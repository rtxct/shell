import QtQuick
import QtTest
import "../../../../themes"
import "../../../app/styles"
import "../../../app/components"

Item {
    width: 1920
    height: 1080

    FloatingWindow {
        id: floatWin
        winId: "float-audio"
        title: "Audio & Media"
        originSide: "bottom"
        posX: 400
        posY: 400
        winWidth: 380
        winHeight: 320
        screenW: 1920
        screenH: 1080
        active: true
    }

    SignalSpy {
        id: dockSpy
        target: floatWin
        signalName: "dockRequested"
    }

    SignalSpy {
        id: closeSpy
        target: floatWin
        signalName: "closeRequested"
    }

    TestCase {
        name: "FloatingWindowTests"
        when: windowShown

        function init() {
            floatWin.originSide = "bottom"
            floatWin.posX = 400
            floatWin.posY = 400
            floatWin.winWidth = 380
            floatWin.winHeight = 320
            floatWin.active = true
            dockSpy.clear()
            closeSpy.clear()
        }

        function test_check_dock_zone_all_four_edges() {
            var snap = floatWin.snapDistance

            // Left edge
            floatWin.originSide = "left"
            floatWin.posX = snap + 10
            compare(floatWin.checkDockZone(), false)
            floatWin.posX = snap - 5
            compare(floatWin.checkDockZone(), true)

            // Top edge
            floatWin.originSide = "top"
            floatWin.posY = snap + 10
            compare(floatWin.checkDockZone(), false)
            floatWin.posY = snap - 5
            compare(floatWin.checkDockZone(), true)

            // Bottom edge
            floatWin.originSide = "bottom"
            floatWin.posY = 1080 - floatWin.winHeight - snap - 10
            compare(floatWin.checkDockZone(), false)
            floatWin.posY = 1080 - floatWin.winHeight - snap + 5
            compare(floatWin.checkDockZone(), true)

            // Right edge
            floatWin.originSide = "right"
            floatWin.posX = 1920 - floatWin.winWidth - snap - 10
            compare(floatWin.checkDockZone(), false)
            floatWin.posX = 1920 - floatWin.winWidth - snap + 5
            compare(floatWin.checkDockZone(), true)
        }

        function test_dock_and_close_signals() {
            floatWin.dock()
            compare(dockSpy.count, 1)
            compare(dockSpy.signalArguments[0][0], "float-audio")

            floatWin.close()
            compare(closeSpy.count, 1)
            compare(closeSpy.signalArguments[0][0], "float-audio")
        }
    }
}
