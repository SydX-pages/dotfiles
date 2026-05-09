from .cli import args_parse
from .tui import run_tui, add_tui
from datetime import datetime
from .task import add, remove, clear, set_status, show, get_id_by_index, set_date

if __name__ == "__main__":

    args = args_parse()
    cmd = args.cmd

    if cmd == "add":
        ddl = args.ddl
        if ddl:
            ddl = set_date(args.ddl)
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
    elif cmd == "run_tui":
        run_tui()
    elif cmd == "add_tui":
        add_tui()
