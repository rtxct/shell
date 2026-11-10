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
        id: ctlLeft
    }

    QtObject {
        id: mockFloatManager
        property string activeFloatId: ""
        signal windowDocked(string id)
        signal windowClosed(string id)

        function isFloating(id) {
            return activeFloatId !== "" && activeFloatId === id
        }

        function startDrag(cfg, x, y) {
            activeFloatId = cfg.id
        }

        function updateDrag(x, y) {}

        function endDrag() {}

        function closeWindow(id) {
            if (activeFloatId === id) {
                activeFloatId = ""
                windowClosed(id)
            }
        }
    }

    Component {
        id: dummyCirclePanel
        Item {}
    }

    Circle {
        id: testCircle
        ctl: ctlLeft
        stripH: 0
        vertical: true
        side: "up"
        slot: 0
        panelId: "up-outer"
        title: "Wi-Fi"
        glyph: "󰤨"
        panel: dummyCirclePanel
        floatManager: mockFloatManager
    }

    WorkspaceIsland {
        id: wsIsland
        anchors.fill: parent
        ctl: ctlLeft
        stripH: 0
        barLen: 620
        floatManager: mockFloatManager
    }

    TestCase {
        name: "LeftBarCircleFloatReturnTests"
        when: windowShown

        function init() {
            mockFloatManager.activeFloatId = ""
            wsIsland.detachedFromOpen = false
            wsIsland.savedOpenState = null
            wsIsland.isDetachingIdle = false
            wsIsland.isDetachingOpen = false
            ctlLeft.finish()
            tryCompare(testCircle, "travel", 0.0, 600)
            tryCompare(wsIsland, "e", 0.0, 600)
        }

        function test_open_circle_detached_to_float_returns_circle_home_and_resets_island() {
            // 1. Click circle to open its panel in WorkspaceIsland
            ctlLeft.open({
                id: "up-outer",
                host: "island",
                kind: "click",
                travels: true,
                title: "Wi-Fi",
                panel: dummyCirclePanel,
                bubbleLen: testCircle.diameter * 0.88,
                bubbleDepth: testCircle.diameter * 0.75
            })
            tryCompare(ctlLeft, "phase", "open", 1000)
            compare(testCircle.travel, 1.0, "Circle travelled to middle of left bar")
            compare(wsIsland.e, 1.0, "WorkspaceIsland expanded to 1.0")

            // 2. Detach open circle panel to floating window (same sequence as titleRow drag release)
            wsIsland.detachedFromOpen = true
            wsIsland.savedOpenState = {
                id: "up-outer",
                host: "island",
                kind: "click",
                travels: true,
                bubbleLen: testCircle.diameter * 0.88,
                bubbleDepth: testCircle.diameter * 0.75,
                title: "Wi-Fi",
                panel: dummyCirclePanel
            }
            mockFloatManager.activeFloatId = "up-outer"
            wsIsland.e = 0
            ctlLeft.finish()

            // Circle must NOT remain frozen at travel=1.0 in the middle of the left bar, and must vanish while floating!
            tryCompare(testCircle, "travel", 0.0, 800)
            tryCompare(testCircle, "opacity", 0.0, 500)
            compare(wsIsland.e, 0.0, "WorkspaceIsland returned to idle pill")
            compare(ctlLeft.phase, "closed")

            // 3. Dock/close floating circle window back to left bar -> circle fades back in at its slot (travel=0)
            mockFloatManager.activeFloatId = ""
            mockFloatManager.windowDocked("up-outer")
            compare(ctlLeft.phase, "closed", "Docking circle window keeps island closed and fades circle in")
            compare(wsIsland.e, 0.0, "WorkspaceIsland stays at idle")
            compare(testCircle.travel, 0.0, "Circle is at home slot")
            tryCompare(testCircle, "opacity", 1.0, 500)
        }

        function test_close_on_first_frame_of_expanding_does_not_freeze_circle() {
            ctlLeft.open({
                id: "up-outer",
                host: "island",
                kind: "click",
                travels: true,
                title: "Wi-Fi",
                panel: dummyCirclePanel,
                bubbleLen: testCircle.diameter * 0.88,
                bubbleDepth: testCircle.diameter * 0.75
            })
            tryCompare(ctlLeft, "phase", "expanding", 800)
            // Force e=0 and immediately close (simulating instant close at start of expanding)
            wsIsland.e = 0
            ctlLeft.close()
            tryCompare(ctlLeft, "phase", "closed", 1000)
            tryCompare(testCircle, "travel", 0.0, 800)
            compare(wsIsland.e, 0.0)
        }
    }
}
