import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

PluginComponent {
    id: root

    readonly property string defaultStorageDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/dank-todo"
    readonly property string resolvedStorageDir: {
        const custom = String(pluginData.storagePath || "").trim()
        return custom.length > 0 ? custom : defaultStorageDir
    }
    readonly property string storageFilePath: resolvedStorageDir + "/todos.json"

    function parseIntOr(value, fallback, min) {
        const n = parseInt(value, 10)
        if (isNaN(n))
            return fallback
        return (min !== undefined && n < min) ? min : n
    }

    property int maxItems: parseIntOr(pluginData.maxItems, 200, 10)
    property int maxTextLength: parseIntOr(pluginData.maxTextLength, 500, 40)
    property string countMode: {
        const v = String(pluginData.countMode || "active")
        return (v === "total" || v === "done" || v === "hidden") ? v : "active"
    }

    property var todos: []
    property int revision: 0
    property string filter: "active"
    readonly property int visibleCount: {
        revision
        let n = 0
        for (let i = 0; i < todos.length; i++) {
            if (!todos[i].deletedAt)
                n++
        }
        return n
    }

    readonly property int activeCount: {
        revision
        let n = 0
        for (let i = 0; i < todos.length; i++) {
            if (!todos[i].deletedAt && !todos[i].completed)
                n++
        }
        return n
    }
    readonly property int doneCount: {
        revision
        return visibleCount - activeCount
    }

    function uid() {
        return Date.now().toString(36) + Math.random().toString(36).substring(2, 8)
    }

    function ensureStorageReady() {
        Quickshell.execDetached(["mkdir", "-p", resolvedStorageDir])
    }

    function saveTodos() {
        const data = {
            version: 2,
            todos: todos
        }
        todoFile.setText(JSON.stringify(data, null, 2))
    }

    function reloadTodos() {
        ensureStorageReady()
        todoFile.reload()
    }

    function filteredTodos(filterKey) {
        revision
        const visibleTodos = todos.filter(t => !t.deletedAt)
        if (filterKey === "active")
            return visibleTodos.filter(t => !t.completed && !hasCompletedAncestor(t.id))
        if (filterKey === "done")
            return visibleTodos.filter(t => t.completed)
        return visibleTodos
    }

    function hasCompletedAncestor(id) {
        let cur = todos.find(t => t.id === id)
        while (cur && cur.parentId) {
            cur = todos.find(t => t.id === cur.parentId)
            if (cur && !cur.deletedAt && cur.completed)
                return true
        }
        return false
    }

    function depthOf(id) {
        let d = 0
        let cur = todos.find(t => t.id === id)
        while (cur && cur.parentId) {
            d++
            if (d > 16)
                return d
            cur = todos.find(t => t.id === cur.parentId)
        }
        return d
    }

    function getDescendantIds(id) {
        const result = new Set()
        let changed = true
        while (changed) {
            changed = false
            for (const t of todos) {
                const pid = t.parentId || null
                if (pid === null)
                    continue
                if ((pid === id || result.has(pid)) && !result.has(t.id)) {
                    result.add(t.id)
                    changed = true
                }
            }
        }
        return result
    }

    function isDescendant(candidateId, ancestorId) {
        if (!candidateId || !ancestorId)
            return false
        if (candidateId === ancestorId)
            return true
        return getDescendantIds(ancestorId).has(candidateId)
    }

    function subtreeIndices(id) {
        const indices = []
        const startIdx = todos.findIndex(t => t.id === id)
        if (startIdx === -1)
            return indices
        const descendants = getDescendantIds(id)
        indices.push(startIdx)
        for (let i = startIdx + 1; i < todos.length; i++) {
            if (descendants.has(todos[i].id))
                indices.push(i)
        }
        return indices
    }

    function addTodo(text, parentId) {
        const trimmed = String(text || "").replace(/\s+/g, " ").trim()
        if (!trimmed.length)
            return false
        if (visibleCount >= maxItems) {
            if (typeof ToastService !== "undefined")
                ToastService.showWarning("Max " + maxItems + " todos reached")
            return false
        }
        const entry = {
            id: uid(),
            text: trimmed.substring(0, maxTextLength),
            completed: false,
            parentId: parentId || null,
            createdAt: new Date().toISOString()
        }
        if (entry.parentId) {
            // Insert right after parent so it becomes the first visible child
            const parentIdx = todos.findIndex(t => t.id === entry.parentId && !t.deletedAt)
            if (parentIdx === -1) {
                entry.parentId = null
                todos = [entry].concat(todos)
            } else {
                const next = todos.slice()
                next.splice(parentIdx + 1, 0, entry)
                todos = next
            }
        } else {
            todos = [entry].concat(todos)
        }
        revision++
        saveTodos()
        return true
    }

    function toggleTodo(id) {
        const idx = todos.findIndex(t => t.id === id && !t.deletedAt)
        if (idx === -1)
            return
        const next = todos.slice()
        next[idx] = Object.assign({}, next[idx], {
            completed: !next[idx].completed,
            completedAt: !next[idx].completed ? new Date().toISOString() : undefined
        })
        todos = next
        revision++
        saveTodos()
    }

    function deleteTodo(id) {
        const toDelete = new Set([id])
        const descendants = getDescendantIds(id)
        descendants.forEach(d => toDelete.add(d))
        const deletedAt = new Date().toISOString()
        let changed = false
        const next = todos.map(t => {
            if (!toDelete.has(t.id) || t.deletedAt)
                return t
            changed = true
            return Object.assign({}, t, {
                deletedAt: deletedAt
            })
        })
        if (!changed)
            return
        todos = next
        revision++
        saveTodos()
    }

    function moveTodo(sourceId, targetId, position) {
        if (!sourceId || !targetId || sourceId === targetId)
            return
        if (isDescendant(targetId, sourceId))
            return
        const sourceIdx = todos.findIndex(t => t.id === sourceId && !t.deletedAt)
        const targetIdx = todos.findIndex(t => t.id === targetId && !t.deletedAt)
        if (sourceIdx === -1 || targetIdx === -1)
            return

        const sourceIndices = subtreeIndices(sourceId)
        const sourceBlock = sourceIndices.map(i => todos[i])
        const sourceIdSet = new Set(sourceBlock.map(t => t.id))

        // Remove the source block from the array
        const remaining = todos.filter(t => !sourceIdSet.has(t.id))

        // Determine new parentId for the source and insert position in `remaining`
        const targetInRemainingIdx = remaining.findIndex(t => t.id === targetId)
        if (targetInRemainingIdx === -1)
            return
        const target = remaining[targetInRemainingIdx]

        let newParentId = null
        let insertAt = targetInRemainingIdx
        if (position === "before") {
            newParentId = target.parentId || null
            insertAt = targetInRemainingIdx
        } else if (position === "child") {
            newParentId = target.id
            insertAt = targetInRemainingIdx + 1
        } else {
            // "after": insert after target's full subtree
            newParentId = target.parentId || null
            let end = targetInRemainingIdx
            const targetDescendants = new Set()
            let changed = true
            while (changed) {
                changed = false
                for (const t of remaining) {
                    const pid = t.parentId || null
                    if (pid === null)
                        continue
                    if ((pid === target.id || targetDescendants.has(pid)) && !targetDescendants.has(t.id)) {
                        targetDescendants.add(t.id)
                        changed = true
                    }
                }
            }
            for (let i = targetInRemainingIdx + 1; i < remaining.length; i++) {
                if (targetDescendants.has(remaining[i].id))
                    end = i
                else
                    break
            }
            insertAt = end + 1
        }

        // Update the root of the source block with its new parentId
        sourceBlock[0] = Object.assign({}, sourceBlock[0], {
            parentId: newParentId
        })

        const next = remaining.slice()
        next.splice(insertAt, 0, ...sourceBlock)
        todos = next
        revision++
        saveTodos()
    }

    function editTodo(id, newText) {
        const trimmed = String(newText || "").replace(/\s+/g, " ").trim()
        if (!trimmed.length)
            return
        const idx = todos.findIndex(t => t.id === id && !t.deletedAt)
        if (idx === -1)
            return
        const next = todos.slice()
        next[idx] = Object.assign({}, next[idx], {
            text: trimmed.substring(0, maxTextLength)
        })
        todos = next
        revision++
        saveTodos()
    }

    function clearCompleted() {
        const deletedAt = new Date().toISOString()
        let changed = false
        const next = todos.map(t => {
            if (t.deletedAt || !t.completed)
                return t
            changed = true
            return Object.assign({}, t, {
                deletedAt: deletedAt
            })
        })
        if (!changed)
            return
        todos = next
        revision++
        saveTodos()
    }

    function pillCountLabel() {
        switch (countMode) {
        case "total":
            return String(visibleCount)
        case "done":
            return String(doneCount)
        case "hidden":
            return ""
        default:
            return String(activeCount)
        }
    }

    FileView {
        id: todoFile
        path: root.storageFilePath
        watchChanges: false
        blockWrites: false
        atomicWrites: true
        printErrors: false

        onLoaded: {
            let parsed = null
            try {
                parsed = JSON.parse(text())
            } catch (_) {
                parsed = null
            }
            const raw = parsed && Array.isArray(parsed.todos) ? parsed.todos : (Array.isArray(parsed) ? parsed : [])
            const clean = []
            const seenIds = new Set()
            for (let i = 0; i < raw.length; i++) {
                const t = raw[i]
                if (!t || typeof t.text !== "string")
                    continue
                let id = t.id || root.uid()
                if (seenIds.has(id))
                    id = root.uid()
                seenIds.add(id)
                clean.push({
                    id: id,
                    text: String(t.text).substring(0, root.maxTextLength),
                    completed: Boolean(t.completed),
                    parentId: t.parentId || null,
                    createdAt: t.createdAt || new Date().toISOString(),
                    completedAt: t.completedAt,
                    deletedAt: t.deletedAt
                })
            }
            const byId = new Map()
            for (let i = 0; i < clean.length; i++)
                byId.set(clean[i].id, clean[i])
            // Drop dangling parent references and parents that are soft-deleted
            for (let i = 0; i < clean.length; i++) {
                const pid = clean[i].parentId
                const parent = pid ? byId.get(pid) : null
                if (pid && (!parent || parent.deletedAt))
                    clean[i].parentId = null
            }
            root.todos = clean
            root.revision++
        }
        onLoadFailed: error => {
            if (error === 2) {
                root.todos = []
                root.revision++
                root.ensureStorageReady()
                root.saveTodos()
            }
        }
    }

    IpcHandler {
        target: "dankTodo"

        function add(text: string): string {
            const ok = root.addTodo(text, null)
            return ok ? "OK" : "FAILED"
        }

        function addChild(text: string, parentId: string): string {
            const ok = root.addTodo(text, parentId)
            return ok ? "OK" : "FAILED"
        }

        function toggle(id: string): string {
            root.toggleTodo(id)
            return "OK"
        }

        function edit(id: string, text: string): string {
            root.editTodo(id, text)
            return "OK"
        }

        function remove(id: string): string {
            root.deleteTodo(id)
            return "OK"
        }

        function move(sourceId: string, targetId: string, position: string): string {
            root.moveTodo(sourceId, targetId, position)
            return "OK"
        }

        function clearDone(): string {
            root.clearCompleted()
            return "OK"
        }

        function list(): string {
            try {
                return JSON.stringify(root.filteredTodos("all"))
            } catch (_) {
                return "[]"
            }
        }

        function count(): string {
            return root.activeCount + "/" + root.visibleCount
        }
    }

    Component.onCompleted: reloadTodos()

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.activeCount > 0 ? "checklist" : "check_circle"
                size: Theme.iconSize - 6
                color: root.activeCount > 0 ? Theme.primary : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.pillCountLabel()
                visible: text.length > 0
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.activeCount > 0 ? "checklist" : "check_circle"
                size: Theme.iconSize - 6
                color: root.activeCount > 0 ? Theme.primary : Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: root.pillCountLabel()
                visible: text.length > 0
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: "Todos"
            detailsText: root.visibleCount === 0 ? "Nothing here yet" : (root.activeCount + " active • " + root.doneCount + " done")
            showCloseButton: true

            onVisibleChanged: {
                if (visible)
                    root.reloadTodos()
            }

            Column {
                id: popoutColumn
                width: 380
                spacing: Theme.spacingM

                property string addingChildOfId: ""
                property string editingId: ""

                readonly property string addingChildOfText: {
                    if (!addingChildOfId)
                        return ""
                    const p = root.todos.find(t => t.id === addingChildOfId)
                    return p ? p.text : ""
                }

                readonly property string editingText: {
                    if (!editingId)
                        return ""
                    const p = root.todos.find(t => t.id === editingId)
                    return p ? p.text : ""
                }

                function startAddingChild(parentId) {
                    editingId = ""
                    addInput.text = ""
                    addingChildOfId = parentId
                    addInput.forceActiveFocus()
                }

                function startEditing(id) {
                    addingChildOfId = ""
                    const t = root.todos.find(x => x.id === id)
                    if (!t)
                        return
                    editingId = id
                    addInput.text = t.text
                    addInput.selectAll()
                    addInput.forceActiveFocus()
                }

                function cancelComposer() {
                    if (editingId) {
                        editingId = ""
                        addInput.text = ""
                    } else if (addingChildOfId) {
                        addingChildOfId = ""
                    }
                }

                function submitComposer() {
                    if (editingId) {
                        const id = editingId
                        const newText = addInput.text
                        editingId = ""
                        addInput.text = ""
                        root.editTodo(id, newText)
                        return true
                    }
                    if (root.addTodo(addInput.text, addingChildOfId || null)) {
                        addInput.text = ""
                        addingChildOfId = ""
                        return true
                    }
                    return false
                }

                // Drop composer state if the referenced item disappears
                Connections {
                    target: root
                    function onTodosChanged() {
                        if (popoutColumn.editingId && !root.todos.find(t => t.id === popoutColumn.editingId)) {
                            popoutColumn.editingId = ""
                            addInput.text = ""
                        }
                        if (popoutColumn.addingChildOfId && !root.todos.find(t => t.id === popoutColumn.addingChildOfId))
                            popoutColumn.addingChildOfId = ""
                    }
                }

                // Target indicator — shown when composing a subtask or editing
                Rectangle {
                    width: parent.width
                    height: 28
                    radius: Theme.cornerRadius
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                    border.width: 1
                    border.color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35)
                    visible: popoutColumn.addingChildOfId !== "" || popoutColumn.editingId !== ""

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingS
                        anchors.rightMargin: Theme.spacingXS
                        spacing: Theme.spacingXS

                        DankIcon {
                            name: popoutColumn.editingId ? "edit" : "subdirectory_arrow_right"
                            size: 14
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: popoutColumn.editingId ? ("Editing: " + popoutColumn.editingText) : ("Subtask of: " + popoutColumn.addingChildOfText)
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.primary
                            elide: Text.ElideRight
                            width: parent.width - 14 - 22 - Theme.spacingXS * 2
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            width: 22
                            height: 22
                            radius: 11
                            color: cancelChildArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            DankIcon {
                                anchors.centerIn: parent
                                name: "close"
                                size: 14
                                color: Theme.primary
                            }

                            MouseArea {
                                id: cancelChildArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: popoutColumn.cancelComposer()
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: Math.max(addInput.implicitHeight, 40)

                    DankTextField {
                        id: addInput
                        anchors.left: parent.left
                        anchors.right: addButton.left
                        anchors.rightMargin: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter
                        placeholderText: {
                            if (popoutColumn.editingId)
                                return "Edit and press Enter"
                            if (popoutColumn.addingChildOfId)
                                return "Subtask text and press Enter"
                            return "Add a todo and press Enter"
                        }
                        maximumLength: root.maxTextLength
                        onAccepted: {
                            popoutColumn.submitComposer()
                            forceActiveFocus()
                        }
                        Keys.onEscapePressed: popoutColumn.cancelComposer()
                    }

                    Rectangle {
                        id: addButton
                        width: 40
                        height: 40
                        radius: Theme.cornerRadius
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        color: addArea.containsMouse ? Theme.primary : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)

                        DankIcon {
                            anchors.centerIn: parent
                            name: popoutColumn.editingId ? "check" : "add"
                            size: 20
                            color: addArea.containsMouse ? Theme.onPrimary : Theme.primary
                        }

                        MouseArea {
                            id: addArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popoutColumn.submitComposer()
                                addInput.forceActiveFocus()
                            }
                        }
                    }
                }

                Row {
                    id: filterRow
                    width: parent.width
                    spacing: Theme.spacingXS

                    property real chipWidth: (width - spacing * 2) / 3

                    Repeater {
                        model: [
                            {
                                key: "active",
                                label: "Active",
                                count: root.activeCount
                            },
                            {
                                key: "all",
                                label: "All",
                                count: root.visibleCount
                            },
                            {
                                key: "done",
                                label: "Done",
                                count: root.doneCount
                            }
                        ]

                        Rectangle {
                            width: filterRow.chipWidth
                            height: 28
                            radius: Theme.cornerRadius
                            color: root.filter === modelData.key ? Theme.primary : (chipArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
                            border.width: root.filter === modelData.key ? 0 : 1
                            border.color: Theme.outlineVariant

                            StyledText {
                                anchors.centerIn: parent
                                text: modelData.label + " (" + modelData.count + ")"
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: root.filter === modelData.key ? Font.Medium : Font.Normal
                                color: root.filter === modelData.key ? Theme.onPrimary : Theme.surfaceText
                            }

                            MouseArea {
                                id: chipArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.filter = modelData.key
                            }
                        }
                    }
                }

                Item {
                    id: listContainer
                    width: parent.width
                    height: Math.min(320, Math.max(48, todoList.contentHeight))

                    property string dragId: ""
                    readonly property int indentStep: 20

                    ListView {
                        id: todoList
                        anchors.fill: parent
                        spacing: Theme.spacingXS
                        clip: false
                        interactive: listContainer.dragId === ""
                        model: {
                            return root.filteredTodos(root.filter)
                        }

                        displaced: Transition {
                            NumberAnimation {
                                properties: "y"
                                duration: 180
                                easing.type: Easing.OutQuad
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            id: todoScrollBar
                            policy: ScrollBar.AsNeeded
                            visible: todoList.contentHeight > todoList.height
                            width: 6
                            minimumSize: 0.1
                            contentItem: Rectangle {
                                radius: width / 2
                                color: Theme.primary
                                opacity: parent.pressed ? 0.9 : (parent.hovered ? 0.75 : 0.5)
                            }
                            background: Rectangle {
                                radius: width / 2
                                color: Theme.surfaceContainerHighest
                                opacity: 0.3
                            }
                        }

                        delegate: Item {
                            id: slot
                            width: todoList.width - (todoScrollBar.visible ? (todoScrollBar.width + Theme.spacingS) : 0)
                            height: Math.max(36, todoText.implicitHeight + Theme.spacingS * 2)

                            property var itemData: modelData
                            property string itemId: modelData ? modelData.id : ""
                            property int depth: modelData ? root.depthOf(modelData.id) : 0
                            property string dropZone: ""
                            readonly property bool isDragSource: listContainer.dragId === slot.itemId
                            readonly property bool acceptsDrag: {
                                if (!listContainer.dragId)
                                    return false
                                if (slot.isDragSource)
                                    return false
                                return !root.isDescendant(slot.itemId, listContainer.dragId)
                            }

                            Item {
                                id: dragProxy
                                width: slot.width
                                height: slot.height
                                z: slot.isDragSource ? 1000 : 0

                                Drag.active: dragHandleArea.drag.active
                                Drag.source: slot
                                Drag.hotSpot.x: dragProxy.width / 2
                                Drag.hotSpot.y: dragProxy.height / 2

                            Rectangle {
                                id: card
                                x: slot.depth * listContainer.indentStep
                                y: 0
                                width: dragProxy.width - x
                                height: dragProxy.height
                                radius: Theme.cornerRadius / 2
                                color: {
                                    if (listContainer.dragId && slot.dropZone === "child" && slot.acceptsDrag)
                                        return Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                                    if (itemHover.containsMouse)
                                        return Theme.surfaceContainerHighest
                                    return Theme.surfaceContainerHigh
                                }
                                border.width: itemHover.containsMouse || slot.isDragSource ? 1 : 0
                                border.color: slot.isDragSource ? Theme.primary : Theme.outlineVariant
                                opacity: slot.isDragSource ? 0.85 : 1.0

                                Row {
                                    id: itemRow
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacingXS
                                    anchors.rightMargin: Theme.spacingXS
                                    spacing: Theme.spacingS

                                    Rectangle {
                                        id: dragHandle
                                        width: 20
                                        height: 20
                                        radius: 10
                                        color: dragHandleArea.containsMouse || dragHandleArea.drag.active ? Theme.surfaceContainerHighest : "transparent"
                                        anchors.verticalCenter: parent.verticalCenter

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "drag_indicator"
                                            size: 16
                                            color: dragHandleArea.drag.active ? Theme.primary : Theme.surfaceVariantText
                                        }

                                        MouseArea {
                                            id: dragHandleArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: dragHandleArea.drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                            drag.target: dragProxy
                                            drag.axis: Drag.YAxis
                                            drag.threshold: 2
                                            preventStealing: true

                                            onPressed: {
                                                listContainer.dragId = slot.itemId
                                            }
                                            onReleased: {
                                                dragProxy.Drag.drop()
                                                listContainer.dragId = ""
                                                dragProxy.x = 0
                                                dragProxy.y = 0
                                            }
                                            onCanceled: {
                                                listContainer.dragId = ""
                                                dragProxy.x = 0
                                                dragProxy.y = 0
                                            }
                                        }
                                    }

                                    DankIcon {
                                        id: checkIcon
                                        name: modelData.completed ? "check_circle" : "radio_button_unchecked"
                                        size: 18
                                        color: modelData.completed ? Theme.primary : Theme.surfaceVariantText
                                        anchors.verticalCenter: parent.verticalCenter

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.toggleTodo(modelData.id)
                                        }
                                    }

                                    StyledText {
                                        id: todoText
                                        width: parent.width - (dragHandle.visible ? (dragHandle.width + Theme.spacingS) : 0) - checkIcon.width - editBtn.width - addChildBtn.width - deleteBtn.width - Theme.spacingS * 4
                                        text: modelData.text
                                        color: modelData.completed ? Theme.surfaceVariantText : Theme.surfaceText
                                        font.strikeout: modelData.completed
                                        wrapMode: Text.WordWrap
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Rectangle {
                                        id: editBtn
                                        width: 26
                                        height: 26
                                        radius: 13
                                        color: editArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : "transparent"
                                        anchors.verticalCenter: parent.verticalCenter

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "edit"
                                            size: 16
                                            color: editArea.containsMouse ? Theme.primary : Theme.surfaceVariantText
                                        }

                                        MouseArea {
                                            id: editArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: popoutColumn.startEditing(modelData.id)
                                        }
                                    }

                                    Rectangle {
                                        id: addChildBtn
                                        width: 26
                                        height: 26
                                        radius: 13
                                        color: addChildArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2) : "transparent"
                                        anchors.verticalCenter: parent.verticalCenter

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "subdirectory_arrow_right"
                                            size: 16
                                            color: addChildArea.containsMouse ? Theme.primary : Theme.surfaceVariantText
                                        }

                                        MouseArea {
                                            id: addChildArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: popoutColumn.startAddingChild(modelData.id)
                                        }
                                    }

                                    Rectangle {
                                        id: deleteBtn
                                        width: 26
                                        height: 26
                                        radius: 13
                                        color: deleteArea.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.2) : "transparent"
                                        anchors.verticalCenter: parent.verticalCenter

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "delete"
                                            size: 16
                                            color: deleteArea.containsMouse ? Theme.error : Theme.surfaceVariantText
                                        }

                                        MouseArea {
                                            id: deleteArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.deleteTodo(modelData.id)
                                        }
                                    }
                                }

                                MouseArea {
                                    id: itemHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                    z: -1
                                }

                                // Drop indicators
                                Rectangle {
                                    id: indicatorBefore
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.topMargin: -1
                                    height: 2
                                    radius: 1
                                    color: Theme.primary
                                    visible: slot.dropZone === "before" && slot.acceptsDrag
                                }

                                Rectangle {
                                    id: indicatorAfter
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: -1
                                    height: 2
                                    radius: 1
                                    color: Theme.primary
                                    visible: slot.dropZone === "after" && slot.acceptsDrag
                                }
                            }
                            }

                            DropArea {
                                anchors.fill: parent

                                onPositionChanged: drag => {
                                    if (!slot.acceptsDrag) {
                                        slot.dropZone = ""
                                        return
                                    }
                                    const y = drag.y
                                    const h = slot.height
                                    if (y < h * 0.25)
                                        slot.dropZone = "before"
                                    else if (y > h * 0.75)
                                        slot.dropZone = "after"
                                    else
                                        slot.dropZone = "child"
                                }
                                onExited: slot.dropZone = ""
                                onDropped: drop => {
                                    const sourceId = listContainer.dragId
                                    const zone = slot.dropZone
                                    slot.dropZone = ""
                                    if (sourceId && zone && slot.acceptsDrag)
                                        root.moveTodo(sourceId, slot.itemId, zone)
                                }
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            visible: todoList.count === 0
                            text: {
                                if (root.filter === "active")
                                    return "No active todos"
                                if (root.filter === "done")
                                    return "No completed todos"
                                return "No todos yet"
                            }
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: 30
                    visible: root.doneCount > 0

                    Rectangle {
                        id: clearButton
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: clearLabel.implicitWidth + Theme.spacingM * 2
                        height: 30
                        radius: Theme.cornerRadius
                        color: clearArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                        border.width: 1
                        border.color: Theme.outlineVariant

                        StyledText {
                            id: clearLabel
                            anchors.centerIn: parent
                            text: "Clear completed"
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                        }

                        MouseArea {
                            id: clearArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.clearCompleted()
                        }
                    }
                }
            }
        }
    }
}
