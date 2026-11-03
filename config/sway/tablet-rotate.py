#!/usr/bin/env python3
import glob
import json
import os
import signal
import subprocess
import sys

import gi

gi.require_version("GLib", "2.0")
from gi.repository import Gio, GLib

DEST_NAME = "net.hadess.SensorProxy"
OBJ_PATH = "/net/hadess/SensorProxy"
IFACE = "net.hadess.SensorProxy"
PROP = "AccelerometerOrientation"

OUTPUT = os.environ.get("SWAY_TABLET_ORIENT_OUTPUT", "eDP-1")
DEBOUNCE_MS = int(os.environ.get("SWAY_TABLET_ORIENT_DEBOUNCE_MS", "1200"))

TRANSFORM = {
    "normal": "normal",
    "left-up": "270",
    "right-up": "90",
    "upside-down": "180",
}

state = {
    "proxy": None,
    "current": None,
    "pending": None,
    "timer": 0,
    "claimed": False,
}


def log(msg):
    print(msg, flush=True)


def sway_env():
    sock = os.environ.get("SWAYSOCK")
    if sock and os.path.exists(sock):
        return None
    candidates = sorted(
        glob.glob("/run/user/%d/sway-ipc.*.sock" % os.getuid())
    )
    if not candidates:
        return None
    log("SWAYSOCK not usable, falling back to %s" % candidates[-1])
    env = dict(os.environ)
    env["SWAYSOCK"] = candidates[-1]
    return env


def swaymsg(*args):
    try:
        proc = subprocess.run(
            ["swaymsg", *args],
            capture_output=True,
            text=True,
            timeout=5,
            env=sway_env(),
        )
    except Exception as exc:
        log("swaymsg failed: %s" % exc)
        return False
    try:
        reply = json.loads(proc.stdout or "[]")
    except ValueError:
        log("swaymsg unparsable reply: %r" % proc.stdout)
        return False
    if not reply or not all(entry.get("success") for entry in reply):
        log("swaymsg rejected %s: %r" % (" ".join(args), proc.stdout))
        return False
    return True


def output_exists():
    try:
        proc = subprocess.run(
            ["swaymsg", "-t", "get_outputs"],
            capture_output=True,
            text=True,
            timeout=5,
            env=sway_env(),
        )
        reply = json.loads(proc.stdout or "[]")
    except Exception:
        return False
    return any(out.get("name") == OUTPUT for out in reply)


def apply(orientation):
    transform = TRANSFORM.get(orientation)
    if transform is None:
        log("ignoring unknown orientation %r" % orientation)
        return
    if not output_exists():
        log("output %s not present, skipping" % OUTPUT)
        return
    if swaymsg("output", OUTPUT, "transform", transform):
        log("tablet: %s -> %s" % (orientation, transform))


def commit():
    state["timer"] = 0
    pending = state["pending"]
    state["pending"] = None
    if pending is None or pending == state["current"]:
        return False
    state["current"] = pending
    apply(pending)
    return False


def schedule(orientation):
    if orientation == state["current"]:
        state["pending"] = None
        if state["timer"]:
            GLib.source_remove(state["timer"])
            state["timer"] = 0
        return
    if state["pending"] == orientation:
        return
    state["pending"] = orientation
    if state["timer"]:
        GLib.source_remove(state["timer"])
    state["timer"] = GLib.timeout_add(DEBOUNCE_MS, commit)
    log("pending %s in %dms" % (orientation, DEBOUNCE_MS))


def read_orientation():
    try:
        result = state["proxy"].call_sync(
            "org.freedesktop.DBus.Properties.Get",
            GLib.Variant("(ss)", (IFACE, PROP)),
            Gio.DBusCallFlags.NONE,
            -1,
            None,
        )
        return result.unpack()[0]
    except Exception as exc:
        log("could not read %s: %s" % (PROP, exc))
        return None


def on_properties_changed(*_args):
    orientation = read_orientation()
    if orientation is not None:
        schedule(orientation)


def release_accelerometer():
    proxy = state["proxy"]
    if proxy is None or not state["claimed"]:
        return
    try:
        proxy.call_sync(
            "ReleaseAccelerometer", None, Gio.DBusCallFlags.NONE, -1, None
        )
        state["claimed"] = False
        log("accelerometer released")
    except Exception as exc:
        log("ReleaseAccelerometer failed: %s" % exc)


def shutdown(*_args):
    if state["timer"]:
        GLib.source_remove(state["timer"])
        state["timer"] = 0
    release_accelerometer()
    if output_exists():
        log("resetting transform on exit")
        swaymsg("output", OUTPUT, "transform", "normal")
    GLib.idle_add(GLib.MainLoop.quit, state.get("loop"))
    return False


def main():
    loop = GLib.MainLoop()
    state["loop"] = loop

    proxy = Gio.DBusProxy.new_for_bus_sync(
        Gio.BusType.SYSTEM,
        Gio.DBusProxyFlags.DO_NOT_AUTO_START,
        None,
        DEST_NAME,
        OBJ_PATH,
        IFACE,
        None,
    )
    state["proxy"] = proxy

    has_accel = proxy.get_cached_property("HasAccelerometer")
    if has_accel is not None and not has_accel.get_boolean():
        log("no accelerometer available, exiting")
        return 1

    proxy.call_sync("ClaimAccelerometer", None, Gio.DBusCallFlags.NONE, -1, None)
    state["claimed"] = True
    log("accelerometer claimed")

    GLib.unix_signal_add(GLib.PRIORITY_HIGH, signal.SIGTERM, shutdown)
    GLib.unix_signal_add(GLib.PRIORITY_HIGH, signal.SIGINT, shutdown)

    proxy.connect("g-properties-changed", on_properties_changed)

    initial = read_orientation()
    if initial is not None:
        log("initial orientation: %s" % initial)
        state["current"] = initial
        if TRANSFORM.get(initial) not in (None, "normal"):
            apply(initial)
    else:
        log("initial orientation unavailable")

    log("watching %s for output %s" % (IFACE, OUTPUT))
    loop.run()
    return 0


if __name__ == "__main__":
    sys.exit(main())
