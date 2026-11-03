#!/usr/bin/env python3
"""触摸屏手势（sway 用）

sway 自带的 bindgesture 只处理触摸板，触摸屏（Atmel maXTouch）不会产生
libinput gesture 事件。所以这里直接读 /dev/input/event*（只读，不 grab，
不会影响正常触摸），自己识别手指滑动，然后调用 swaymsg / dms。

默认映射（可在下面的 ACTIONS 里改）：
  三指上 / 下 / 左 / 右         -> 启动器 / 通知中心 / 上一个 / 下一个工作区
                                   （向右到最后一个工作区时会自动新建）
  四指上 / 下 / 左 / 右         -> 切换屏幕键盘 / 关闭当前窗口 / 通知中心 / 控制中心

方向会跟随 tablet-rotate.py 设置的 output transform，横竖屏都能用。
"""
import fcntl
import glob
import json
import os
import select
import signal
import struct
import subprocess
import sys
import time

# ---- evdev 常量 ----
EV_SYN = 0x00
EV_ABS = 0x03
SYN_REPORT = 0

ABS_X = 0x00
ABS_Y = 0x01
ABS_MT_SLOT = 0x2F
ABS_MT_POSITION_X = 0x35
ABS_MT_POSITION_Y = 0x36
ABS_MT_TRACKING_ID = 0x39

# arm64 / x86_64: struct input_event 是 24 字节（timeval 16 + type/code + value）
INPUT_EVENT = struct.Struct("@llHHi")
EVIOCGABS = 0x80184540  # _IOR('E', 0x40 + abs, struct input_absinfo)

# ---- 可调参数 ----
DEVICE_MATCH = os.environ.get("SWAY_SCREEN_GESTURE_DEVICE", "Touchscreen")
OUTPUT = os.environ.get("SWAY_SCREEN_GESTURE_OUTPUT", "eDP-1")

SETTLE = 0.10          # 手指落齐后等多久再判定（秒）
MIN_SWIPE = 0.055      # 滑动至少要移动屏幕的 5.5%
MAX_GESTURE = 2.0      # 一次手势最长持续时间

DMS = "dms"
SWAYMSG = "swaymsg"
OSK = os.path.expanduser("~/.config/sway/osk.sh")
WORKSPACE_SWITCH = ["/usr/bin/python3", os.path.expanduser("~/.config/sway/workspace-switch.py")]

# (手指数, 方向) -> 命令
ACTIONS = {
    (3, "up"): [DMS, "ipc", "call", "spotlight-bar", "toggle"],
    (3, "down"): [DMS, "ipc", "call", "notifications", "toggle"],
    (3, "left"): WORKSPACE_SWITCH + ["prev"],
    (3, "right"): WORKSPACE_SWITCH + ["next"],

    (4, "up"): [OSK, "toggle"],
    (4, "down"): [SWAYMSG, "kill"],
    (4, "left"): [DMS, "ipc", "call", "notifications", "toggle"],
    (4, "right"): [DMS, "ipc", "call", "control-center", "toggle"],
}

DEBUG = os.environ.get("SWAY_SCREEN_GESTURE_DEBUG") == "1"

running = True
children = []
transform_cache = {"at": 0.0, "value": "normal", "warned": False}


def log(msg):
    print(msg, flush=True)


def debug(msg):
    if DEBUG:
        log("debug: " + msg)


def stop(*_args):
    global running
    running = False


def reap_children():
    for proc in children[:]:
        if proc.poll() is not None:
            children.remove(proc)


def spawn(cmd):
    debug("exec: %s" % " ".join(cmd))
    try:
        children.append(
            subprocess.Popen(
                cmd,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                start_new_session=True,
            )
        )
    except Exception as exc:
        log("exec failed: %s: %s" % (" ".join(cmd), exc))


def sway_socket():
    sock = os.environ.get("SWAYSOCK")
    if sock and os.path.exists(sock):
        return sock
    candidates = sorted(glob.glob("/run/user/%d/sway-ipc.*.sock" % os.getuid()))
    return candidates[-1] if candidates else None


