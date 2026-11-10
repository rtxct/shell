// ============================================================================
// File: modules/floating-stick-note-panel.module.qml
// Purpose: Detached floating stick note editor panel with swipe-to-edit and swipe-to-delete item gestures.
// Public API:
//   - Properties: sticknotes, extraData, fg, dim, accent, danger, noteId, currentNote, noteItems, addingItem
// Dependencies: QtQuick, "../styles", QtQuick.Layouts
// ============================================================================
import QtQuick
import "../styles"
import QtQuick.Layouts

// Floating Stick Note window content:
// Displays note name, scrollable notes items, add note input, swipe-to-delete / edit.
Item {
    id: root

    property var sticknotes: null
    property var extraData: null // { noteId: "...", name: "..." }

    property color fg: FloatingPanelsStyle.textPrimary
    property color dim: FloatingPanelsStyle.textDim
    property color accent: FloatingPanelsStyle.accent
    property color danger: FloatingPanelsStyle.danger

    readonly property string noteId: extraData ? (extraData.noteId || "") : ""
    readonly property var currentNote: {
        if (!sticknotes || !sticknotes.items) return null
        for (var i = 0; i < sticknotes.items.length; i++) {
            if (sticknotes.items[i].id === noteId) return sticknotes.items[i]
        }
        return null
    }

    readonly property var noteItems: currentNote ? (currentNote.notes || []) : []
    property string localColorOverride: ""
    readonly property string effectiveColorKey: localColorOverride !== "" ? localColorOverride : (currentNote ? (currentNote.color || "") : "")

    readonly property var colorPaletteModel: [
        { key: "blue", label: "Blue", color: FloatingPanelsStyle.paletteBlue },
        { key: "orange", label: "Orange", color: FloatingPanelsStyle.paletteOrange },
        { key: "red", label: "Red", color: FloatingPanelsStyle.paletteRed },
        { key: "yellow", label: "Yellow", color: FloatingPanelsStyle.paletteYellow },
        { key: "green", label: "Green", color: FloatingPanelsStyle.paletteGreen },
        { key: "cyan", label: "Cyan", color: FloatingPanelsStyle.paletteCyan },
        { key: "purple", label: "Purple", color: FloatingPanelsStyle.palettePurple },
        { key: "pink", label: "Pink", color: FloatingPanelsStyle.palettePink }
    ]

    function resolveStickNoteColor(colorKey) {
        if (colorKey === "blue") return FloatingPanelsStyle.paletteBlue
        if (colorKey === "orange") return FloatingPanelsStyle.paletteOrange
        if (colorKey === "red") return FloatingPanelsStyle.paletteRed
        if (colorKey === "yellow") return FloatingPanelsStyle.paletteYellow
        if (colorKey === "green") return FloatingPanelsStyle.paletteGreen
        if (colorKey === "cyan") return FloatingPanelsStyle.paletteCyan
        if (colorKey === "purple") return FloatingPanelsStyle.palettePurple
        if (colorKey === "pink") return FloatingPanelsStyle.palettePink
        return root.accent
    }

    readonly property color noteAccentColor: resolveStickNoteColor(effectiveColorKey)

    property bool addingItem: false
    property int selectedNoteIndex: -1
    property bool editingSelectedNote: false
    property bool pickingColor: false
    readonly property bool isViewingNote: selectedNoteIndex >= 0 && selectedNoteIndex < noteItems.length
    property real viewNoteProgress: isViewingNote ? 1.0 : 0.0
    Behavior on viewNoteProgress {
        NumberAnimation { duration: FloatingPanelsStyle.noteSwipeSnapDurationMs; easing.type: Easing.OutCubic }
    }
    property real pickingColorProgress: pickingColor ? 1.0 : 0.0
    Behavior on pickingColorProgress {
        NumberAnimation { duration: FloatingPanelsStyle.noteSwipeSnapDurationMs; easing.type: Easing.OutCubic }
    }
    readonly property real subviewProgress: Math.max(viewNoteProgress, pickingColorProgress)
    property string cachedNoteText: ""
    readonly property string selectedNoteText: isViewingNote ? noteItems[selectedNoteIndex] : cachedNoteText
    onSelectedNoteTextChanged: {
        if (isViewingNote) cachedNoteText = noteItems[selectedNoteIndex] || ""
    }

    function saveFullNoteEdit() {
        if (!isViewingNote) return
        var trimmed = fullNoteEditInput.text.trim()
        if (trimmed && root.sticknotes) {
            cachedNoteText = trimmed
            root.sticknotes.editItem(root.noteId, selectedNoteIndex, trimmed)
        }
        editingSelectedNote = false
    }

    Column {
        anchors.fill: parent
        spacing: 10
        visible: opacity > 0.01
        opacity: 1.0 - root.subviewProgress
        scale: 1.0 - 0.06 * root.subviewProgress
        transformOrigin: Item.Center

        // Subheader: Note Name (clickable to choose color) & Add '+' Button
        Item {
            id: floatSubheader
            width: parent.width
            height: 28

            Row {
                id: floatTitleRow
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Text {
                    id: floatNoteIcon
                    text: "󰠮"
                    font.family: FloatingPanelsStyle.iconFont
                    font.pixelSize: 14
                    color: root.noteAccentColor
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.currentNote ? root.currentNote.name : "Stick Note"
                    color: floatTitleMouse.containsMouse ? root.noteAccentColor : root.fg
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, Math.max(0, floatSubheader.width - 64))
                }
            }

            MouseArea {
                id: floatTitleMouse
                anchors.left: floatTitleRow.left
                anchors.verticalCenter: floatTitleRow.verticalCenter
                width: floatTitleRow.width
                height: parent.height
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.selectedNoteIndex = -1
                    root.editingSelectedNote = false
                    root.pickingColor = true
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: FloatingPanelsStyle.noteAddBtnSize
                height: FloatingPanelsStyle.noteAddBtnSize
                radius: FloatingPanelsStyle.noteAddBtnRadius
                color: addMouse.containsMouse ? root.accent : FloatingPanelsStyle.itemHoverBg

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    color: addMouse.containsMouse ? FloatingPanelsStyle.textOnAccent : root.accent
                }

                MouseArea {
                    id: addMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.addingItem = true
                        noteInput.forceActiveFocus()
                    }
                }
            }
        }

        // Inline Add Note Input
        Rectangle {
            width: parent.width
            height: root.addingItem ? FloatingPanelsStyle.searchBoxHeight : 0
            visible: root.addingItem
            clip: true
            radius: FloatingPanelsStyle.cardRadius
            color: FloatingPanelsStyle.searchBoxBg
            border.width: 1
            border.color: root.accent

            Behavior on height { NumberAnimation { duration: FloatingPanelsStyle.noteAddInputDurationMs } }

            Row {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6

                TextInput {
                    id: noteInput
                    width: parent.width - 32
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.fg
                    font.pixelSize: 12
                    clip: true

                    onAccepted: {
                        if (text.trim() !== "" && root.sticknotes) {
                            root.sticknotes.addItem(root.noteId, text.trim())
                            text = ""
                        }
                        root.addingItem = false
                    }

                    Keys.onEscapePressed: {
                        text = ""
                        root.addingItem = false
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✓"
                    color: root.accent
                    font.pixelSize: 14
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (noteInput.text.trim() !== "" && root.sticknotes) {
                                root.sticknotes.addItem(root.noteId, noteInput.text.trim())
                                noteInput.text = ""
                            }
                            root.addingItem = false
                        }
                    }
                }
            }
        }

        // Notes List
        ListView {
            id: listView
            width: parent.width
            height: parent.height - (root.addingItem ? 74 : 38)
            clip: true
            spacing: 6
            model: root.noteItems

            Text {
                anchors.centerIn: parent
                visible: listView.count === 0 && !root.addingItem
                text: "No notes yet.\nClick + above to add one."
                color: root.dim
                font.pixelSize: 12
                horizontalAlignment: Text.AlignHCenter
            }

            delegate: Item {
                id: itemDelegate
                required property var modelData
                required property int index

                width: listView.width
                height: isEditing ? StickNotesBarStyle.rowEditingHeight : FloatingPanelsStyle.noteItemHeight

                property bool isEditing: false

                // Background: Trash on left swipe, Edit pen on right swipe
                // Action buttons are ONLY visible in the revealed gap when pulled left or right
                Item {
                    anchors.fill: parent

                    // Edit action on the left (only revealed when pulled right: cardFront.x > 0)
                    Rectangle {
                        objectName: "swipeEditAction"
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.min(StickNotesBarStyle.swipeRevealedOffset, Math.max(0, cardFront.x - 2))
                        radius: FloatingPanelsStyle.cardRadius
                        color: FloatingPanelsStyle.editSwipeBg
                        opacity: Math.min(1.0, Math.max(0.0, cardFront.x / FloatingPanelsStyle.noteSwipeActionThreshold))
                        visible: opacity > 0.01
                        clip: true

                        Text {
                            anchors.centerIn: parent
                            text: "󰏫"
                            font.family: FloatingPanelsStyle.iconFont
                            font.pixelSize: StickNotesBarStyle.swipeActionIconFontPx
                            color: StickNotesBarStyle.editSwipeIcon
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: parent.visible
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                itemDelegate.isEditing = true
                                cardFront.x = 0
                                editInput.forceActiveFocus()
                            }
                        }
                    }

                    // Trash action on the right (only revealed when pulled left: cardFront.x < 0)
                    Rectangle {
                        objectName: "swipeDeleteAction"
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: Math.min(StickNotesBarStyle.swipeRevealedOffset, Math.max(0, -cardFront.x - 2))
                        radius: FloatingPanelsStyle.cardRadius
                        color: StickNotesBarStyle.deleteHoverTint
                        opacity: Math.min(1.0, Math.max(0.0, -cardFront.x / FloatingPanelsStyle.noteSwipeActionThreshold))
                        visible: opacity > 0.01
                        clip: true

                        Text {
                            anchors.centerIn: parent
                            text: "󰆴"
                            font.family: FloatingPanelsStyle.iconFont
                            font.pixelSize: StickNotesBarStyle.swipeActionIconFontPx
                            color: root.danger
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: parent.visible
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.sticknotes) {
                                    root.sticknotes.deleteItem(root.noteId, itemDelegate.index)
                                }
                            }
                        }
                    }
                }

                // Foreground draggable & clickable card (matches StickNotesBar behavior)
                Rectangle {
                    id: cardFront
                    width: parent.width
                    height: parent.height
                    radius: FloatingPanelsStyle.cardRadius
                    color: itemDragArea.containsMouse ? FloatingPanelsStyle.buttonHoverBg : FloatingPanelsStyle.noteCardBg
                    border.width: 1
                    border.color: (itemDragArea.containsMouse || itemDelegate.isEditing) ? root.accent : FloatingPanelsStyle.noteCardBorder
                    clip: true
                    Behavior on color { ColorAnimation { duration: FloatingPanelsStyle.noteAddInputDurationMs } }
                    Behavior on border.color { ColorAnimation { duration: FloatingPanelsStyle.noteAddInputDurationMs } }

                    Behavior on x {
                        enabled: !itemDragArea.drag.active
                        NumberAnimation { duration: FloatingPanelsStyle.noteSwipeSnapDurationMs; easing.type: Easing.OutCubic }
                    }

                    // Display mode: Single-line Note Preview (shows "..." when note has multiple lines)
                    Text {
                        objectName: "noteCardPreviewText"
                        anchors.fill: parent
                        anchors.leftMargin: StickNotesBarStyle.noteCardTextMargin
                        anchors.rightMargin: StickNotesBarStyle.noteCardTextMargin
                        verticalAlignment: Text.AlignVCenter
                        text: {
                            var raw = String(itemDelegate.modelData || "")
                            var nl = raw.search(/\r?\n/)
                            return nl >= 0 ? (raw.substring(0, nl) + "...") : raw
                        }
                        color: root.fg
                        font.pixelSize: StickNotesBarStyle.itemInputFontPx
                        maximumLineCount: 1
                        elide: Text.ElideRight
                        visible: !itemDelegate.isEditing
                    }

                    // Edit mode: Inline TextInput
                    TextInput {
                        id: editInput
                        anchors.fill: parent
                        anchors.leftMargin: StickNotesBarStyle.itemInputMargin
                        anchors.rightMargin: StickNotesBarStyle.itemInputMargin
                        verticalAlignment: TextInput.AlignVCenter
                        text: itemDelegate.modelData
                        font.pixelSize: StickNotesBarStyle.itemInputFontPx
                        color: root.accent
                        visible: itemDelegate.isEditing
                        focus: itemDelegate.isEditing

                        onVisibleChanged: {
                            if (visible) {
                                forceActiveFocus()
                                cursorPosition = text.length
                            }
                        }

                        onAccepted: {
                            if (text.trim() !== "" && root.sticknotes) {
                                root.sticknotes.editItem(root.noteId, itemDelegate.index, text.trim())
                            }
                            itemDelegate.isEditing = false
                        }
                        Keys.onEscapePressed: {
                            itemDelegate.isEditing = false
                            text = itemDelegate.modelData
                        }
                    }

                    // Drag handler for Gmail-style swipe + click to open full note view
                    MouseArea {
                        id: itemDragArea
                        objectName: "cardDragMouse"
                        anchors.fill: parent
                        enabled: !itemDelegate.isEditing
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        drag.target: cardFront
                        drag.axis: Drag.XAxis
                        drag.minimumX: -FloatingPanelsStyle.noteSwipeMaxOffset
                        drag.maximumX: FloatingPanelsStyle.noteSwipeMaxOffset

                        onClicked: {
                            if (Math.abs(cardFront.x) > 2) {
                                cardFront.x = 0
                            } else {
                                root.cachedNoteText = itemDelegate.modelData || ""
                                root.selectedNoteIndex = itemDelegate.index
                                root.editingSelectedNote = false
                            }
                        }

                        onReleased: {
                            if (cardFront.x < -FloatingPanelsStyle.noteSwipeActionThreshold) {
                                cardFront.x = -StickNotesBarStyle.swipeRevealedOffset
                            } else if (cardFront.x > FloatingPanelsStyle.noteSwipeActionThreshold) {
                                cardFront.x = StickNotesBarStyle.swipeRevealedOffset
                            } else {
                                cardFront.x = 0
                            }
                        }
                    }
                }
            }
        }
    }

    // Full-Note Inspection View (Takes entire area when a note is clicked)
    Column {
        anchors.fill: parent
        spacing: 10
        visible: opacity > 0.01
        opacity: root.viewNoteProgress
        scale: 0.88 + 0.12 * root.viewNoteProgress
        transformOrigin: Item.Center

        Item {
            width: parent.width
            height: 28

            // Top-left back arrow button
            Rectangle {
                id: floatBackBtn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: FloatingPanelsStyle.noteAddBtnSize
                height: FloatingPanelsStyle.noteAddBtnSize
                radius: FloatingPanelsStyle.noteAddBtnRadius
                color: floatBackMouse.containsMouse ? FloatingPanelsStyle.itemHoverBg : FloatingPanelsStyle.transparent

                Text {
                    anchors.centerIn: parent
                    text: "󰁍"
                    font.family: FloatingPanelsStyle.iconFont
                    font.pixelSize: 13
                    color: floatBackMouse.containsMouse ? root.accent : root.dim
                }

                MouseArea {
                    id: floatBackMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.editingSelectedNote = false
                        root.selectedNoteIndex = -1
                    }
                }
            }

            Text {
                anchors.left: floatBackBtn.right
                anchors.leftMargin: 6
                anchors.right: floatRightActions.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: root.currentNote ? root.currentNote.name : "Stick Note"
                color: root.fg
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            // Top-right subtle Edit and Trash buttons
            Row {
                id: floatRightActions
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Rectangle {
                    width: FloatingPanelsStyle.noteAddBtnSize
                    height: FloatingPanelsStyle.noteAddBtnSize
                    radius: FloatingPanelsStyle.noteAddBtnRadius
                    color: floatEditMouse.containsMouse ? FloatingPanelsStyle.itemHoverBg : FloatingPanelsStyle.transparent

                    Text {
                        anchors.centerIn: parent
                        text: root.editingSelectedNote ? "󰄬" : "󰏫"
                        font.family: FloatingPanelsStyle.iconFont
                        font.pixelSize: 13
                        color: (floatEditMouse.containsMouse || root.editingSelectedNote) ? root.accent : root.dim
                    }

                    MouseArea {
                        id: floatEditMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (root.editingSelectedNote) {
                                root.saveFullNoteEdit()
                            } else {
                                fullNoteEditInput.text = root.selectedNoteText
                                root.editingSelectedNote = true
                                fullNoteEditInput.forceActiveFocus()
                            }
                        }
                    }
                }

                Rectangle {
                    width: FloatingPanelsStyle.noteAddBtnSize
                    height: FloatingPanelsStyle.noteAddBtnSize
                    radius: FloatingPanelsStyle.noteAddBtnRadius
                    color: floatDelMouse.containsMouse ? FloatingPanelsStyle.mutedTint : FloatingPanelsStyle.transparent

                    Text {
                        anchors.centerIn: parent
                        text: "󰆴"
                        font.family: FloatingPanelsStyle.iconFont
                        font.pixelSize: 13
                        color: floatDelMouse.containsMouse ? root.danger : root.dim
                    }

                    MouseArea {
                        id: floatDelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            var idxToDelete = root.selectedNoteIndex
                            root.editingSelectedNote = false
                            root.selectedNoteIndex = -1
                            if (idxToDelete >= 0 && root.sticknotes) {
                                root.sticknotes.deleteItem(root.noteId, idxToDelete)
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - y
            radius: FloatingPanelsStyle.cardRadius
            color: FloatingPanelsStyle.noteCardBg
            border.width: 1
            border.color: root.editingSelectedNote ? root.accent : FloatingPanelsStyle.noteCardBorder
            clip: true

            Flickable {
                anchors.fill: parent
                anchors.margins: 10
                contentWidth: width
                contentHeight: floatFullNoteText.paintedHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: !root.editingSelectedNote

                Text {
                    id: floatFullNoteText
                    width: parent.width
                    text: root.selectedNoteText
                    font.pixelSize: 12
                    color: root.fg
                    wrapMode: Text.Wrap
                }
            }

            Flickable {
                anchors.fill: parent
                anchors.margins: 10
                contentWidth: width
                contentHeight: fullNoteEditInput.paintedHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                visible: root.editingSelectedNote

                TextEdit {
                    id: fullNoteEditInput
                    width: parent.width
                    text: root.selectedNoteText
                    font.pixelSize: 12
                    color: root.fg
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (event.modifiers & Qt.ShiftModifier) {
                                event.accepted = false
                            } else {
                                event.accepted = true
                                root.saveFullNoteEdit()
                            }
                        }
                    }

                    Keys.onEscapePressed: {
                        root.editingSelectedNote = false
                        text = root.selectedNoteText
                    }
                }
            }
        }
    }

    // Color Palette View (Opens animated when clicking icon or name on top-left)
    Column {
        anchors.fill: parent
        spacing: 10
        visible: opacity > 0.01
        opacity: root.pickingColorProgress
        scale: 0.88 + 0.12 * root.pickingColorProgress
        transformOrigin: Item.Center

        Item {
            width: parent.width
            height: 28

            Rectangle {
                id: floatPaletteBackBtn
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: FloatingPanelsStyle.noteAddBtnSize
                height: FloatingPanelsStyle.noteAddBtnSize
                radius: FloatingPanelsStyle.noteAddBtnRadius
                color: floatPaletteBackMouse.containsMouse ? FloatingPanelsStyle.itemHoverBg : FloatingPanelsStyle.transparent

                Text {
                    anchors.centerIn: parent
                    text: "󰁍"
                    font.family: FloatingPanelsStyle.iconFont
                    font.pixelSize: 13
                    color: floatPaletteBackMouse.containsMouse ? root.noteAccentColor : root.dim
                }

                MouseArea {
                    id: floatPaletteBackMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.pickingColor = false
                    }
                }
            }

            Text {
                anchors.left: floatPaletteBackBtn.right
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: "Choose Bar Color"
                color: root.fg
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
        }

        Rectangle {
            width: parent.width
            height: parent.height - y
            radius: FloatingPanelsStyle.cardRadius
            color: FloatingPanelsStyle.noteCardBg
            border.width: 1
            border.color: FloatingPanelsStyle.noteCardBorder
            clip: true

            Grid {
                anchors.centerIn: parent
                columns: 4
                spacing: 16

                Repeater {
                    model: root.colorPaletteModel

                    delegate: Rectangle {
                        id: floatSwatchItem
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: root.effectiveColorKey === modelData.key
                            || (root.effectiveColorKey === "" && index === 0)

                        width: 48
                        height: 48
                        radius: 24
                        color: floatSwatchMouse.containsMouse ? FloatingPanelsStyle.buttonHoverBg : FloatingPanelsStyle.buttonBg
                        border.width: (isSelected || floatSwatchMouse.containsMouse) ? 2 : 1
                        border.color: (isSelected || floatSwatchMouse.containsMouse) ? modelData.color : FloatingPanelsStyle.noteCardBorder
                        scale: floatSwatchMouse.containsMouse ? 1.08 : 1.0
                        Behavior on scale { NumberAnimation { duration: FloatingPanelsStyle.noteAddInputDurationMs; easing.type: Easing.OutCubic } }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            radius: 14
                            color: floatSwatchItem.modelData.color

                            Text {
                                anchors.centerIn: parent
                                visible: floatSwatchItem.isSelected
                                text: "✓"
                                font.pixelSize: 14
                                font.weight: Font.Bold
                                color: FloatingPanelsStyle.textBright
                            }
                        }

                        MouseArea {
                            id: floatSwatchMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.localColorOverride = floatSwatchItem.modelData.key
                                if (root.sticknotes) {
                                    root.sticknotes.setColor(root.noteId, floatSwatchItem.modelData.key)
                                }
                                root.pickingColor = false
                            }
                        }
                    }
                }
            }
        }
    }
}
