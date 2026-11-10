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

    QtObject {
        id: mockFloatManager
        property bool isCalendarFloating: false
        signal windowDocked(string id)
        signal windowClosed(string id)
        function isFloating(id) {
            return id === "calendar" ? isCalendarFloating : false
        }
    }

    Strip {
        id: topStrip
        barStart: 600
        barLen: 720
        gapLen: (mockFloatManager && mockFloatManager.isCalendarFloating) ? middleBar.idleLen : middleBar.outerSpan
        splitGap: (mockFloatManager && mockFloatManager.isCalendarFloating) ? true : false
    }

    MiddleBar {
        id: middleBar
        anchors.fill: parent
        ctl: ctlTop
        stripH: topStrip.thickness
        barW: 720
        floatManager: mockFloatManager
    }

    readonly property var dynamicMiddleBarMaskItem: (mockFloatManager && mockFloatManager.isCalendarFloating && !middleBar.isActivelyDetaching) ? null : middleBar.maskItem

    TestCase {
        name: "MiddleBarFloatDetachTests"
        when: windowShown

        function init() {
            mockFloatManager.isCalendarFloating = false
            middleBar.isDetachingIdle = false
            middleBar.isDetachingOpen = false
            ctlTop.finish()
            tryCompare(middleBar, "opacity", 1.0, 500)
        }

        function test_idle_docked_state() {
            compare(mockFloatManager.isCalendarFloating, false)
            compare(middleBar.isFloating, false)
            compare(middleBar.opacity, 1.0)
            compare(middleBar.visible, true)
            compare(middleBar.integratedStripSpan, 720)
            verify(topStrip.gapLen > 0)
            compare(root.dynamicMiddleBarMaskItem, middleBar.maskItem)
        }

        function test_drag_detach_animates_middlebar_and_fulfills_strip_border() {
            // When calendar floats
            mockFloatManager.isCalendarFloating = true
            compare(middleBar.isFloating, true)
            compare(root.dynamicMiddleBarMaskItem, null)
            compare(topStrip.splitGap, true)

            // Animated properties settle to target values
            tryCompare(middleBar, "opacity", 0.0, 500)
            tryCompare(middleBar, "visible", false, 500)
            tryCompare(topStrip, "gapLen", middleBar.idleLen, 500)
            compare(topStrip.segmentLen, (720 - middleBar.idleLen) / 2)

            // When calendar docks/closes back
            mockFloatManager.isCalendarFloating = false
            compare(middleBar.isFloating, false)
            compare(topStrip.splitGap, false)
            compare(middleBar.integratedStripSpan, 720)
            tryCompare(middleBar, "opacity", 1.0, 500)
            tryCompare(middleBar, "visible", true, 500)
            verify(topStrip.gapLen > 0)
            compare(root.dynamicMiddleBarMaskItem, middleBar.maskItem)
            // Verify maskItem has zero visual Translate transform and covers the full idle depth
            compare(middleBar.maskItem.y, 0)
            compare(middleBar.maskItem.height, middleBar.idleDepth)
        }

        function test_open_calendar_returned_from_float_is_clean_and_closable() {
            // 1. Open calendar normally
            ctlTop.open({
                id: "calendar",
                host: "island",
                kind: "click",
                travels: false,
                title: "Calendar",
                panel: middleBar.clickPanel
            })
            tryCompare(ctlTop, "phase", "open", 500)
            compare(middleBar.e, 1.0)

            // 2. Simulate detaching while open (same sequence as titleRow drag threshold)
            middleBar.detachedFromOpen = true
            middleBar.savedOpenState = {
                id: "calendar",
                host: "island",
                kind: "click",
                travels: false,
                bubbleLen: 0,
                bubbleDepth: 0,
                title: "Calendar",
                panel: middleBar.clickPanel
            }
            middleBar.e = 1
            middleBar.hot = false
            middleBar.frozen = "idle"
            ctlTop.finish()
            mockFloatManager.isCalendarFloating = true
            tryCompare(middleBar, "opacity", 0.0, 500)

            // 3. Dock back to origin -> restores ctlTop to "open" so X button and click-outside work!
            mockFloatManager.isCalendarFloating = false
            mockFloatManager.windowDocked("calendar")
            tryCompare(middleBar, "opacity", 1.0, 500)
            compare(ctlTop.phase, "open")
            compare(ctlTop.clickOpen, true)
            compare(middleBar.e, 1.0)

            // 4. Close via ctlTop.close() (X button / click outside)
            ctlTop.close()
            tryCompare(ctlTop, "phase", "closed", 500)
            compare(middleBar.e, 0.0)
        }

        function test_detaching_flags_preserve_visibility_during_gesture() {
            mockFloatManager.isCalendarFloating = true
            tryCompare(middleBar, "opacity", 0.0, 500)
            tryCompare(middleBar, "visible", false, 500)

            // During active idle detachment gesture, visibility must be preserved so MouseArea grab is not canceled
            middleBar.isDetachingIdle = true
            compare(middleBar.visible, true)

            middleBar.isDetachingIdle = false
            compare(middleBar.visible, false)

            // During active open detachment gesture, visibility and maskItem must also be preserved
            middleBar.isDetachingOpen = true
            compare(middleBar.visible, true)
            compare(middleBar.isActivelyDetaching, true)
            compare(root.dynamicMiddleBarMaskItem, middleBar.maskItem)

            middleBar.isDetachingOpen = false
            compare(middleBar.visible, false)
            compare(middleBar.isActivelyDetaching, false)
            compare(root.dynamicMiddleBarMaskItem, null)
        }
    }
}
