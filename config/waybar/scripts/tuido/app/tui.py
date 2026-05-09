from .task import remove, set_status, get_id_by_index, show, set_date, add
import os


def is_by_index():
    index = input("by index?[(y)es | (n)o | (q)uit | (default = no)]: ")
    if index == "yes" or index == "y":
        i = int(input("index: "))
        return get_id_by_index(i)
    elif index == "" or index == "no" or index == "n":
        id = int(input("id:"))
        return id
    elif index == "quit" or index == "q":
        return "quit"


def add_tui():
    content = input("Content: ")
    ddl = input("Deadline (YYYY-MM-DD optional): ")
    if ddl:
        ddl = set_date(ddl)
    add(content, ddl)
    show(None)


def run_tui():
    try:
        while True:
            print("\n==== TUIDO ====")
            print("1. list (ls)")
            print("2. add")
            print("3. remove (rm)")
            print("4. set status (set)")
            print("5. exit (q)")

            choice = input("tuido ❯ ")

            if choice == "1" or choice == "ls" or choice == "list":
                show(None)

            elif choice == "2" or choice == "add":
                add_tui()

            elif choice == "3" or choice == "remove" or choice == "rm":
                show(None)
                id = is_by_index()
                if id == "quit":
                    continue
                remove(id)
                show(None)

            elif choice == "4" or choice == "set":
                show(None)
                id = is_by_index()
                status = input(
                    "status[done|undone|reminder|toggle (default = toggle)]:"
                )
                if id == "quit":
                    continue
                set_status(id, status)
                show(None)

            elif choice == "5" or choice == "q":
                break

            elif choice == "clear":
                os.system("clear")
            else:
                print("invalid option")

    except KeyboardInterrupt:
        print("Exit")
    except EOFError:
        print("Exit")
