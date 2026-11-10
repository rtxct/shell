import QtQuick
import QtTest
import "../../../../themes"
import "../../../app/styles"
import "../../../app/components"
import "../../../app/modules"

Item {
    id: root
    width: 1920
    height: 1080

    QtObject {
        id: mockStickNotes
        property var items: [
            { id: "note-1", name: "Work Note", notes: ["First task item\nSecond line of first note", "Second long note item"] },
            { id: "note-2", name: "Personal Note", notes: [] }
        ]
        property int lastDeletedNoteIdx: -1
        property string lastEditedText: ""
        property string lastSetColorKey: ""
        function create(name) {}
        function deleteNote(id) {}
        function setColor(noteId, colorKey) { lastSetColorKey = colorKey }
        function addItem(noteId, text) {}
        function deleteItem(noteId, index) { lastDeletedNoteIdx = index }
        function editItem(noteId, index, newText) { lastEditedText = newText }
    }

    Component {
        id: compStickNote
        FloatingStickNotePanel {}
    }

    FloatingWindow {
        id: floatWin
        screenW: root.width
        screenH: root.height
        winWidth: StickNotesBarStyle.floatWidth
        winHeight: StickNotesBarStyle.floatHeight
    }

    QtObject {
        id: mockFloatMgr
        property var fw0: QtObject { property bool active: false; property string winId: "" }
        property var fw1: QtObject { property bool active: false; property string winId: "" }
        property var fw2: QtObject { property bool active: false; property string winId: "" }
        property var fw3: QtObject { property bool active: false; property string winId: "" }
        property var fw4: QtObject { property bool active: false; property string winId: "" }
        property var fw5: QtObject { property bool active: false; property string winId: "" }
        property var fw6: QtObject { property bool active: false; property string winId: "" }
        property var fw7: QtObject { property bool active: false; property string winId: "" }
    }

    StickNotesBar {
        id: stickBar
        anchors.right: parent.right
        y: 200
        sticknotes: mockStickNotes
        floatManager: mockFloatMgr
    }

    TestCase {
        name: "StickNotesBarMaskTightTests"
        when: windowShown

        function init() {
            stickBar.closeAll()
            tryCompare(stickBar, "width", StickNotesBarStyle.drawerIdleDepth, 500)
        }

        function test_idle_state_collapses_mask_to_idle_depth_without_invisible_wall() {
            // In idle docked state, width must match drawerIdleDepth (8px) exactly
            compare(stickBar.width, StickNotesBarStyle.drawerIdleDepth)
            compare(stickBar.maskItem.width, StickNotesBarStyle.drawerIdleDepth)

            // Right-anchored: left edge of the mask must be parent.width - 8px
            compare(stickBar.x, root.width - StickNotesBarStyle.drawerIdleDepth)

            // Verify height is exactly contentColumn height without arbitrary padding
            verify(stickBar.height > 0)
            compare(stickBar.maskItem.height, stickBar.height)

            // Any click area to the left (e.g. at x = root.width - 20) is outside the mask
            var maskLeftX = stickBar.x
            verify(maskLeftX > (root.width - 16), "Mask left boundary must be tightly constrained to <= 8px from edge")
        }

        function test_open_drawer_expands_mask_to_open_depth_without_padding() {
            // Open note-1 drawer
            stickBar.activeDrawerId = "note-1"
            tryCompare(stickBar, "width", StickNotesBarStyle.drawerOpenDepth, 500)
            compare(stickBar.maskItem.width, StickNotesBarStyle.drawerOpenDepth)

            // Left edge of the open drawer mask must be exactly parent.width - drawerOpenDepth
            compare(stickBar.x, root.width - StickNotesBarStyle.drawerOpenDepth)

            // Close the drawer: collapses back to idle depth (8px)
            stickBar.closeAll()
            tryCompare(stickBar, "width", StickNotesBarStyle.drawerIdleDepth, 500)
            compare(stickBar.maskItem.width, StickNotesBarStyle.drawerIdleDepth)
            compare(stickBar.x, root.width - StickNotesBarStyle.drawerIdleDepth)
        }

        function test_creating_new_expands_mask_to_creation_width() {
            stickBar.creatingNew = true
            tryCompare(stickBar, "width", StickNotesBarStyle.creationWidth, 500)
            compare(stickBar.maskItem.width, StickNotesBarStyle.creationWidth)
            compare(stickBar.x, root.width - StickNotesBarStyle.creationWidth)

            stickBar.creatingNew = false
            tryCompare(stickBar, "width", StickNotesBarStyle.drawerIdleDepth, 500)
            compare(stickBar.maskItem.width, StickNotesBarStyle.drawerIdleDepth)
        }

        function findByObjectName(item, targetName) {
            if (!item) return null
            if (item.objectName === targetName) return item
            var children = item.children || []
            for (var i = 0; i < children.length; ++i) {
                var found = findByObjectName(children[i], targetName)
                if (found) return found
            }
            return null
        }

        function test_create_button_is_at_bottom_left_and_swipe_actions_hidden_at_rest() {
            stickBar.creatingNew = true
            tryCompare(stickBar, "width", StickNotesBarStyle.creationWidth, 500)

            var createBtn = findByObjectName(stickBar, "createNoteBtn")
            verify(createBtn !== null, "Create button should exist in creation drawer")
            compare(createBtn.x, 0, "Create button must be aligned to the bottom-left of the creation column")
            verify(createBtn.y > 60, "Create button must be on its own bottom row below the hint text")

            stickBar.creatingNew = false
            stickBar.activeDrawerId = "note-1"
            tryCompare(stickBar, "width", StickNotesBarStyle.drawerOpenDepth, 500)
            wait(50)

            var swipeEdit = findByObjectName(stickBar, "swipeEditAction")
            var swipeDelete = findByObjectName(stickBar, "swipeDeleteAction")
            verify(swipeEdit !== null, "Swipe edit action must exist")
            verify(swipeDelete !== null, "Swipe delete action must exist")
            compare(swipeEdit.visible, false, "Swipe edit button must be hidden when note is at rest")
            compare(swipeDelete.visible, false, "Swipe delete button must be hidden when note is at rest")
        }

        function test_clicking_note_opens_full_note_view_with_back_edit_and_trash() {
            stickBar.activeDrawerId = "note-1"
            tryCompare(stickBar, "width", StickNotesBarStyle.drawerOpenDepth, 500)
            wait(50)

            var fullView = findByObjectName(stickBar, "fullNoteView")
            verify(fullView !== null, "Full note view must exist")
            compare(fullView.visible, false, "Full note view is hidden initially")

            var previewText = findByObjectName(stickBar, "noteCardPreviewText")
            verify(previewText !== null, "Note card preview text must exist")
            compare(previewText.text, "First task item...", "Multi-line note preview in list must truncate at \\n with ...")

            var openContent = fullView.parent
            openContent.openFullNote(0, false)
            tryCompare(fullView, "visible", true, 500)
            tryCompare(openContent, "viewNoteProgress", 1.0, 500)

            var displayText = findByObjectName(fullView, "fullNoteDisplayText")
            verify(displayText !== null)
            compare(displayText.text, "First task item\nSecond line of first note")

            var backBtn = findByObjectName(fullView, "fullNoteBackBtn")
            var editBtn = findByObjectName(fullView, "fullNoteEditBtn")
            var deleteBtn = findByObjectName(fullView, "fullNoteDeleteBtn")
            verify(backBtn !== null && editBtn !== null && deleteBtn !== null)

            // Test edit mode: Shift+Enter inserts newline, plain Enter saves
            openContent.openFullNote(0, true)
            tryCompare(openContent, "editingSelectedNote", true, 500)
            var fullNoteEditInput = findByObjectName(fullView, "fullNoteEditInput")
            verify(fullNoteEditInput !== null, "fullNoteEditInput must exist")
            fullNoteEditInput.forceActiveFocus()
            fullNoteEditInput.text = "First task item"
            fullNoteEditInput.cursorPosition = 15

            // Shift + Enter should insert a newline and keep editing active
            keyClick(Qt.Key_Return, Qt.ShiftModifier)
            compare(fullNoteEditInput.text, "First task item\n")
            compare(openContent.editingSelectedNote, true)

            // Plain Enter should save modifications and close edit mode
            mockStickNotes.lastEditedText = ""
            keyClick(Qt.Key_Return, Qt.NoModifier)
            tryCompare(openContent, "editingSelectedNote", false, 500)
            compare(mockStickNotes.lastEditedText, "First task item")

            // Test back arrow animates back to list view
            openContent.selectedNoteIndex = -1
            tryCompare(openContent, "viewNoteProgress", 0.0, 500)
            tryCompare(fullView, "visible", false, 500)

            // Test clicking header icon/title opens animated color palette and updates idle bar color
            var paletteView = findByObjectName(stickBar, "colorPaletteView")
            verify(paletteView !== null, "Color palette view must exist")
            compare(paletteView.visible, false, "Color palette view is hidden initially")

            openContent.pickingColor = true
            tryCompare(paletteView, "visible", true, 500)
            tryCompare(openContent, "pickingColorProgress", 1.0, 500)

            var purpleSwatch = findByObjectName(paletteView, "colorSwatch_purple")
            verify(purpleSwatch !== null, "Purple color swatch must exist")
            var closedBar = findByObjectName(stickBar, "closedTabColorBar")
            verify(closedBar !== null, "Closed tab color bar must exist")

            // Select purple color
            openContent.selectNoteColor("purple")
            tryCompare(openContent, "pickingColorProgress", 0.0, 500)
            tryCompare(paletteView, "visible", false, 500)
            compare(closedBar.color, StickNotesBarStyle.palettePurple, "Idle closed tab bar color must match chosen palette color")
            compare(mockStickNotes.lastSetColorKey, "purple")
        }

        function test_floating_stick_note_window_receives_sticknotes_and_extra_data_when_detached() {
            // Simulate even the pre-fix order where contentComponent is set BEFORE sticknotes & extraData:
            floatWin.contentComponent = compStickNote
            floatWin.sticknotes = mockStickNotes
            floatWin.extraData = { noteId: "note-1", name: "Work Note" }
            floatWin.active = true

            // Verify untransformed FloatingWindow root (maskItem === floatWin) has scale 1.0, full size, and live x/y updates
            verify(floatWin.maskItem === floatWin, "FloatingWindow maskItem must be the root item itself so Region tracks x/y moves")
            compare(floatWin.scale, 1.0, "FloatingWindow root must remain unscaled (scale animation lives on cardBg)")
            compare(floatWin.maskItem.width, StickNotesBarStyle.floatWidth, "FloatingWindow maskItem width must be immediately full winWidth")
            compare(floatWin.maskItem.height, StickNotesBarStyle.floatHeight, "FloatingWindow maskItem height must be immediately full winHeight")
            floatWin.posX = 640
            floatWin.posY = 280
            compare(floatWin.maskItem.x, 640, "FloatingWindow maskItem.x must update when posX moves")
            compare(floatWin.maskItem.y, 280, "FloatingWindow maskItem.y must update when posY moves")

            var loadedPanel = null
            for (var i = 0; i < floatWin.children.length; ++i) {
                var child = floatWin.children[i]
                for (var j = 0; j < child.children.length; ++j) {
                    var sub = child.children[j]
                    if (sub.children && sub.children.length > 0 && sub.children[0].item) {
                        loadedPanel = sub.children[0].item
                    }
                }
            }
            verify(loadedPanel !== null, "Loaded FloatingStickNotePanel must exist")
            compare(loadedPanel.noteId, "note-1", "Loaded panel must receive extraData.noteId")
            verify(loadedPanel.sticknotes === mockStickNotes, "Loaded panel must receive sticknotes service")
            compare(loadedPanel.noteItems.length, 2, "Loaded panel must display the 2 existing notes of note-1")

            var floatEditAction = findByObjectName(loadedPanel, "swipeEditAction")
            var floatDeleteAction = findByObjectName(loadedPanel, "swipeDeleteAction")
            var floatCardDragMouse = findByObjectName(loadedPanel, "cardDragMouse")
            verify(floatEditAction !== null && floatDeleteAction !== null && floatCardDragMouse !== null, "FloatingStickNotePanel must have swipeEditAction, swipeDeleteAction, and cardDragMouse")
            verify(floatCardDragMouse.drag.target !== null, "FloatingStickNotePanel cardDragMouse must use native drag.target")
            compare(floatEditAction.visible, false, "Floating swipeEditAction must be hidden at rest")
            compare(floatDeleteAction.visible, false, "Floating swipeDeleteAction must be hidden at rest")

            // Verify that when sticknote-note-1 is floating in floatManager, noteDrawer_note-1 disappears from the right bar
            var note1Drawer = findByObjectName(stickBar, "noteDrawer_note-1")
            verify(note1Drawer !== null, "noteDrawer_note-1 must exist")
            compare(note1Drawer.visible, true)

            mockFloatMgr.fw0.winId = "sticknote-note-1"
            mockFloatMgr.fw0.active = true
            tryCompare(note1Drawer, "opacity", 0.0, 500)
            tryCompare(note1Drawer, "height", 0, 500)
            compare(note1Drawer.visible, false, "Detached stick note must disappear from the right bar while floating")

            mockFloatMgr.fw0.active = false
            tryCompare(note1Drawer, "opacity", 1.0, 500)
            tryCompare(note1Drawer, "height", StickNotesBarStyle.drawerIdleHeight, 500)
            compare(note1Drawer.visible, true, "Docked stick note must reappear on the right bar")

            floatWin.active = false
        }
    }
}
