import argparse


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

    sub.add_parser("run_tui")
    sub.add_parser("add_tui")

    sub.add_parser("clear")

    return parser.parse_args()
