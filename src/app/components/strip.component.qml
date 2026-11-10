// ============================================================================
// File: components/strip.component.qml
// Purpose: Thin background edge strip along the top or left monitor border built atop Drop.
// Public API:
//   - Properties: barStart, barLen, gapLen, splitGap, thickness, vertical, fill, slant, rad, flare
// Dependencies: QtQuick, "../styles"
// ============================================================================
import QtQuick
import "../styles"

// The thin strip along a monitor edge. Its ends curve into the edge.
// Horizontal = the top bar's strip, `vertical: true` = the left bar's strip.
// When `splitGap` is true, the center `gapLen` span is completely empty, leaving two independent
// left/right (or top/bottom) strip segments with rounded convex corners and concave edge flares.
Item {
    id: root

    // ── input from the parent ──
    property bool vertical: false
    property real barStart: 0         // where the strip starts along the edge
    property real barLen: StripStyle.defaultLength         // how long it is
    property real gapLen: 0           // length of the center island junction where the strip's bottom border should not draw
    property bool splitGap: false     // when true, splits the strip into two rounded segments separated by gapLen
    property real nearVisibility: 1.0
    property real farVisibility: 1.0

    // ── style ──
    property real thickness: StripStyle.thickness        // how much of the strip shows ("a pinch")
    property color fill: StripStyle.fill
    property real slant: StripStyle.slant
    property real rad: StripStyle.radius                 // convex corners
    property real flare: StripStyle.flare                // concave curve into the monitor edge
    readonly property real centerGap: gapLen

    x: vertical ? 0 : barStart
    y: vertical ? barStart : 0
    width: vertical ? thickness : barLen
    height: vertical ? barLen : thickness

    readonly property real segmentLen: Math.max(0, (barLen - gapLen) / 2)

    // Near (left/top) strip segment
    Drop {
        id: nearDrop
        vertical: root.vertical
        x: root.vertical ? 0 : (root.segmentLen * (1 - root.nearVisibility))
        y: root.vertical ? (root.segmentLen * (1 - root.nearVisibility)) : 0
        width: root.vertical ? root.thickness : (root.segmentLen * root.nearVisibility)
        height: root.vertical ? (root.segmentLen * root.nearVisibility) : root.thickness
        fill: root.fill
        tp: 0
        slant: root.slant
        rad: root.rad
        flare: root.flare
        roundFarEnd: root.splitGap
        opacity: root.nearVisibility
        visible: (root.vertical ? height : width) > 1 && opacity > 0.01
    }

    // Far (right/bottom) strip segment
    Drop {
        id: farDrop
        vertical: root.vertical
        x: root.vertical ? 0 : (root.barLen - root.segmentLen)
        y: root.vertical ? (root.barLen - root.segmentLen) : 0
        width: root.vertical ? root.thickness : (root.segmentLen * root.farVisibility)
        height: root.vertical ? (root.segmentLen * root.farVisibility) : root.thickness
        fill: root.fill
        tp: 0
        slant: root.slant
        rad: root.rad
        flare: root.flare
        roundNearEnd: root.splitGap
        opacity: root.farVisibility
        visible: (root.vertical ? height : width) > 1 && opacity > 0.01
    }
}
