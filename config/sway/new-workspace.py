#!/usr/bin/env python3
"""新建一个空工作区并切换过去。

sway 的 `workspace next` 在只有一个工作区时什么也不做，所以手势会“失效”。
这个脚本找出当前还没有被使用的最小正整数编号，然后 `workspace number N`
新建并切过去。例如只有工作区 1 时会新建 2；有 1、2、4 时会新建 3。
"""
import glob
import json
import os
import subprocess
import sys


def sway_env():
    sock = os.environ.get("SWAYSOCK")
    if sock and os.path.exists(sock):
        return None
    candidates = sorted(glob.glob("/run/user/%d/sway-ipc.*.sock" % os.getuid()))
    if not candidates:
        return None
    return dict(os.environ, SWAYSOCK=candidates[-1])


def main():
    env = sway_env()
    try:
        proc = subprocess.run(
            ["swaymsg", "-t", "get_workspaces", "-r"],
            capture_output=True,
            text=True,
            timeout=3,
            env=env,
        )
        workspaces = json.loads(proc.stdout or "[]")
    except Exception as exc:
        print("could not list workspaces: %s" % exc, file=sys.stderr)
        return 1

    used = set()
    for ws in workspaces:
        try:
            num = int(ws.get("num", -1))
        except (TypeError, ValueError):
            continue
        if num > 0:
            used.add(num)

    number = 1
    while number in used:
        number += 1

    if "--dry-run" in sys.argv[1:]:
        print("would create workspace number %d" % number)
        return 0

    try:
        proc = subprocess.run(
            ["swaymsg", "workspace", "number", str(number)],
            capture_output=True,
            text=True,
            timeout=3,
            env=env,
        )
    except Exception as exc:
        print("could not create workspace: %s" % exc, file=sys.stderr)
        return 1

    if proc.returncode != 0:
        print(proc.stderr.strip() or proc.stdout.strip(), file=sys.stderr)
        return proc.returncode

    print("workspace number %d" % number, flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
