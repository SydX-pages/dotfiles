import json
from datetime import datetime
import argparse
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(BASE_DIR, "db.json")


def clear():
    re_upload([])
    print("all cleared\n")


def re_upload(data):
    with open(DB, "w") as f:
        json.dump(data, f, indent=2)


def load():
    with open(DB, "r") as f:
        return json.load(f)


def add(content, ddl=""):
    data = load()
    for item in data:
        if item["content"] == content:
            print("duplicated item\n")
            return
    new_id = max([item["id"] for item in data], default=0) + 1
    data.append({"id": new_id, "status": -1, "content": content, "deadline": ddl})
    re_upload(data)
    print(content, " added\n")


def get_by_id(id):
    for item in load():
        if item["id"] == id:
            return item["content"]
    return None


def remove(id):
    data = load()
    removed_id = get_by_id(id)
    data = [item for item in data if item["id"] != id]
    re_upload(data)
    print(removed_id, " removed\n")


def set_status(id, status):
    data = load()
    for item in data:
        if item["id"] == id:
            if status == "done":
                item["status"] = 1
                print(item["content"], "done")
            elif status == "undone":
                item["status"] = -1
                print(item["content"], "undone")
            elif status == "reminder":
                item["status"] = 0
                print(item["content"], "is a reminder")
            elif status == "toggle":
                item["status"] *= -1
                if item["status"] == 0:
                    item["status"] = -1
                if item["status"] == -1:
                    text = "undone"
                elif item["status"] == 1:
                    text = "done"
                print(item["content"], "text")

    re_upload(data)


def print_one(item):
    if item["status"] == 1:
        status = "✅"
    elif item["status"] == -1:
        if (
            item["deadline"]
            and datetime.strptime(item["deadline"], "%Y-%m-%d").date()
            < datetime.now().date()
        ):
            status = "❌"
        else:
            status = "❕"
    else:
        status = "⏰"
    deadline = item["deadline"] or "-"
    return f"{item['id']: <5} {item['content']: <25} {deadline:<15} {status:<5}\n"


def show(index):
    data = load()
    data = data[::-1]
    result = ""
    if index is None:
        for item in data:
            result += print_one(item)
    else:
        if index >= len(data):
            return
        result += print_one(data[index])
    print(result)


def add_ui():
    content = str(input("Content: "))
    ddl = str(input("deadline: "))
    if ddl:
        ddl = datetime.strptime(ddl, "%Y-%m-%d").strftime("%Y-%m-%d")
    add(content, ddl)


def args_parse():
    parser = argparse.ArgumentParser(prog="tuido")
    sub = parser.add_subparsers(dest="cmd")

    add_parser = sub.add_parser("add")
    add_parser.add_argument("content")
    add_parser.add_argument("--ddl")

    rm_parser = sub.add_parser("rm")
    rm_parser.add_argument("id", type=int)
    rm_parser.add_argument("--index", action="store_true")

    set_parser = sub.add_parser("set")
    set_parser.add_argument("id", type=int)
    set_parser.add_argument("status", choices=["done", "undone", "reminder", "toggle"])
    set_parser.add_argument("--index", action="store_true")

    ls_parser = sub.add_parser("ls")
    ls_parser.add_argument("--index", type=int)

    sub.add_parser("add_ui")
    sub.add_parser("run_tui")

    sub.add_parser("clear")

    return parser.parse_args()


def get_id_by_index(index):
    return load()[::-1][index]["id"]


def run_tui():
    print("Coming Soon...")
    while 1:
        x = input("~>")


if __name__ == "__main__":

    args = args_parse()
    cmd = args.cmd

    if cmd == "add":
        ddl = args.ddl
        if ddl:
            ddl = datetime.strptime(args.ddl, "%Y-%m-%d").strftime("%Y-%m-%d")
        add(args.content, ddl)
    elif cmd == "ls":
        show(args.index)
    elif cmd == "rm":
        if args.index:
            remove(get_id_by_index(args.id))
        else:
            remove(args.id)
    elif cmd == "set":
        if args.index:
            set_status(get_id_by_index(args.id), args.status)
        else:
            set_status(args.id, args.status)
    elif cmd == "clear":
        clear()
    elif cmd == "add_ui":
        add_ui()
    elif cmd == "run_tui":
        run_tui()
