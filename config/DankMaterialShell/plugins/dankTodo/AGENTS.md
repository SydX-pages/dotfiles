# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) and other AI agents when working with code in this repository.

## What this is

A [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell) (DMS) bar-widget plugin written in QML. Installed by symlinking or cloning into `~/.config/DankMaterialShell/plugins/dankTodo`. There is no build step — the QML files are loaded at runtime by Quickshell.

## Common commands

```bash
# Reload DMS to pick up changes (most edits require this)
dms ipc call appearance reload

# Exercise IPC surface the widget exposes
dms ipc call dankTodo add "Buy milk"
dms ipc call dankTodo addChild "Whole milk" <parentId>
dms ipc call dankTodo edit <id> "new text"
dms ipc call dankTodo toggle <id>
dms ipc call dankTodo move <sourceId> <targetId> <before|after|child>
dms ipc call dankTodo list        # JSON dump of current state
dms ipc call dankTodo count       # "active/total"
```

There is no lint or test suite. Validate changes by reloading DMS and driving the popout manually, or via the IPC calls above.

## Architecture

Four files ship with the plugin:

| File                  | Role                                                     |
| --------------------- | -------------------------------------------------------- |
| `plugin.json`         | DMS manifest. `capabilities: ["dankbar-widget"]` is what makes it show up in the Plugins tab. |
| `DankTodoWidget.qml`  | `PluginComponent` root — bar pill, popout, data model, persistence, IPC. |
| `DankTodoSettings.qml`| `PluginSettings` root — storage path, pill count mode, limits, IPC hints. |
| `registry-entry.json` | Draft of the file that goes into `AvengeMedia/dms-plugin-registry` as `plugins/deepu105-dank-todo.json`. Not part of the plugin install. |

### Data model and persistence

Todos are a flat array with `parentId` linking children to parents (null = top-level). **Array order is display order**, so reorder operations mutate array position and the `parentId` field in tandem. Deletions are soft deletes via `deletedAt`; deleted rows remain persisted but are filtered out of UI counts and list models.

Storage is a single JSON file (`$XDG_CONFIG_HOME/dank-todo/todos.json` by default) written via `Quickshell.Io.FileView` with `atomicWrites: true` and `watchChanges: false` — we own the writes, so watching would cause reload loops. The loader migrates legacy `version: 1` files by defaulting `parentId` to null and auto-sanitizes dangling parent references.

### Hierarchy helpers

Inside `DankTodoWidget.qml` these are the load-bearing functions for the tree:

- `depthOf(id)` — walk `parentId` chain, capped at depth 16.
- `getDescendantIds(id)` — BFS all descendants. Used by `deleteTodo` (soft-delete a whole subtree) and by `moveTodo` (move a subtree as one block, block cycles).
- `subtreeIndices(id)` — contiguous indices in `todos` for the subtree root, used when splicing a block out of the array.
- `moveTodo(sourceId, targetId, position)` — single entry point for all three drop zones (`before`, `after`, `child`). Always re-parents the source's whole subtree as one unit and refuses to drop onto a descendant.

### Drag & drop

Drag/drop is available in all three filters. The view still renders a filtered slice of `todos`, but drop targets map back to the canonical array and continue to use the same `moveTodo(sourceId, targetId, position)` path, so reorder/grouping behavior stays consistent across All, Active, and Done.

The delegate uses a **`dragProxy` wrapper Item** around the visual `card` Rectangle. The `MouseArea.drag.target` points at the proxy, not the card. This is deliberate: `drag.target` imperatively mutates `x`/`y`, which **breaks declarative bindings**. Since `card.x` is bound to `slot.depth * indentStep` so the indent tracks depth changes after moves, the card binding must stay intact — the proxy absorbs the drag translation instead. On release, the proxy resets to `0,0` (no broken bindings needed).

Drop zones are computed in `DropArea.onPositionChanged` against `drag.y` relative to the delegate: top 25 % → `before`, bottom 25 % → `after`, middle 50 % → `child`. `ListView.interactive` is disabled while dragging to prevent scroll-stealing.

### Popout composer state

The add-input at the top of the popout is the single composer UI for three actions: new top-level todo, new subtask, and edit. State lives on `popoutColumn`:

- `addingChildOfId: string` — target parent for a subtask compose
- `editingId: string` — target id for an edit

These are **mutually exclusive**. Use the helper functions — do not mutate the properties directly:

- `startAddingChild(parentId)` / `startEditing(id)` — each clears the other, seeds/clears input text, and focuses.
- `submitComposer()` — wired to Enter and the add-button click. Routes to `editTodo` or `addTodo` based on state.
- `cancelComposer()` — wired to Escape and the chip's × button.

A `Connections` block watching `root.todos` clears composer state if the referenced item disappears (e.g. deleted from another row while being edited).

The indicator chip above the input visually reflects the mode (`"Editing: …"` vs `"Subtask of: …"`). The `+` button flips to `✓` during edit.

## Conventions from DMS

- Root is `PluginComponent` (widget) or `PluginSettings` (settings). Import via `qs.Modules.Plugins`.
- Plugin settings stored under `~/.config/DankMaterialShell/plugin_settings.json` keyed by the manifest `id` — do not write to that file directly; use `pluginData.<key>` (widget side) and `loadValue()`/`saveValue()` (settings side).
- Values from `StringSetting` arrive as strings even for numeric fields. Coerce via `parseIntOr()` — plain `Math.floor("abc")` is NaN.
- Use `Theme.*` primitives for colors/spacing (`Theme.primary`, `Theme.onPrimary`, `Theme.surfaceText`, `Theme.surfaceContainerHigh`, `Theme.error`, `Theme.outlineVariant`, `Theme.spacingXS/S/M/L`, `Theme.cornerRadius`, `Theme.fontSize*`).
- QML widget primitives (`DankIcon`, `DankTextField`, `StyledText`, `StyledRect`) come from `qs.Widgets`; popout chrome is `PopoutComponent`.

## Reference plugins

When stuck, read these installed plugins for patterns:

- `~/.config/DankMaterialShell/plugins/.repos/0026f1eba8dedaec/DankPomodoroTimer/` — simplest bar-pill + popout; closest to this plugin's shape.
- `~/.config/DankMaterialShell/plugins/.repos/7c0d8f010141a5dc/ClipboardPlus/` — full-screen panel plugin with its own `PanelWindow` per screen; the place to look for pinned-items, todo-pages, and selector patterns (heavier than needed here).
- `~/.config/DankMaterialShell/plugins/.repos/0026f1eba8dedaec/DankActions/` — IPC + variants + process execution.

## Submitting to the DMS plugin registry

Registry lives at `github.com/AvengeMedia/dms-plugin-registry`. Submission flow:

1. Make sure `plugin.json`'s `id` and `name` match `registry-entry.json` exactly — the validator rejects mismatches.
2. Fork the registry, copy `registry-entry.json` → `plugins/deepu105-dank-todo.json` (filename must be `{gh-username}-{plugin-name}.json`, lowercase).
3. From inside the registry fork: `python3 .github/generate.py --validate && python3 .github/validate_links.py`.
4. Open a PR. The registry site rebuilds on merge.
