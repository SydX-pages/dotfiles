from datetime import datetime, timedelta
from .db import load, re_upload


# C
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


# R
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


def get_id_by_index(index):
    return load()[::-1][index]["id"]


# U
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


# D
def remove(id):
    data = load()
    removed_id = get_by_id(id)
    data = [item for item in data if item["id"] != id]
    re_upload(data)
    print(removed_id, " removed\n")


def clear():
    re_upload([])
    print("all cleared\n")


# set_date
def set_date(date_str):
    today = datetime.today()

    if date_str == "today":
        return today.strftime("%Y-%m-%d")

    elif date_str == "tomorrow":
        return (today + timedelta(days=1)).strftime("%Y-%m-%d")

    else:
        try:
            return datetime.strptime(date_str, "%Y-%m-%d").strftime("%Y-%m-%d")
        except ValueError:
            print("Invalid date format. Use YYYY-MM-DD / today / tomorrow")
            return None
