# Intro

A TUI todo-list App using with waybar

# Usage

```sh
# list all items in db.json
python -m app.main ls

# add new item (--ddl)
python -m app.main add --ddl 2026-5-20

# remove by id
python -m app.main rm $id
# remove by index
python -m app.main rm $id --index

# set status(done|undone|reminder|toggle)
python -m app.main set $status

# clear
python -m app.main clear

# tui
python -m app.main run_tui
```

## [my waybar](https://github.com/SydX-pages/waybar_with_widgets)
