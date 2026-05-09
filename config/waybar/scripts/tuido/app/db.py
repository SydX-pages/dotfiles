import json
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB = os.path.join(BASE_DIR, "../db/db.json")


def re_upload(data):
    with open(DB, "w") as f:
        json.dump(data, f, indent=2)


def load():
    with open(DB, "r") as f:
        return json.load(f)
