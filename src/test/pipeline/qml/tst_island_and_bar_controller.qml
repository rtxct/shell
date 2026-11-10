import QtQuick
import QtTest
import "../../../../themes"
import "../../../app/styles"
import "../../../app/components"
import "../../../app/modules"

Item {
    id: scene
    width: 1000
    height: 700

    BarController {
        id: topCtl
        now: new Date(2026, 9, 17, 14, 30, 0)
    }

    BarController {
        id: realCtl
    }

    Component {
        id: dummyPanel
        PanelPlaceholder { text: "Test Panel" }
    }

    Island {
        id: testIsland
        anchors.fill: parent
        ctl: topCtl
        panelId: "middle"
        title: "Calendar"
        clickPanel: dummyPanel
        openDuration: 20
        closeDuration: 20
    }

    SideBar {
        id: leftWing
        anchors.fill: parent
        ctl: topCtl
        side: "left"
        travelDuration: 20
        openDuration: 20
        closeDuration: 20
    }

    Circle {
        id: circleOuter
        anchors.fill: parent
        ctl: topCtl
        vertical: true
        side: "up"
        slot: 0
        panelId: "circle-up-outer"
        title: "Outer"
        glyph: "A"
        panel: dummyPanel
        travelDuration: 20
    }

    TestCase {
        name: "IslandAndBarControllerTests"
        when: windowShown

        function init() {
            topCtl.finish()
            realCtl.finish()
            testIsland.hot = false
        }

        function test_bar_controller_module_state_machine() {
            compare(realCtl.phase, "closed")
            compare(realCtl.busy, false)

            // Direct island open (travels: false): closed -> expanding -> open -> collapsing -> closed
            realCtl.open({ id: "middle", host: "island", kind: "click", travels: false, title: "Clock" })
            compare(realCtl.phase, "expanding")
            compare(realCtl.busy, true)
            compare(realCtl.clickOpen, true)
            compare(realCtl.owner, "middle")

            realCtl.expandDone()
            compare(realCtl.phase, "open")

            realCtl.close()
            compare(realCtl.phase, "collapsing")

            realCtl.collapseDone()
            compare(realCtl.phase, "closed")
            compare(realCtl.owner, "")

            // Travelling circle open (travels: true): closed -> travelling -> expanding -> open -> collapsing -> returning -> closed
            realCtl.open({ id: "c1", host: "island", kind: "click", travels: true, bubbleLen: 26, bubbleDepth: 26 })
            compare(realCtl.phase, "travelling")
            realCtl.travelDone()
            compare(realCtl.phase, "expanding")
            realCtl.expandDone()
            compare(realCtl.phase, "open")
            realCtl.close()
            compare(realCtl.phase, "collapsing")
            realCtl.collapseDone()
            compare(realCtl.phase, "returning")
            realCtl.returnDone()
            compare(realCtl.phase, "closed")
        }

        function test_island_idle_hover_and_open_states() {
            compare(testIsland.baseMode, "idle")
            compare(testIsland.hoverFade, 0.0)
            compare(testIsland.hoverOpacity, 0.0)
            compare(testIsland.idleOpacity, 1.0)
            compare(testIsland.clamp01(-0.5), 0)
            compare(testIsland.clamp01(1.5), 1)

            testIsland.hot = true
            compare(testIsland.baseMode, "hover")
            tryCompare(testIsland, "hoverFade", 1.0, 400)
            compare(testIsland.hoverOpacity, 1.0)

            // Trigger open via controller
            topCtl.open({ id: "middle", host: "island", kind: "click", travels: false, title: "Calendar", panel: dummyPanel })
            compare(topCtl.phase, "expanding")
            tryCompare(topCtl, "phase", "open", 500)
            compare(testIsland.e, 1.0)
            compare(testIsland.hoverOpacity, 0.0)
            compare(testIsland.idleOpacity, 0.0)

            topCtl.close()
            tryCompare(topCtl, "phase", "closed", 500)
            compare(testIsland.e, 0.0)
        }

        function test_sidebar_and_circle_geometry_math() {
            compare(leftWing.isLeft, true)
            compare(leftWing.myId, "left-bar")
            compare(leftWing.trigger, "click")
            verify(leftWing.zoneW >= 40)

            // Circle two-phase trajectory math
            compare(circleOuter.offset, circleOuter.innerOffset + 2 * circleOuter.spacing)
            compare(circleOuter.pA, 0)
            compare(circleOuter.pD, 0)
            compare(circleOuter.easeInOut(0), 0)
            compare(circleOuter.easeInOut(0.5), 0.5)
            compare(circleOuter.easeInOut(1), 1)
        }
    }
}
