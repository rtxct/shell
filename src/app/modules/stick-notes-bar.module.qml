// ============================================================================
// File: modules/stick-notes-bar.module.qml
// Purpose: Right-edge stick notes drawer system with creation drawer, note tabs, and Gmail-style swipe-to-edit/delete actions.
// Public API:
//   - Properties: sticknotes, floatManager, fg, dim, accent, fill, danger, cardBg, creatingNew, activeDrawerId, isAnyOpen, plusBtnHeight ...
//   - Functions:  closeAll()
// Dependencies: "../components", "../styles", "../theme", QtQuick, QtQuick.Layouts
// ============================================================================
import "../components"
import "../styles"
import "../../../themes"
import QtQuick
import QtQuick.Layouts

// Stick Notes Drawer Manager on the Right Edge of the Screen
Item {
    id: root

    required property var sticknotes
    property var floatManager: null

    property color fg: StickNotesBarStyle.textPrimary
    property color dim: StickNotesBarStyle.textDim
    property color accent: StickNotesBarStyle.accent
    property color fill: StickNotesBarStyle.fill
    property color danger: StickNotesBarStyle.danger
    property color cardBg: StickNotesBarStyle.cardBg

    // ── State ──
    property bool creatingNew: false
    property string activeDrawerId: ""
    property bool isAnyDetaching: false
    readonly property bool isAnyOpen: creatingNew || activeDrawerId !== ""

    // ── Dimensions ──
    readonly property real plusBtnHeight: StickNotesBarStyle.plusIdleHeight
    readonly property real plusBtnOpenDepth: StickNotesBarStyle.plusHoverDepth
    readonly property real drawerIdleDepth: StickNotesBarStyle.drawerIdleDepth
    readonly property real drawerOpenDepth: StickNotesBarStyle.drawerOpenDepth
    readonly property real drawerHeight: StickNotesBarStyle.drawerOpenHeight

    // Dynamic active depth matching visible tabs & open drawers with zero phantom padding.
    // When idle, width collapses to drawerIdleDepth (8px), leaving the desktop completely click-through.
    readonly property real activeDepth: {
        var d = root.drawerIdleDepth
        if (plusWrapper.isHovered) {
            d = Math.max(d, root.plusBtnOpenDepth)
        }
        if (creatingNew) {
            d = Math.max(d, StickNotesBarStyle.creationWidth)
        }
        if (activeDrawerId !== "" || isAnyDetaching) {
            d = Math.max(d, root.drawerOpenDepth)
        }
        return d
    }

    width: activeDepth
    height: contentColumn.implicitHeight
    Behavior on width { NumberAnimation { duration: StickNotesBarStyle.drawerDepthDurationMs; easing.type: Easing.OutCubic } }

    // ── Mask for Wayland LayerShell Input ──
    readonly property Item maskItem: barMask
    Item {
        id: barMask
        anchors.fill: parent
    }

    // ── Dismissal & Escape Shortcut ──
    Shortcut {
        sequence: "Escape"
        enabled: root.isAnyOpen
        onActivated: root.closeAll()
    }

    function closeAll() {
        root.creatingNew = false
        root.activeDrawerId = ""
    }

    readonly property var colorPaletteModel: [
        { key: "blue", label: "Blue", color: StickNotesBarStyle.paletteBlue },
        { key: "orange", label: "Orange", color: StickNotesBarStyle.paletteOrange },
        { key: "red", label: "Red", color: StickNotesBarStyle.paletteRed },
        { key: "yellow", label: "Yellow", color: StickNotesBarStyle.paletteYellow },
        { key: "green", label: "Green", color: StickNotesBarStyle.paletteGreen },
        { key: "cyan", label: "Cyan", color: StickNotesBarStyle.paletteCyan },
        { key: "purple", label: "Purple", color: StickNotesBarStyle.palettePurple },
        { key: "pink", label: "Pink", color: StickNotesBarStyle.palettePink }
    ]

    function resolveStickNoteColor(colorKey) {
        if (colorKey === "blue") return StickNotesBarStyle.paletteBlue
        if (colorKey === "orange") return StickNotesBarStyle.paletteOrange
        if (colorKey === "red") return StickNotesBarStyle.paletteRed
        if (colorKey === "yellow") return StickNotesBarStyle.paletteYellow
        if (colorKey === "green") return StickNotesBarStyle.paletteGreen
        if (colorKey === "cyan") return StickNotesBarStyle.paletteCyan
        if (colorKey === "purple") return StickNotesBarStyle.palettePurple
        if (colorKey === "pink") return StickNotesBarStyle.palettePink
        return root.accent
    }

    Column {
        id: contentColumn
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: StickNotesBarStyle.stackSpacing

        // ────────────────────────────────────────────────────────
        // 1. THE "+" DRAWER BUTTON (1/4 size of middle island)
        // ────────────────────────────────────────────────────────
        Item {
            id: plusWrapper
            anchors.right: parent.right
            width: plusDrop.width
            height: root.plusBtnHeight

            HoverHandler {
                id: plusHover
                onHoveredChanged: {
                    if (hovered) {
                        plusCloseTimer.stop()
                    } else {
                        plusCloseTimer.restart()
                    }
                }
            }

            Timer {
                id: plusCloseTimer
                interval: StickNotesBarStyle.plusUnhoverMs
            }

            readonly property bool isHovered: plusHover.hovered || plusCloseTimer.running

            Drop {
                id: plusDrop
                fromRight: true
                anchors.right: parent.right
                height: root.plusBtnHeight
                width: (plusWrapper.isHovered || root.creatingNew) ? root.plusBtnOpenDepth : root.drawerIdleDepth
                fill: root.fill
                slant: StickNotesBarStyle.plusSlant
                rad: StickNotesBarStyle.plusRadius
                flare: StickNotesBarStyle.plusFlare
                inset: StickNotesBarStyle.plusInset
                bottomInset: StickNotesBarStyle.plusInset

                Behavior on width { NumberAnimation { duration: StickNotesBarStyle.plusExpandDurationMs; easing.type: Easing.OutCubic } }

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    font.family: "Symbols Nerd Font"
                    font.pixelSize: StickNotesBarStyle.plusIconFontPx
                    font.weight: Font.Bold
                    color: plusWrapper.isHovered ? root.accent : root.fg
                    opacity: plusDrop.width > StickNotesBarStyle.plusShowThreshold ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: StickNotesBarStyle.colorAnimDurationMs } }
                    Behavior on color { ColorAnimation { duration: StickNotesBarStyle.colorAnimDurationMs } }
                }

                MouseArea {
                    id: plusMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.creatingNew) {
                            root.creatingNew = false
                        } else {
                            root.activeDrawerId = ""
                            root.creatingNew = true
                        }
                    }
                }
            }
        }

        // ────────────────────────────────────────────────────────
        // 2. NEW STICK NOTE CREATION DRAWER (under the "+" button)
        // ────────────────────────────────────────────────────────
        Item {
            id: creationWrapper
            anchors.right: parent.right
            width: creationDrop.width
            height: root.creatingNew ? StickNotesBarStyle.creationHeight : 0
            visible: height > 0
            clip: true

            Behavior on height { NumberAnimation { duration: StickNotesBarStyle.creationAnimDurationMs; easing.type: Easing.OutCubic } }

            Drop {
                id: creationDrop
                fromRight: true
                anchors.right: parent.right
                width: root.creatingNew ? StickNotesBarStyle.creationWidth : 0
                height: StickNotesBarStyle.creationHeight
                fill: root.fill
                slant: StickNotesBarStyle.creationSlant
                rad: StickNotesBarStyle.creationRadius
                flare: StickNotesBarStyle.creationFlare
                inset: StickNotesBarStyle.creationInset
                bottomInset: StickNotesBarStyle.creationInset

                Behavior on width { NumberAnimation { duration: StickNotesBarStyle.creationAnimDurationMs; easing.type: Easing.OutCubic } }

                Column {
                    anchors.fill: parent
                    anchors.margins: StickNotesBarStyle.creationMargins
                    spacing: StickNotesBarStyle.creationSpacing

                    Row {
                        width: parent.width
                        spacing: StickNotesBarStyle.creationHeaderSpacing
                        Text {
                            text: "󰠮"
                            font.family: "Symbols Nerd Font"
                            font.pixelSize: StickNotesBarStyle.creationHeaderIconFontPx
                            color: root.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "New Stick Note"
                            font.pixelSize: StickNotesBarStyle.creationHeaderTitleFontPx
                            font.weight: Font.Bold
                            color: root.fg
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Input for Stick Note Name
                    Rectangle {
                        width: parent.width
                        height: StickNotesBarStyle.creationInputHeight
                        radius: StickNotesBarStyle.creationInputRadius
                        color: StickNotesBarStyle.inputBg
                        border.width: 1
                        border.color: nameInput.activeFocus ? root.accent : StickNotesBarStyle.inputBorder
                        Behavior on border.color { ColorAnimation { duration: StickNotesBarStyle.colorAnimDurationMs } }

                        TextInput {
                            id: nameInput
                            anchors.fill: parent
                            anchors.leftMargin: StickNotesBarStyle.creationInputMargin
                            anchors.rightMargin: StickNotesBarStyle.creationInputMargin
                            verticalAlignment: TextInput.AlignVCenter
                            color: root.fg
                            font.pixelSize: StickNotesBarStyle.creationInputFontPx
                            focus: root.creatingNew
                            clip: true

                            Text {
                                text: "Note name (e.g. Ideas)..."
                                color: root.dim
                                font.pixelSize: StickNotesBarStyle.creationInputFontPx
                                visible: !nameInput.text && !nameInput.activeFocus
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Keys.onEscapePressed: {
                                root.creatingNew = false
                                nameInput.text = ""
                            }

                            onAccepted: creationWrapper.confirmCreate()
                        }
                    }

                    // Exit/options hint placeholder on its own line
                    Text {
                        width: parent.width
                        text: "↵ to create  •  Esc to cancel"
                        font.pixelSize: StickNotesBarStyle.creationHintFontPx
                        color: root.dim
                    }

                    // Create button on the bottom-left
                    Rectangle {
                        id: createNoteBtn
                        objectName: "createNoteBtn"
                        anchors.left: parent.left
                        width: StickNotesBarStyle.creationBtnWidth
                        height: StickNotesBarStyle.creationBtnHeight
                        radius: StickNotesBarStyle.creationBtnRadius
                        color: root.accent

                        Text {
                            anchors.centerIn: parent
                            text: "Create"
                            font.pixelSize: StickNotesBarStyle.creationBtnFontPx
                            font.weight: Font.Bold
                            color: StickNotesBarStyle.textOnAccent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: creationWrapper.confirmCreate()
                        }
                    }
                }
            }

            function confirmCreate() {
                var name = nameInput.text.trim()
                if (root.sticknotes) {
                    root.sticknotes.create(name || "Stick Note")
                }
                nameInput.text = ""
                root.creatingNew = false
            }
        }

        // ────────────────────────────────────────────────────────
        // 3. EXISTING STICK NOTES (Stacked under the "+" button)
        // ────────────────────────────────────────────────────────
        Repeater {
            model: root.sticknotes ? root.sticknotes.items : []

            delegate: Item {
                id: noteDrawerItem
                objectName: "noteDrawer_" + modelData.id
                required property var modelData
                required property int index

                readonly property bool isFloating: root.floatManager ? (
                    (root.floatManager.fw0.active && root.floatManager.fw0.winId === ("sticknote-" + modelData.id))
                    || (root.floatManager.fw1.active && root.floatManager.fw1.winId === ("sticknote-" + modelData.id))
                    || (root.floatManager.fw2.active && root.floatManager.fw2.winId === ("sticknote-" + modelData.id))
                    || (root.floatManager.fw3.active && root.floatManager.fw3.winId === ("sticknote-" + modelData.id))
                    || (root.floatManager.fw4.active && root.floatManager.fw4.winId === ("sticknote-" + modelData.id))
                    || (root.floatManager.fw5.active && root.floatManager.fw5.winId === ("sticknote-" + modelData.id))
                    || (root.floatManager.fw6.active && root.floatManager.fw6.winId === ("sticknote-" + modelData.id))
                    || (root.floatManager.fw7.active && root.floatManager.fw7.winId === ("sticknote-" + modelData.id))
                ) : false
                readonly property bool isDetachingFromOpen: drawerBgDragMouse.isDetachingDrawer || headerBgDragMouse.isDetachingHeader || headerTitleMouse.isDetachingHeader || addMouse.isDetachingAdd
                readonly property bool isActivelyDetaching: closedTab.isDetaching || isDetachingFromOpen
                readonly property bool hideInBar: isFloating && !isActivelyDetaching
                readonly property bool isOpen: !isFloating && root.activeDrawerId === modelData.id
                property string localColorOverride: ""
                readonly property string effectiveColorKey: localColorOverride !== "" ? localColorOverride : (modelData.color || "")
                readonly property color noteAccentColor: root.resolveStickNoteColor(effectiveColorKey)
                anchors.right: parent ? parent.right : undefined
                width: noteDrop.width
                height: hideInBar ? 0 : ((isOpen || isDetachingFromOpen) ? root.drawerHeight : StickNotesBarStyle.drawerIdleHeight)
                opacity: isFloating ? 0.0 : 1.0
                visible: (opacity > 0.01 && height > 0.5) || isActivelyDetaching

                Behavior on opacity { NumberAnimation { duration: StickNotesBarStyle.drawerHeightDurationMs; easing.type: Easing.OutCubic } }

                function beginDetach(ptX, ptY) {
                    unhoverTimer.stop()
                    root.isAnyDetaching = true
                    if (root.floatManager) {
                        root.floatManager.startDrag({
                            id: "sticknote-" + modelData.id,
                            title: modelData.name || "Stick Note",
                            icon: "󰠮",
                            originSide: "right",
                            originX: root.x,
                            originY: root.y + noteDrawerItem.y,
                            width: StickNotesBarStyle.floatWidth,
                            height: StickNotesBarStyle.floatHeight,
                            extraData: { noteId: modelData.id, name: modelData.name },
                            sticknotes: root.sticknotes
                        }, ptX, ptY)
                    }
                }

                function moveDetach(ptX, ptY) {
                    if (root.floatManager) {
                        root.floatManager.updateDrag(ptX, ptY)
                    }
                }

                function finishDetach() {
                    root.isAnyDetaching = false
                    root.activeDrawerId = ""
                    if (root.floatManager) {
                        root.floatManager.endDrag()
                    }
                }

                onIsOpenChanged: {
                    if (!isOpen) {
                        openContent.selectedNoteIndex = -1
                        openContent.editingSelectedNote = false
                        openContent.inlineEditingNote = false
                        openContent.pickingColor = false
                    }
                }

                Behavior on height { NumberAnimation { duration: StickNotesBarStyle.drawerHeightDurationMs; easing.type: Easing.OutCubic } }

                HoverHandler {
                    id: drawerHover
                    enabled: !noteDrawerItem.isFloating && !noteDrawerItem.isActivelyDetaching && !closedTabMouse.pressed
                    onHoveredChanged: {
                        if (hovered && !noteDrawerItem.isFloating && !noteDrawerItem.isActivelyDetaching && !closedTabMouse.pressed) {
                            unhoverTimer.stop()
                            root.creatingNew = false
                            root.activeDrawerId = modelData.id
                        } else {
                            unhoverTimer.restart()
                        }
                    }
                }

                Timer {
                    id: unhoverTimer
                    interval: StickNotesBarStyle.drawerUnhoverMs
                    onTriggered: {
                        if (!drawerHover.hovered && !noteDrawerItem.isActivelyDetaching && !openContent.hasActiveInput && root.activeDrawerId === modelData.id) {
                            root.activeDrawerId = ""
                        }
                    }
                }

                Drop {
                    id: noteDrop
                    fromRight: true
                    anchors.right: parent.right
                    height: parent.height
                    width: noteDrawerItem.hideInBar ? 0 : ((noteDrawerItem.isOpen || noteDrawerItem.isDetachingFromOpen) ? root.drawerOpenDepth : root.drawerIdleDepth)
                    fill: root.fill
                    slant: noteDrawerItem.isOpen ? StickNotesBarStyle.drawerOpenSlant : StickNotesBarStyle.drawerIdleSlant
                    rad: StickNotesBarStyle.drawerRadius
                    flare: StickNotesBarStyle.drawerFlare
                    inset: StickNotesBarStyle.drawerInset
                    bottomInset: StickNotesBarStyle.drawerInset

                    Behavior on width { NumberAnimation { duration: StickNotesBarStyle.drawerDepthDurationMs; easing.type: Easing.OutCubic } }

                    // Background drag handle covering margins and empty drawer space when open
                    MouseArea {
                        id: drawerBgDragMouse
                        anchors.fill: parent
                        enabled: noteDrawerItem.isOpen || isDetachingDrawer
                        cursorShape: Qt.SizeAllCursor
                        property real pressSceneX: 0
                        property real pressSceneY: 0
                        property bool isDetachingDrawer: false

                        onPressed: function(mouse) {
                            var pt = mapToItem(null, mouse.x, mouse.y)
                            pressSceneX = pt.x
                            pressSceneY = pt.y
                            isDetachingDrawer = false
                        }

                        onPositionChanged: function(mouse) {
                            if (!pressed) return
                            var pt = mapToItem(null, mouse.x, mouse.y)
                            var dx = pt.x - pressSceneX
                            var dy = pt.y - pressSceneY

                            if (!isDetachingDrawer && root.floatManager && (dx < StickNotesBarStyle.detachThresholdX || Math.hypot(dx, dy) > StickNotesBarStyle.detachThresholdHypot)) {
                                isDetachingDrawer = true
                                noteDrawerItem.beginDetach(pt.x, pt.y)
                            } else if (isDetachingDrawer) {
                                noteDrawerItem.moveDetach(pt.x, pt.y)
                            }
                        }

                        onReleased: {
                            if (isDetachingDrawer) {
                                isDetachingDrawer = false
                                noteDrawerItem.finishDetach()
                            }
                        }
                    }

                    // ── A. CLOSED TAB (when idle) ──
                    Item {
                        id: closedTab
                        anchors.fill: parent
                        visible: opacity > 0.01 || closedTabMouse.pressed || closedTab.isDetaching
                        opacity: noteDrawerItem.isOpen ? 0.0 : 1.0
                        Behavior on opacity { NumberAnimation { duration: StickNotesBarStyle.colorAnimDurationMs } }

                        Rectangle {
                            objectName: "closedTabColorBar"
                            anchors.centerIn: parent
                            width: StickNotesBarStyle.closedTabBarWidth
                            height: StickNotesBarStyle.closedTabBarHeight
                            radius: StickNotesBarStyle.closedTabBarRadius
                            color: noteDrawerItem.noteAccentColor
                            opacity: StickNotesBarStyle.closedTabBarOpacity
                            Behavior on color { ColorAnimation { duration: StickNotesBarStyle.colorAnimDurationMs } }
                        }

                        property real pressSceneX: 0
                        property real pressSceneY: 0
                        property bool isDetaching: false

                        MouseArea {
                            id: closedTabMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor

                            onPressed: function(mouse) {
                                var pt = mapToItem(null, mouse.x, mouse.y)
                                closedTab.pressSceneX = pt.x
                                closedTab.pressSceneY = pt.y
                                closedTab.isDetaching = false
                            }

                            onPositionChanged: function(mouse) {
                                if (!pressed) return
                                var pt = mapToItem(null, mouse.x, mouse.y)
                                var dx = pt.x - closedTab.pressSceneX
                                var dy = pt.y - closedTab.pressSceneY

                                if (!closedTab.isDetaching && root.floatManager && (dx < StickNotesBarStyle.detachThresholdX || Math.hypot(dx, dy) > StickNotesBarStyle.detachThresholdHypot)) {
                                    closedTab.isDetaching = true
                                    noteDrawerItem.beginDetach(pt.x, pt.y)
                                } else if (closedTab.isDetaching) {
                                    noteDrawerItem.moveDetach(pt.x, pt.y)
                                }
                            }

                            onReleased: {
                                if (closedTab.isDetaching) {
                                    closedTab.isDetaching = false
                                    noteDrawerItem.finishDetach()
                                } else {
                                    root.creatingNew = false
                                    root.activeDrawerId = modelData.id
                                }
                            }
                        }
                    }

                    // ── B. OPEN DRAWER VIEW ──
                    Item {
                        id: openContent
                        anchors.fill: parent
                        anchors.margins: StickNotesBarStyle.openContentMargins
                        visible: (opacity > 0.01 && !closedTabMouse.pressed && !closedTab.isDetaching) || noteDrawerItem.isDetachingFromOpen
                        opacity: (noteDrawerItem.isOpen && noteDrop.width > StickNotesBarStyle.openShowThreshold) ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: StickNotesBarStyle.openFadeDurationMs } }

                        property bool addingItem: false
                        property int selectedNoteIndex: -1
                        property bool editingSelectedNote: false
                        property bool inlineEditingNote: false
                        property bool pickingColor: false
                        readonly property var currentNotesList: modelData.notes || []
                        readonly property bool isViewingNote: selectedNoteIndex >= 0 && selectedNoteIndex < currentNotesList.length
                        property real viewNoteProgress: isViewingNote ? 1.0 : 0.0
                        Behavior on viewNoteProgress {
                            NumberAnimation { duration: StickNotesBarStyle.drawerHeightDurationMs; easing.type: Easing.OutCubic }
                        }
                        property real pickingColorProgress: pickingColor ? 1.0 : 0.0
                        Behavior on pickingColorProgress {
                            NumberAnimation { duration: StickNotesBarStyle.drawerHeightDurationMs; easing.type: Easing.OutCubic }
                        }
                        readonly property real subviewProgress: Math.max(viewNoteProgress, pickingColorProgress)
                        property string cachedNoteText: ""
                        readonly property string selectedNoteText: isViewingNote ? currentNotesList[selectedNoteIndex] : cachedNoteText
                        onSelectedNoteTextChanged: {
                            if (isViewingNote) cachedNoteText = currentNotesList[selectedNoteIndex] || ""
                        }
                        readonly property bool hasActiveInput: addingItem || itemInput.activeFocus || inlineEditingNote || editingSelectedNote || fullNoteEditInput.activeFocus || pickingColor

                        function openFullNote(idx, startEditing) {
                            pickingColor = false
                            if (idx >= 0 && idx < currentNotesList.length) {
                                cachedNoteText = currentNotesList[idx] || ""
                            }
                            selectedNoteIndex = idx
                            editingSelectedNote = !!startEditing
                            if (editingSelectedNote) {
                                fullNoteEditInput.text = currentNotesList[idx] || ""
                                fullNoteEditInput.forceActiveFocus()
                            }
                        }

                        function selectNoteColor(colorKey) {
                            noteDrawerItem.localColorOverride = colorKey
                            if (root.sticknotes) {
                                root.sticknotes.setColor(modelData.id, colorKey)
                            }
                            pickingColor = false
                        }

                        function saveFullNoteEdit() {
                            if (!isViewingNote) return
                            var trimmed = fullNoteEditInput.text.trim()
                            if (trimmed && root.sticknotes) {
                                cachedNoteText = trimmed
                                root.sticknotes.editItem(modelData.id, selectedNoteIndex, trimmed)
                            }
                            editingSelectedNote = false
                        }

                        // ── B1. ALL-NOTES LIST VIEW ──
                        Column {
                            id: notesListColumn
                            anchors.fill: parent
                            spacing: StickNotesBarStyle.openColumnSpacing
                            visible: opacity > 0.01 || noteDrawerItem.isDetachingFromOpen
                            opacity: 1.0 - openContent.subviewProgress
                            scale: 1.0 - 0.06 * openContent.subviewProgress
                            transformOrigin: Item.Center

                            // Header: Note Name + Delete Note (Clicking icon or name opens Color Palette)
                            Item {
                                id: noteHeaderBar
                                width: parent.width
                                height: StickNotesBarStyle.noteHeaderHeight

                                // Drag handle across the empty header space to detach open stick note
                                MouseArea {
                                    id: headerBgDragMouse
                                    anchors.fill: parent
                                    anchors.rightMargin: StickNotesBarStyle.noteHeaderHeight
                                    cursorShape: Qt.SizeAllCursor
                                    property real pressSceneX: 0
                                    property real pressSceneY: 0
                                    property bool isDetachingHeader: false

                                    onPressed: function(mouse) {
                                        var pt = mapToItem(null, mouse.x, mouse.y)
                                        pressSceneX = pt.x
                                        pressSceneY = pt.y
                                        isDetachingHeader = false
                                    }

                                    onPositionChanged: function(mouse) {
                                        if (!pressed) return
                                        var pt = mapToItem(null, mouse.x, mouse.y)
                                        var dx = pt.x - pressSceneX
                                        var dy = pt.y - pressSceneY

                                        if (!isDetachingHeader && root.floatManager && (dx < StickNotesBarStyle.detachThresholdX || Math.hypot(dx, dy) > StickNotesBarStyle.detachThresholdHypot)) {
                                            isDetachingHeader = true
                                            noteDrawerItem.beginDetach(pt.x, pt.y)
                                        } else if (isDetachingHeader) {
                                            noteDrawerItem.moveDetach(pt.x, pt.y)
                                        }
                                    }

                                    onReleased: {
                                        if (isDetachingHeader) {
                                            isDetachingHeader = false
                                            noteDrawerItem.finishDetach()
                                        }
                                    }
                                }

                                Row {
                                    id: headerTitleRow
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: StickNotesBarStyle.noteHeaderSpacing

                                    Text {
                                        id: headerNoteIcon
                                        text: "󰠮"
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: StickNotesBarStyle.noteHeaderIconFontPx
                                        color: noteDrawerItem.noteAccentColor
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: StickNotesBarStyle.fastColorAnimDurationMs } }
                                    }

                                    Text {
                                        id: headerNoteTitle
                                        text: modelData.name || "Stick Note"
                                        font.pixelSize: StickNotesBarStyle.noteHeaderTitleFontPx
                                        font.weight: Font.Bold
                                        color: headerTitleMouse.containsMouse ? noteDrawerItem.noteAccentColor : root.fg
                                        elide: Text.ElideRight
                                        width: Math.min(implicitWidth, Math.max(0, noteHeaderBar.width - StickNotesBarStyle.noteHeaderHeight - headerNoteIcon.implicitWidth - StickNotesBarStyle.noteHeaderSpacing - StickNotesBarStyle.noteHeaderTitleRightReserve))
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: StickNotesBarStyle.fastColorAnimDurationMs } }
                                    }
                                }

                                // Click icon or title ONLY (tightly fitted to headerTitleRow) to open Color Palette; drag also detaches
                                MouseArea {
                                    id: headerTitleMouse
                                    objectName: "headerTitleMouse"
                                    anchors.left: headerTitleRow.left
                                    anchors.verticalCenter: headerTitleRow.verticalCenter
                                    width: headerTitleRow.width
                                    height: parent.height
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    property real pressSceneX: 0
                                    property real pressSceneY: 0
                                    property bool isDetachingHeader: false

                                    onPressed: function(mouse) {
                                        var pt = mapToItem(null, mouse.x, mouse.y)
                                        pressSceneX = pt.x
                                        pressSceneY = pt.y
                                        isDetachingHeader = false
                                    }

                                    onPositionChanged: function(mouse) {
                                        if (!pressed) return
                                        var pt = mapToItem(null, mouse.x, mouse.y)
                                        var dx = pt.x - pressSceneX
                                        var dy = pt.y - pressSceneY

                                        if (!isDetachingHeader && root.floatManager && (dx < StickNotesBarStyle.detachThresholdX || Math.hypot(dx, dy) > StickNotesBarStyle.detachThresholdHypot)) {
                                            isDetachingHeader = true
                                            noteDrawerItem.beginDetach(pt.x, pt.y)
                                        } else if (isDetachingHeader) {
                                            noteDrawerItem.moveDetach(pt.x, pt.y)
                                        }
                                    }

                                    onReleased: {
                                        if (isDetachingHeader) {
                                            isDetachingHeader = false
                                            noteDrawerItem.finishDetach()
                                        } else {
                                            openContent.selectedNoteIndex = -1
                                            openContent.editingSelectedNote = false
                                            openContent.pickingColor = true
                                        }
                                    }
                                }

                                // Delete stick note button
                                Rectangle {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: StickNotesBarStyle.deleteBtnSize
                                    height: StickNotesBarStyle.deleteBtnSize
                                    radius: StickNotesBarStyle.deleteBtnSize / 2
                                    color: delMouse.containsMouse ? StickNotesBarStyle.deleteHoverTint : StickNotesBarStyle.transparent

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰆴"
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: StickNotesBarStyle.deleteIconFontPx
                                        color: delMouse.containsMouse ? root.danger : root.dim
                                        Behavior on color { ColorAnimation { duration: StickNotesBarStyle.fastColorAnimDurationMs } }
                                    }

                                    MouseArea {
                                        id: delMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.sticknotes) root.sticknotes.deleteNote(modelData.id)
                                            root.activeDrawerId = ""
                                        }
                                    }
                                }
                            }

                            // ── "+" Action Button in the middle (also supports drag-out if user pulls from here) ──
                            Rectangle {
                                width: parent.width
                                height: StickNotesBarStyle.addBtnHeight
                                radius: StickNotesBarStyle.addBtnRadius
                                color: addMouse.containsMouse ? StickNotesBarStyle.addBtnHoverBg : StickNotesBarStyle.addBtnBg
                                border.width: 1
                                border.color: addMouse.containsMouse ? root.accent : StickNotesBarStyle.addBtnBorder
                                Behavior on color { ColorAnimation { duration: StickNotesBarStyle.fastColorAnimDurationMs } }
                                Behavior on border.color { ColorAnimation { duration: StickNotesBarStyle.fastColorAnimDurationMs } }

                                Row {
                                    anchors.centerIn: parent
                                    spacing: StickNotesBarStyle.noteHeaderSpacing
                                    Text {
                                        text: "+"
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: StickNotesBarStyle.addIconFontPx
                                        font.weight: Font.Bold
                                        color: root.accent
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: "Add note"
                                        font.pixelSize: StickNotesBarStyle.addLabelFontPx
                                        color: root.fg
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: addMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    property real pressSceneX: 0
                                    property real pressSceneY: 0
                                    property bool isDetachingAdd: false

                                    onPressed: function(mouse) {
                                        var pt = mapToItem(null, mouse.x, mouse.y)
                                        pressSceneX = pt.x
                                        pressSceneY = pt.y
                                        isDetachingAdd = false
                                    }

                                    onPositionChanged: function(mouse) {
                                        if (!pressed) return
                                        var pt = mapToItem(null, mouse.x, mouse.y)
                                        var dx = pt.x - pressSceneX
                                        var dy = pt.y - pressSceneY

                                        if (!isDetachingAdd && root.floatManager && (dx < StickNotesBarStyle.detachThresholdX || Math.hypot(dx, dy) > StickNotesBarStyle.detachThresholdHypot)) {
                                            isDetachingAdd = true
                                            noteDrawerItem.beginDetach(pt.x, pt.y)
                                        } else if (isDetachingAdd) {
                                            noteDrawerItem.moveDetach(pt.x, pt.y)
                                        }
                                    }

                                    onReleased: {
                                        if (isDetachingAdd) {
                                            isDetachingAdd = false
                                            noteDrawerItem.finishDetach()
                                        } else {
                                            openContent.addingItem = !openContent.addingItem
                                            if (openContent.addingItem) itemInput.forceActiveFocus()
                                        }
                                    }
                                }
                            }

                            // Inline input when "+" is clicked
                            Rectangle {
                                width: parent.width
                                height: openContent.addingItem ? StickNotesBarStyle.itemInputHeight : 0
                                visible: height > 0
                                radius: StickNotesBarStyle.itemInputRadius
                                color: StickNotesBarStyle.itemRowBg
                                border.width: 1
                                border.color: root.accent
                                clip: true

                                Behavior on height { NumberAnimation { duration: StickNotesBarStyle.openFadeDurationMs; easing.type: Easing.OutCubic } }

                                TextInput {
                                    id: itemInput
                                    anchors.fill: parent
                                    anchors.leftMargin: StickNotesBarStyle.itemInputMargin
                                    anchors.rightMargin: StickNotesBarStyle.itemInputMargin
                                    verticalAlignment: TextInput.AlignVCenter
                                    color: root.fg
                                    font.pixelSize: StickNotesBarStyle.itemInputFontPx
                                    clip: true

                                    Text {
                                        text: "Type note and press Enter..."
                                        color: root.dim
                                        font.pixelSize: StickNotesBarStyle.itemPlaceholderFontPx
                                        visible: !itemInput.text && !itemInput.activeFocus
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    onAccepted: {
                                        if (text.trim() && root.sticknotes) {
                                            root.sticknotes.addItem(modelData.id, text.trim())
                                            text = ""
                                        }
                                    }

                                    Keys.onEscapePressed: {
                                        openContent.addingItem = false
                                        text = ""
                                    }
                                }
                            }

                            // ── Scrollable Notes List with Swipe-to-Action & Click-to-View ──
                            ListView {
                                id: notesListView
                                width: parent.width
                                height: parent.height - y
                                clip: true
                                spacing: StickNotesBarStyle.notesListSpacing
                                boundsBehavior: Flickable.StopAtBounds

                                model: modelData.notes || []

                                delegate: Item {
                                    id: noteItemDelegate
                                    required property string modelData
                                    required property int index

                                    width: notesListView.width
                                    height: isEditing ? StickNotesBarStyle.rowEditingHeight : StickNotesBarStyle.rowDisplayHeight

                                    property bool isEditing: false

                                    // Background: Trash on left swipe, Edit pen on right swipe
                                    // Action buttons are ONLY visible in the revealed gap when pulled left or right
                                    Item {
                                        anchors.fill: parent

                                        // Edit action on the left (only revealed when pulled right: cardItem.x > 0)
                                        Rectangle {
                                            objectName: "swipeEditAction"
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: Math.min(StickNotesBarStyle.swipeRevealedOffset, Math.max(0, cardItem.x - 2))
                                            radius: StickNotesBarStyle.swipeActionRadius
                                            color: StickNotesBarStyle.editSwipeTint
                                            opacity: Math.min(1.0, Math.max(0.0, cardItem.x / StickNotesBarStyle.swipeCommitThreshold))
                                            visible: opacity > 0.01
                                            clip: true

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰏫"
                                                font.family: "Symbols Nerd Font"
                                                font.pixelSize: StickNotesBarStyle.swipeActionIconFontPx
                                                color: StickNotesBarStyle.editSwipeIcon
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: parent.visible
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    noteItemDelegate.isEditing = true
                                                    openContent.inlineEditingNote = true
                                                    cardItem.x = 0
                                                    editInput.forceActiveFocus()
                                                    editInput.cursorPosition = editInput.text.length
                                                }
                                            }
                                        }

                                        // Trash action on the right (only revealed when pulled left: cardItem.x < 0)
                                        Rectangle {
                                            objectName: "swipeDeleteAction"
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: Math.min(StickNotesBarStyle.swipeRevealedOffset, Math.max(0, -cardItem.x - 2))
                                            radius: StickNotesBarStyle.swipeActionRadius
                                            color: StickNotesBarStyle.deleteHoverTint
                                            opacity: Math.min(1.0, Math.max(0.0, -cardItem.x / StickNotesBarStyle.swipeCommitThreshold))
                                            visible: opacity > 0.01
                                            clip: true

                                            Text {
                                                anchors.centerIn: parent
                                                text: "󰆴"
                                                font.family: "Symbols Nerd Font"
                                                font.pixelSize: StickNotesBarStyle.swipeActionIconFontPx
                                                color: root.danger
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                enabled: parent.visible
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    if (root.sticknotes) {
                                                        root.sticknotes.deleteItem(noteDrawerItem.modelData.id, index)
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Foreground draggable & clickable card
                                    Rectangle {
                                        id: cardItem
                                        width: parent.width
                                        height: parent.height
                                        radius: StickNotesBarStyle.swipeActionRadius
                                        color: cardDragMouse.containsMouse ? StickNotesBarStyle.addBtnHoverBg : StickNotesBarStyle.inputBg
                                        border.width: 1
                                        border.color: (cardDragMouse.containsMouse || noteItemDelegate.isEditing) ? root.accent : StickNotesBarStyle.editInputBorder
                                        clip: true
                                        Behavior on color { ColorAnimation { duration: StickNotesBarStyle.fastColorAnimDurationMs } }
                                        Behavior on border.color { ColorAnimation { duration: StickNotesBarStyle.fastColorAnimDurationMs } }

                                        Behavior on x {
                                            enabled: !cardDragMouse.drag.active
                                            NumberAnimation { duration: StickNotesBarStyle.openFadeDurationMs; easing.type: Easing.OutCubic }
                                        }

                                        // Display mode: Single-line Note Preview (shows "..." when note has multiple lines)
                                        Text {
                                            objectName: "noteCardPreviewText"
                                            anchors.fill: parent
                                            anchors.leftMargin: StickNotesBarStyle.noteCardTextMargin
                                            anchors.rightMargin: StickNotesBarStyle.noteCardTextMargin
                                            verticalAlignment: Text.AlignVCenter
                                            text: {
                                                var raw = String(noteItemDelegate.modelData || "")
                                                var nl = raw.search(/\r?\n/)
                                                return nl >= 0 ? (raw.substring(0, nl) + "...") : raw
                                            }
                                            font.pixelSize: StickNotesBarStyle.itemInputFontPx
                                            color: root.fg
                                            maximumLineCount: 1
                                            elide: Text.ElideRight
                                            visible: !noteItemDelegate.isEditing
                                        }

                                        // Edit mode: Inline TextInput
                                        TextInput {
                                            id: editInput
                                            anchors.fill: parent
                                            anchors.leftMargin: StickNotesBarStyle.itemInputMargin
                                            anchors.rightMargin: StickNotesBarStyle.itemInputMargin
                                            verticalAlignment: TextInput.AlignVCenter
                                            text: noteItemDelegate.modelData
                                            font.pixelSize: StickNotesBarStyle.itemInputFontPx
                                            color: root.accent
                                            visible: noteItemDelegate.isEditing
                                            focus: noteItemDelegate.isEditing

                                            onVisibleChanged: {
                                                if (visible) {
                                                    forceActiveFocus()
                                                    cursorPosition = text.length
                                                }
                                            }

                                            onAccepted: {
                                                if (text.trim() && root.sticknotes) {
                                                    root.sticknotes.editItem(noteDrawerItem.modelData.id, noteItemDelegate.index, text.trim())
                                                }
                                                noteItemDelegate.isEditing = false
                                                openContent.inlineEditingNote = false
                                            }

                                            Keys.onEscapePressed: {
                                                noteItemDelegate.isEditing = false
                                                openContent.inlineEditingNote = false
                                                text = noteItemDelegate.modelData
                                            }
                                        }

                                        // Drag handler for Gmail-style swipe + click to open full note view
                                        MouseArea {
                                            id: cardDragMouse
                                            objectName: "cardDragMouse"
                                            anchors.fill: parent
                                            enabled: !noteItemDelegate.isEditing
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            drag.target: cardItem
                                            drag.axis: Drag.XAxis
                                            drag.minimumX: -StickNotesBarStyle.swipeMaxOffset
                                            drag.maximumX: StickNotesBarStyle.swipeMaxOffset

                                            onClicked: {
                                                if (Math.abs(cardItem.x) > 2) {
                                                    cardItem.x = 0
                                                } else {
                                                    openContent.openFullNote(noteItemDelegate.index, false)
                                                }
                                            }

                                            onReleased: {
                                                if (cardItem.x < -StickNotesBarStyle.swipeCommitThreshold) {
                                                    cardItem.x = -StickNotesBarStyle.swipeRevealedOffset
                                                } else if (cardItem.x > StickNotesBarStyle.swipeCommitThreshold) {
                                                    cardItem.x = StickNotesBarStyle.swipeRevealedOffset
                                                } else {
                                                    cardItem.x = 0
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // ── B2. FULL-NOTE INSPECTION VIEW (Takes entire Stick Note area when a note is clicked) ──
                        Column {
                            id: fullNoteView
                            objectName: "fullNoteView"
                            anchors.fill: parent
                            spacing: StickNotesBarStyle.openColumnSpacing
                            visible: opacity > 0.01
                            opacity: openContent.viewNoteProgress
                            scale: 0.88 + 0.12 * openContent.viewNoteProgress
                            transformOrigin: Item.Center

                            // Top bar: Back arrow on top-left, subtle Edit & Trash buttons on top-right
                            Item {
                                width: parent.width
                                height: StickNotesBarStyle.noteHeaderHeight

                                // Go back arrow button on top-left
                                Rectangle {
                                    id: fullNoteBackBtn
                                    objectName: "fullNoteBackBtn"
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: StickNotesBarStyle.deleteBtnSize
                                    height: StickNotesBarStyle.deleteBtnSize
                                    radius: StickNotesBarStyle.deleteBtnSize / 2
                                    color: backMouse.containsMouse ? StickNotesBarStyle.addBtnHoverBg : StickNotesBarStyle.transparent

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰁍"
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: StickNotesBarStyle.deleteIconFontPx
                                        color: backMouse.containsMouse ? root.accent : root.dim
                                        Behavior on color { ColorAnimation { duration: StickNotesBarStyle.fastColorAnimDurationMs } }
                                    }

                                    MouseArea {
                                        id: backMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            openContent.editingSelectedNote = false
                                            openContent.selectedNoteIndex = -1
                                        }
                                    }
                                }

                                Text {
                                    anchors.left: fullNoteBackBtn.right
                                    anchors.leftMargin: StickNotesBarStyle.noteHeaderSpacing
                                    anchors.right: fullNoteRightActions.left
                                    anchors.rightMargin: StickNotesBarStyle.noteHeaderSpacing
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.name || "Stick Note"
                                    font.pixelSize: StickNotesBarStyle.noteHeaderTitleFontPx
                                    font.weight: Font.Bold
                                    color: root.fg
                                    elide: Text.ElideRight
                                }

                                // Subtle Edit and Trash buttons on top-right (styled like the stick note trash button)
                                Row {
                                    id: fullNoteRightActions
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: StickNotesBarStyle.noteHeaderSpacing

                                    // Subtle Edit button
                                    Rectangle {
                                        id: fullNoteEditBtn
                                        objectName: "fullNoteEditBtn"
                                        width: StickNotesBarStyle.deleteBtnSize
                                        height: StickNotesBarStyle.deleteBtnSize
                                        radius: StickNotesBarStyle.deleteBtnSize / 2
                                        color: editNoteMouse.containsMouse ? StickNotesBarStyle.addBtnHoverBg : StickNotesBarStyle.transparent

                                        Text {
                                            anchors.centerIn: parent
                                            text: openContent.editingSelectedNote ? "󰄬" : "󰏫"
                                            font.family: "Symbols Nerd Font"
                                            font.pixelSize: StickNotesBarStyle.deleteIconFontPx
                                            color: (editNoteMouse.containsMouse || openContent.editingSelectedNote) ? root.accent : root.dim
                                            Behavior on color { ColorAnimation { duration: StickNotesBarStyle.fastColorAnimDurationMs } }
                                        }

                                        MouseArea {
                                            id: editNoteMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (openContent.editingSelectedNote) {
                                                    openContent.saveFullNoteEdit()
                                                } else {
                                                    fullNoteEditInput.text = openContent.selectedNoteText
                                                    openContent.editingSelectedNote = true
                                                    fullNoteEditInput.forceActiveFocus()
                                                }
                                            }
                                        }
                                    }

                                    // Subtle Trash button
                                    Rectangle {
                                        id: fullNoteDeleteBtn
                                        objectName: "fullNoteDeleteBtn"
                                        width: StickNotesBarStyle.deleteBtnSize
                                        height: StickNotesBarStyle.deleteBtnSize
                                        radius: StickNotesBarStyle.deleteBtnSize / 2
                                        color: delNoteMouse.containsMouse ? StickNotesBarStyle.deleteHoverTint : StickNotesBarStyle.transparent

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰆴"
                                            font.family: "Symbols Nerd Font"
                                            font.pixelSize: StickNotesBarStyle.deleteIconFontPx
                                            color: delNoteMouse.containsMouse ? root.danger : root.dim
                                            Behavior on color { ColorAnimation { duration: StickNotesBarStyle.fastColorAnimDurationMs } }
                                        }

                                        MouseArea {
                                            id: delNoteMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var idxToDelete = openContent.selectedNoteIndex
                                                openContent.editingSelectedNote = false
                                                openContent.selectedNoteIndex = -1
                                                if (idxToDelete >= 0 && root.sticknotes) {
                                                    root.sticknotes.deleteItem(modelData.id, idxToDelete)
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Full-area Note Content Container
                            Rectangle {
                                width: parent.width
                                height: parent.height - y
                                radius: StickNotesBarStyle.itemInputRadius
                                color: StickNotesBarStyle.inputBg
                                border.width: 1
                                border.color: openContent.editingSelectedNote ? root.accent : StickNotesBarStyle.editInputBorder
                                clip: true

                                // Read-only scrollable wrapped note text
                                Flickable {
                                    anchors.fill: parent
                                    anchors.margins: StickNotesBarStyle.noteCardTextMargin
                                    contentWidth: width
                                    contentHeight: fullNoteDisplayText.paintedHeight
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    visible: !openContent.editingSelectedNote

                                    Text {
                                        id: fullNoteDisplayText
                                        objectName: "fullNoteDisplayText"
                                        width: parent.width
                                        text: openContent.selectedNoteText
                                        font.pixelSize: StickNotesBarStyle.itemInputFontPx
                                        color: root.fg
                                        wrapMode: Text.Wrap
                                    }
                                }

                                // Editable wrapped note text when Edit button is clicked
                                Flickable {
                                    anchors.fill: parent
                                    anchors.margins: StickNotesBarStyle.noteCardTextMargin
                                    contentWidth: width
                                    contentHeight: fullNoteEditInput.paintedHeight
                                    clip: true
                                    boundsBehavior: Flickable.StopAtBounds
                                    visible: openContent.editingSelectedNote

                                    TextEdit {
                                        id: fullNoteEditInput
                                        objectName: "fullNoteEditInput"
                                        width: parent.width
                                        text: openContent.selectedNoteText
                                        font.pixelSize: StickNotesBarStyle.itemInputFontPx
                                        color: root.fg
                                        wrapMode: TextEdit.Wrap
                                        selectByMouse: true

                                        Keys.onPressed: function(event) {
                                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                                if (event.modifiers & Qt.ShiftModifier) {
                                                    event.accepted = false
                                                } else {
                                                    event.accepted = true
                                                    openContent.saveFullNoteEdit()
                                                }
                                            }
                                        }

                                        Keys.onEscapePressed: {
                                            openContent.editingSelectedNote = false
                                            text = openContent.selectedNoteText
                                        }
                                    }
                                }
                            }
                        }

                        // ── B3. COLOR PALETTE VIEW (Opens animated when clicking icon or name on top-left) ──
                        Column {
                            id: colorPaletteView
                            objectName: "colorPaletteView"
                            anchors.fill: parent
                            spacing: StickNotesBarStyle.openColumnSpacing
                            visible: opacity > 0.01
                            opacity: openContent.pickingColorProgress
                            scale: 0.88 + 0.12 * openContent.pickingColorProgress
                            transformOrigin: Item.Center

                            // Top bar: Back arrow on top-left + "Note Color" title
                            Item {
                                width: parent.width
                                height: StickNotesBarStyle.noteHeaderHeight

                                Rectangle {
                                    id: paletteBackBtn
                                    objectName: "paletteBackBtn"
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: StickNotesBarStyle.deleteBtnSize
                                    height: StickNotesBarStyle.deleteBtnSize
                                    radius: StickNotesBarStyle.deleteBtnSize / 2
                                    color: paletteBackMouse.containsMouse ? StickNotesBarStyle.addBtnHoverBg : StickNotesBarStyle.transparent

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰁍"
                                        font.family: "Symbols Nerd Font"
                                        font.pixelSize: StickNotesBarStyle.deleteIconFontPx
                                        color: paletteBackMouse.containsMouse ? noteDrawerItem.noteAccentColor : root.dim
                                        Behavior on color { ColorAnimation { duration: StickNotesBarStyle.fastColorAnimDurationMs } }
                                    }

                                    MouseArea {
                                        id: paletteBackMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            openContent.pickingColor = false
                                        }
                                    }
                                }

                                Text {
                                    anchors.left: paletteBackBtn.right
                                    anchors.leftMargin: StickNotesBarStyle.noteHeaderSpacing
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Choose Bar Color"
                                    font.pixelSize: StickNotesBarStyle.noteHeaderTitleFontPx
                                    font.weight: Font.Bold
                                    color: root.fg
                                }
                            }

                            // Palette Grid Container
                            Rectangle {
                                width: parent.width
                                height: parent.height - y
                                radius: StickNotesBarStyle.itemInputRadius
                                color: StickNotesBarStyle.inputBg
                                border.width: 1
                                border.color: StickNotesBarStyle.editInputBorder
                                clip: true

                                Grid {
                                    anchors.centerIn: parent
                                    columns: 4
                                    spacing: 14

                                    Repeater {
                                        model: root.colorPaletteModel

                                        delegate: Rectangle {
                                            id: colorSwatchItem
                                            objectName: "colorSwatch_" + modelData.key
                                            required property var modelData
                                            required property int index

                                            readonly property bool isSelected: noteDrawerItem.effectiveColorKey === modelData.key
                                                || (noteDrawerItem.effectiveColorKey === "" && index === 0)

                                            width: 44
                                            height: 44
                                            radius: 22
                                            color: swatchMouse.containsMouse ? StickNotesBarStyle.addBtnHoverBg : StickNotesBarStyle.itemRowBg
                                            border.width: (isSelected || swatchMouse.containsMouse) ? 2 : 1
                                            border.color: (isSelected || swatchMouse.containsMouse) ? modelData.color : StickNotesBarStyle.editInputBorder
                                            scale: swatchMouse.containsMouse ? 1.08 : 1.0
                                            Behavior on scale { NumberAnimation { duration: StickNotesBarStyle.fastColorAnimDurationMs; easing.type: Easing.OutCubic } }
                                            Behavior on border.color { ColorAnimation { duration: StickNotesBarStyle.fastColorAnimDurationMs } }

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 26
                                                height: 26
                                                radius: 13
                                                color: colorSwatchItem.modelData.color

                                                Text {
                                                    anchors.centerIn: parent
                                                    visible: colorSwatchItem.isSelected
                                                    text: "✓"
                                                    font.pixelSize: 13
                                                    font.weight: Font.Bold
                                                    color: StickNotesBarStyle.textBright
                                                }
                                            }

                                            MouseArea {
                                                id: swatchMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    openContent.selectNoteColor(colorSwatchItem.modelData.key)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
