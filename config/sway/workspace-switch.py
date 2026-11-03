#!/usr/bin/env python3
"""切换工作区，到边界时自动新建。

sway 的 `workspace next` 在最后一个工作区会绕回第一个，所以“向右到底新建
一个”没法用原生命令表达，这里自己算：

  next（向右）：切到编号更大的下一个工作区；没有更大的就新建 max+1
  prev（向左）：切到编号更小的上一个工作区；没有更小的就绕到最大的那个
                （只有一个工作区时什么也不做——没法“往前”新建）

只考虑带正数编号的工作区。用法：

  workspace-switch.py next
  workspace-switch.py prev
  workspace-switch.py next --dry-run
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


def swaymsg(*args, env=None):
    return subprocess.run(
        ["swaymsg", *args],
        capture_output=True,
        text=True,
        timeout=3,
        env=env,
    )


def workspace_numbers(env):
    proc = swaymsg("-t", "get_workspaces", "-r", env=env)
    workspaces = json.loads(proc.stdout or "[]")
    numbers = set()
    focused = None
    for ws in workspaces:
        try:
            num = int(ws.get("num", -1))
        except (TypeError, ValueError):
            continue
        if num > 0:
            numbers.add(num)
            if ws.get("focused"):
                focused = num
    return numbers, focused


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    dry_run = "--dry-run" in sys.argv[1:]
    if len(args) != 1 or args[0] not in ("next", "prev"):
        print("usage: workspace-switch.py next|prev [--dry-run]", file=sys.stderr)
        return 2
    direction = args[0]

    env = sway_env()
    try:
        numbers, current = workspace_numbers(env)
    except Exception as exc:
        print("could not list workspaces: %s" % exc, file=sys.stderr)
        return 1

    if not numbers:
        target = 1
        action = "create"
    elif direction == "next":
        higher = sorted(n for n in numbers if current is None or n > current)
        if higher:
            target = higher[0]
            action = "switch"
        else:
            target = max(numbers) + 1
            action = "create"
    else:
        lower = sorted((n for n in numbers if current is None or n < current), reverse=True)
        if lower:
            target = lower[0]
            action = "switch"
        elif len(numbers) > 1:
            target = max(numbers)
            action = "wrap"
        else:
            print("only one workspace, nothing to do", flush=True)
            return 0

    if dry_run:
        print("would %s workspace %d" % (action, target), flush=True)
        return 0

    proc = swaymsg("workspace", "number", str(target), env=env)
    if proc.returncode != 0:
        print(proc.stderr.strip() or proc.stdout.strip(), file=sys.stderr)
        return proc.returncode

    print("%s workspace %d" % (action, target), flush=True)
    return 0


if __name__ == "__main__":
    sys.exit(main())
