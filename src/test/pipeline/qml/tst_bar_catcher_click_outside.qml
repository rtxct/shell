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

    BarController {
        id: ctlTop
    }

    BarController {
        id: ctlLeft
    }

    property bool appMenuOpen: false
    readonly property bool anyClickOpen: ctlTop.clickOpen || ctlLeft.clickOpen || appMenuOpen

    function closeAll() {
        ctlTop.close()
        ctlLeft.close()
        appMenuOpen = false
    }

    MouseArea {
        id: catcher
        anchors.fill: parent
        enabled: root.anyClickOpen
        visible: root.anyClickOpen
        z: -1
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onPressed: root.closeAll()
    }

    readonly property var dynamicMaskItem: root.anyClickOpen ? catcher : null

    TestCase {
        name: "BarCatcherClickOutsideTests"
        when: windowShown

        function init() {
            ctlTop.finish()
            ctlLeft.finish()
            root.appMenuOpen = false
        }

        function test_catcher_disabled_and_mask_null_when_closed() {
            compare(root.anyClickOpen, false)
            compare(catcher.enabled, false)
            compare(catcher.visible, false)
            compare(root.dynamicMaskItem, null)
        }

        function test_catcher_activated_and_closes_on_click_outside() {
            // Open top bar island
            ctlTop.open({ id: "calendar", host: "island", kind: "click", travels: false, title: "Calendar" })
            compare(ctlTop.clickOpen, true)
            compare(root.anyClickOpen, true)
            compare(catcher.enabled, true)
            compare(catcher.visible, true)
            compare(catcher.width, 1920)
            compare(catcher.height, 1080)
            compare(root.dynamicMaskItem, catcher)

            // Click outside anywhere on catcher
            mouseClick(catcher, 100, 100)
            compare(ctlTop.phase, "collapsing")

            ctlTop.collapseDone()
            compare(ctlTop.clickOpen, false)
            compare(root.anyClickOpen, false)
            compare(catcher.enabled, false)
            compare(catcher.visible, false)
            compare(root.dynamicMaskItem, null)
        }

        function test_catcher_closes_app_menu() {
            root.appMenuOpen = true
            compare(root.anyClickOpen, true)
            compare(catcher.enabled, true)
            compare(root.dynamicMaskItem, catcher)

            mouseClick(catcher, 500, 500)
            compare(root.appMenuOpen, false)
            compare(root.anyClickOpen, false)
            compare(root.dynamicMaskItem, null)
        }
    }
}
