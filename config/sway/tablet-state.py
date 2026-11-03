#!/usr/bin/env python3
"""根据当前平板模式开关状态，同步旋转服务、实体键盘、屏幕键盘。

sway 的 bindswitch 只在状态“变化”时触发；如果开机时已经翻成平板，
或者平板模式下执行了 `swaymsg reload`（sway 会把 input 的 events 状态
重置成 enabled），bindswitch 不会重新触发。所以再用 exec_always 跑一次
这个脚本，按当前开关状态把状态补齐。
"""
import fcntl
import glob
import os
import struct
import subprocess
import sys
import time

SW_TABLET_MODE = 0x01
EVIOCGSW = 0x8008451B  # _IOR('E', 0x1b, unsigned long)

HOME = os.path.expanduser("~")
OSK = os.path.join(HOME, ".config/sway/osk.sh")
KEYBOARD = "0:0:cros_ec"  # 内建键盘，可用 swaymsg -t get_inputs 确认


def sway_env():
    sock = os.environ.get("SWAYSOCK")
    if sock and os.path.exists(sock):
        return None
    candidates = sorted(glob.glob("/run/user/%d/sway-ipc.*.sock" % os.getuid()))
    if not candidates:
        return None
    return dict(os.environ, SWAYSOCK=candidates[-1])


def find_switch():
    for path in sorted(glob.glob("/dev/input/event*")):
        sysname = os.path.basename(path)
        try:
            with open("/sys/class/input/%s/device/name" % sysname) as fp:
                name = fp.read().strip()
        except OSError:
            continue
        if name == "cros_ec_buttons":
            return path
    return None


def tablet_mode():
    path = find_switch()
    if not path:
        return None
    try:
        fd = os.open(path, os.O_RDONLY | os.O_NONBLOCK)
    except OSError:
        return None
    try:
        buf = bytearray(8)
        fcntl.ioctl(fd, EVIOCGSW, buf, True)
        bits = struct.unpack("Q", buf)[0]
        return bool(bits & (1 << SW_TABLET_MODE))
    except OSError:
        return None
    finally:
        os.close(fd)


def run(cmd, retries=1):
    env = sway_env()
    for attempt in range(retries):
        try:
            proc = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=5,
                env=env,
            )
            if proc.returncode == 0:
                return True
            if attempt + 1 < retries:
                time.sleep(0.2)
        except Exception:
            if attempt + 1 < retries:
                time.sleep(0.2)
    return False


def osk_running():
    return (
        subprocess.run(
            ["pgrep", "-x", "wvkbd-mobintl"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        ).returncode
        == 0
    )


def main():
    force = None
    if "--force" in sys.argv[1:]:
        index = sys.argv.index("--force")
        try:
            force = sys.argv[index + 1]
        except IndexError:
            print("usage: tablet-state.py [--force on|off]", file=sys.stderr)
            return 2
        if force not in ("on", "off"):
            print("--force expects on or off", file=sys.stderr)
            return 2

    mode = force == "on" if force else tablet_mode()
    if mode is None and force is None:
        # sway 启动时输入设备可能还没完全就绪，稍等重试
        for _ in range(25):
            time.sleep(0.2)
            mode = tablet_mode()
            if mode is not None:
                break
    if mode is None:
        print("cros_ec_buttons switch not found", file=sys.stderr)
        return 1

    if mode:
        run(["systemctl", "--user", "start", "tablet-rotate.service"], retries=20)
        run(["swaymsg", "input", KEYBOARD, "events", "disabled"], retries=20)
        run([OSK, "show"], retries=5)
        print("tablet mode: on (keyboard disabled, osk shown)", flush=True)
    else:
        run(["systemctl", "--user", "stop", "tablet-rotate.service"])
        run(["swaymsg", "input", KEYBOARD, "events", "enabled"], retries=20)
        if osk_running():
            run([OSK, "hide"], retries=5)
        print("tablet mode: off (keyboard enabled)", flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