def get_transform():
    """读当前 output 的 transform；带 1 秒缓存，避免每次触摸都 fork swaymsg。"""
    now = time.monotonic()
    if now - transform_cache["at"] < 1.0:
        return transform_cache["value"]

    sock = sway_socket()
    if not sock:
        return transform_cache["value"]
    env = dict(os.environ, SWAYSOCK=sock)
    try:
        proc = subprocess.run(
            [SWAYMSG, "-t", "get_outputs", "-r"],
            capture_output=True,
            text=True,
            timeout=1.5,
            env=env,
        )
        outputs = json.loads(proc.stdout or "[]")
    except Exception as exc:
        transform_cache["at"] = now
        if not transform_cache["warned"]:
            log("could not read output transform: %s" % exc)
            transform_cache["warned"] = True
        return transform_cache["value"]

    value = "normal"
    for out in outputs:
        if out.get("name") == OUTPUT:
            value = out.get("transform") or "normal"
            break
    else:
        for out in outputs:
            if out.get("current_mode"):
                value = out.get("transform") or "normal"
                break

    transform_cache["at"] = now
    if value != transform_cache["value"]:
        log("output transform: %s -> %s" % (transform_cache["value"], value))
    transform_cache["value"] = value
    return value


def apply_transform(x, y, transform):
    """把触摸设备的归一化坐标映射到屏幕坐标（x/y 为 0..1）。

    这里用的是 wlroots apply_output_transform() 的逆变换：实际手感验证过，
    竖屏（transform 90/270）时如果直接用正向变换，上下左右会整体反过来。
    180 和 flipped 系列的逆变换与自身相同，所以不受影响。
    """
    if transform == "90":
        return y, 1.0 - x
    if transform == "180":
        return 1.0 - x, 1.0 - y
    if transform == "270":
        return 1.0 - y, x
    if transform == "flipped":
        return 1.0 - x, y
    if transform == "flipped-90":
        return y, x
    if transform == "flipped-180":
        return x, 1.0 - y
    if transform == "flipped-270":
        return 1.0 - y, 1.0 - x
    return x, y


def direction(dx, dy):
    if abs(dx) >= abs(dy):
        return "right" if dx > 0 else "left"
    return "down" if dy > 0 else "up"


class TouchTracker:
    def __init__(self):
        self.ranges = (0, 4095, 0, 2729)  # minx, maxx, miny, maxy
        self.reset()

    def set_ranges(self, minx, maxx, miny, maxy):
        self.ranges = (
            minx,
            maxx if maxx > minx else minx + 1,
            miny,
            maxy if maxy > miny else miny + 1,
        )

    def reset(self):
        self.raw = {}
        self.slots = {}
        self.active = False
        self.t0 = 0.0
        self.last_down = 0.0
        self.max_count = 0
        self.fired = False
        self.transform = "normal"

    def to_screen(self, x, y):
        minx, maxx, miny, maxy = self.ranges
        nx = min(max((x - minx) / (maxx - minx), 0.0), 1.0)
        ny = min(max((y - miny) / (maxy - miny), 0.0), 1.0)
        return apply_transform(nx, ny, self.transform)

    def down(self, slot, now):
        if not self.active:
            self.reset()
            self.active = True
            self.t0 = now
            self.transform = get_transform()
            debug("gesture start, transform=%s" % self.transform)
        self.last_down = now
        # 新触点：清掉这个 slot 上一根手指留下的坐标，等驱动随后发来本次位置
        self.raw[slot] = [None, None]
        entry = {
            "active": True,
            "x": None,
            "y": None,
            "sx": None,
            "sy": None,
            "cx": None,
            "cy": None,
        }
        self.slots[slot] = entry

    def up(self, slot):
        entry = self.slots.get(slot)
        if entry:
            entry["active"] = False

    def position(self, slot, x=None, y=None):
        raw = self.raw.setdefault(slot, [None, None])
        if x is not None:
            raw[0] = x
        if y is not None:
            raw[1] = y
        entry = self.slots.get(slot)
        if entry and entry["active"]:
            entry["x"], entry["y"] = raw[0], raw[1]
            if raw[0] is not None and raw[1] is not None:
                entry["cx"], entry["cy"] = self.to_screen(raw[0], raw[1])
                if entry["sx"] is None:
                    entry["sx"], entry["sy"] = entry["cx"], entry["cy"]

    def sync(self, now):
        live = [
            s
            for s in self.slots.values()
            if s["active"] and s["cx"] is not None and s["cy"] is not None
        ]
        count = len(live)
        if count == 0:
            if self.active:
                debug("gesture end")
            self.reset()
            return

        self.max_count = max(self.max_count, count)
        if self.fired:
            return

        # 等所有手指落稳，避免三指手势被后来的第四指打断/误判
        if now - self.last_down < SETTLE:
            return
        if now - self.t0 > MAX_GESTURE:
            return

        if count < 3 or count != self.max_count:
            return

        deltas = []
        for s in live:
            dx = s["cx"] - s["sx"]
            dy = s["cy"] - s["sy"]
            if (dx * dx + dy * dy) ** 0.5 < MIN_SWIPE * 0.65:
                return
            deltas.append((dx, dy))

        dirs = {direction(dx, dy) for dx, dy in deltas}
        if len(dirs) != 1:
            return
        way = dirs.pop()
        mean_x = sum(dx for dx, _ in deltas) / len(deltas)
        mean_y = sum(dy for _, dy in deltas) / len(deltas)

        if way in ("up", "down"):
            if abs(mean_y) < MIN_SWIPE or abs(mean_x) > abs(mean_y) * 0.85:
                return
        else:
            if abs(mean_x) < MIN_SWIPE or abs(mean_y) > abs(mean_x) * 0.85:
                return

        self.fire((self.max_count, way))

    def fire(self, key):
        cmd = ACTIONS.get(key)
        if not cmd:
            debug("no action for %r" % (key,))
            return
        self.fired = True
        log("gesture %s -> %s" % (key, " ".join(cmd)))
        spawn(cmd)


