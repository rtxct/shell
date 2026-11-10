import QtQuick
import QtTest
import "../../../../themes"
import "../../../app/styles"
import "../../../app/components"

Item {
    width: 800
    height: 600

    Drop {
        id: horizDrop
        width: 300
        height: 44
        slant: DropStyle.slant
        rad: DropStyle.radius
    }

    Drop {
        id: vertDrop
        vertical: true
        width: 60
        height: 240
        slant: 20
        rad: 10
    }

    Drop {
        id: bottomRightDrop
        fromBottom: true
        fromRight: true
        width: 220
        height: 40
    }

    Strip {
        id: topStrip
        barLen: 400
        thickness: StripStyle.thickness
    }

    Strip {
        id: leftStrip
        vertical: true
        barLen: 300
        thickness: StripStyle.thickness
    }

    TestCase {
        name: "DropAndStripTests"
        when: windowShown

        function test_horizontal_drop_geometry() {
            compare(horizDrop.vertical, false)
            compare(horizDrop.la, 300)
            compare(horizDrop.ld, 44)
            compare(horizDrop.sl, Math.min(DropStyle.slant, 149))
            compare(horizDrop.contentArea.clip, true)
            compare(horizDrop.contentArea.width, 300 - 2 * (horizDrop.sl + horizDrop.inset))
            compare(horizDrop.contentArea.height, 44 - horizDrop.tpe - horizDrop.bottomInset)
        }

        function test_vertical_drop_geometry() {
            compare(vertDrop.vertical, true)
            compare(vertDrop.la, 240)
            compare(vertDrop.ld, 60)
            compare(vertDrop.sl, 20)
            compare(vertDrop.tpe, 0)
            verify(vertDrop.hh > 0)
        }

        function test_bottom_right_drop_flags() {
            compare(bottomRightDrop.fromBottom, true)
            compare(bottomRightDrop.fromRight, true)
            compare(bottomRightDrop.la, 40)
            compare(bottomRightDrop.ld, 220)
        }

        function test_strip_dimensions_and_orientation() {
            compare(topStrip.width, 400)
            compare(topStrip.height, StripStyle.thickness)
            compare(leftStrip.width, StripStyle.thickness)
            compare(leftStrip.height, 300)
        }
    }
}