def find_device():
    pattern = DEVICE_MATCH.lower()
    paths = sorted(
        glob.glob("/dev/input/event*"),
        key=lambda p: int(p.rsplit("event", 1)[1] or 0),
    )
    for path in paths:
        sysname = os.path.basename(path)
        try:
            with open("/sys/class/input/%s/device/name" % sysname) as fp:
                name = fp.read().strip()
        except OSError:
            continue
        low = name.lower()
        if pattern in low and "touchpad" not in low:
            return path, name
    return None, None


def abs_range(fd, code):
    buf = bytearray(24)
    try:
        fcntl.ioctl(fd, EVIOCGABS + code, buf)
        _val, minv, maxv, _fuzz, _flat, _res = struct.unpack("iiiiii", buf)
        return minv, maxv
    except OSError:
        return None


def main():
    if not sway_socket():
        log("sway socket not found, exiting")
        return 0

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)

    tracker = TouchTracker()
    while running:
        path, name = find_device()
        if not path:
            log("waiting for touchscreen matching %r" % DEVICE_MATCH)
            time.sleep(2)
            continue

        try:
            fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
        except OSError as exc:
            log("cannot open %s: %s" % (path, exc))
            time.sleep(2)
            continue

        try:
            xr = abs_range(fd, ABS_MT_POSITION_X)
            yr = abs_range(fd, ABS_MT_POSITION_Y)
            if xr and yr:
                tracker.set_ranges(xr[0], xr[1], yr[0], yr[1])
            log("watching %s (%s) range=%s" % (path, name, tracker.ranges))
            tracker.reset()

            current_slot = 0
            buf = b""
            size = INPUT_EVENT.size
            sock = sway_socket()

            while running:
                ready, _, _ = select.select([fd], [], [], 1.0)
                if not ready:
                    reap_children()
                    if not sock or not os.path.exists(sock):
                        log("sway socket disappeared, exiting")
                        return 0
                    continue

                chunk = os.read(fd, size * 128)
                if not chunk:
                    log("device %s closed" % path)
                    break
                buf += chunk

                while len(buf) >= size:
                    _sec, _usec, etype, code, value = INPUT_EVENT.unpack_from(buf)
                    buf = buf[size:]
                    now = time.monotonic()

                    if etype == EV_ABS:
                        if code == ABS_MT_SLOT:
                            current_slot = value
                        elif code == ABS_MT_TRACKING_ID:
                            if value == -1:
                                tracker.up(current_slot)
                            else:
                                tracker.down(current_slot, now)
                        elif code == ABS_MT_POSITION_X:
                            tracker.position(current_slot, x=value)
                        elif code == ABS_MT_POSITION_Y:
                            tracker.position(current_slot, y=value)
                    elif etype == EV_SYN and code == SYN_REPORT:
                        tracker.sync(now)
                        reap_children()
        except Exception as exc:
            log("input error: %s" % exc)
        finally:
            try:
                os.close(fd)
            except OSError:
                pass
            time.sleep(1)

    return 0


if __name__ == "__main__":
    sys.exit(main())
