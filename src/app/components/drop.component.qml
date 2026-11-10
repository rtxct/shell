// ============================================================================
// File: components/drop.component.qml
// Purpose: Procedural vector geometry engine rendering a continuous curved shape emerging from any screen edge with concave outward fillets and clipped inner content area.
// Public API:
//   - Properties: vertical, fromBottom, fromRight, fill, tp, slant, rad, flare, inset, bottomInset, contentOpacity, contentArea ...
// Dependencies: QtQuick, "../styles", QtQuick.Shapes
// ============================================================================
import QtQuick
import "../styles"
import QtQuick.Shapes

// The one shape every bar piece is made of: a "drop" hanging from a monitor edge.
//   - slanted (or straight) sides, rounded convex corners at the far end
//   - CONCAVE fillets where the sides meet the ceiling (the monitor edge when tp = 0,
//     the strip's underside when tp > 0), so components flow into each other
//   - children go into a clipped content area that always lies INSIDE the shape,
//     which is what removes "ghost" text while the shape animates.
//
// vertical: false -> hangs from the TOP edge  (width = along the edge, height = depth)
// vertical: true  -> hangs from the LEFT edge (height = along the edge, width = depth)
Item {
    id: root

    property bool vertical: false
    property bool fromBottom: false
    property bool fromRight: false
    property color fill: DropStyle.fill
    property real tp: 0              // ceiling depth (0 = touching the monitor edge)
    property real slant: DropStyle.slant           // inset of the far end on each side
    property real rad: DropStyle.radius            // convex radius at the far end
    property real flare: DropStyle.flare          // concave radius at the ceiling
    property real inset: DropStyle.inset          // content padding (along the edge)
    property real bottomInset: DropStyle.bottomInset     // content padding (far end)
    property real contentOpacity: 1  // fade children in/out with the animation
    property real centerGap: 0       // unstroked middle span along ld where a child island attaches
    property bool roundNearEnd: true // when false, the near end is a flush vertical join against an adjacent island
    property bool roundFarEnd: true  // when false, the far end is a flush vertical join against an adjacent island
    property real wingLen: 0         // length of integrated top strip wings extending outward from both sides
    property real nearWingLen: wingLen
    property real farWingLen: wingLen
    property real nearTpFactor: 1.0
    property real farTpFactor: 1.0
    property real wingFlare: StripStyle.flare // concave radius at the outer ends of integrated strip wings
    property real wingRad: StripStyle.radius  // convex radius at the outer ends of integrated strip wings
    property color strokeColor: DropStyle.strokeColor
    property real strokeWidth: DropStyle.strokeWidth
    property int strokeColorDuration: 140

    Behavior on strokeColor { ColorAnimation { duration: root.strokeColorDuration; easing.type: Easing.OutCubic } }

    default property alias content: area.data
    readonly property alias contentArea: area

    // la = extent along the edge, ld = extent away from the edge
    readonly property real la: (fromRight || vertical) ? height : width
    readonly property real ld: (fromRight || vertical) ? width : height

    readonly property real sl: Math.max(0, Math.min(slant, la / 2 - 1))
    readonly property real tpe: Math.max(0, Math.min(tp, ld))
    readonly property real tpeNear: tpe * Math.max(0, Math.min(1, nearTpFactor))
    readonly property real tpeFar: tpe * Math.max(0, Math.min(1, farTpFactor))
    readonly property real hh: Math.max(1, ld - tpe)
    readonly property real hhNear: Math.max(1, ld - tpeNear)
    readonly property real hhFar: Math.max(1, ld - tpeFar)
    readonly property real len: Math.sqrt(sl * sl + hh * hh)
    readonly property real lenNear: Math.sqrt(sl * sl + hhNear * hhNear)
    readonly property real lenFar: Math.sqrt(sl * sl + hhFar * hhFar)
    readonly property real t: Math.max(0, Math.min(flare * (len - sl) / hh, len * 0.6))
    readonly property real tNearVal: Math.max(0, Math.min(flare * (lenNear - sl) / hhNear, lenNear * 0.6))
    readonly property real tFarVal: Math.max(0, Math.min(flare * (lenFar - sl) / hhFar, lenFar * 0.6))
    readonly property real r: Math.max(0, Math.min(rad, hh / 2, (len - t) * 0.95, la / 2 - sl))
    readonly property real rNearVal: Math.max(0, Math.min(rad, hhNear / 2, (lenNear - tNearVal) * 0.95, la / 2 - sl))
    readonly property real rFarVal: Math.max(0, Math.min(rad, hhFar / 2, (lenFar - tFarVal) * 0.95, la / 2 - sl))
    readonly property real dx: r * sl / len
    readonly property real dy: r * hh / len
    readonly property real tx: t * sl / len
    readonly property real ty: t * hh / len
    readonly property real slNear: roundNearEnd ? sl : 0
    readonly property real slFar: roundFarEnd ? sl : 0
    readonly property real tNear: roundNearEnd ? tNearVal : 0
    readonly property real tFar: roundFarEnd ? tFarVal : 0
    readonly property real rNear: roundNearEnd ? rNearVal : 0
    readonly property real rFar: roundFarEnd ? rFarVal : 0
    readonly property real dxNear: roundNearEnd ? (rNearVal * sl / lenNear) : 0
    readonly property real dyNear: roundNearEnd ? (rNearVal * hhNear / lenNear) : 0
    readonly property real dxFar: roundFarEnd ? (rFarVal * sl / lenFar) : 0
    readonly property real dyFar: roundFarEnd ? (rFarVal * hhFar / lenFar) : 0
    readonly property real txNear: roundNearEnd ? (tNearVal * sl / lenNear) : 0
    readonly property real tyNear: roundNearEnd ? (tNearVal * hhNear / lenNear) : 0
    readonly property real txFar: roundFarEnd ? (tFarVal * sl / lenFar) : 0
    readonly property real tyFar: roundFarEnd ? (tFarVal * hhFar / lenFar) : 0
    readonly property bool hasNearWing: nearWingLen > 0.5 && tpeNear > 0.5
    readonly property bool hasFarWing: farWingLen > 0.5 && tpeFar > 0.5
    readonly property bool hasWings: hasNearWing || hasFarWing
    readonly property real wLenNear: hasNearWing ? nearWingLen : 0
    readonly property real wLenFar: hasFarWing ? farWingLen : 0
    readonly property real wHhNear: Math.max(1, tpeNear)
    readonly property real wHhFar: Math.max(1, tpeFar)
    readonly property real wTNear: hasNearWing ? Math.max(0, Math.min(wingFlare, wHhNear * 0.6)) : 0
    readonly property real wTFar: hasFarWing ? Math.max(0, Math.min(wingFlare, wHhFar * 0.6)) : 0
    readonly property real wRNear: hasNearWing ? Math.max(0, Math.min(wingRad, wHhNear / 2, (wHhNear - wTNear) * 0.95, wLenNear / 2)) : 0
    readonly property real wRFar: hasFarWing ? Math.max(0, Math.min(wingRad, wHhFar / 2, (wHhFar - wTFar) * 0.95, wLenFar / 2)) : 0
    readonly property real fp: Math.ceil(flare + Math.max(wLenNear, wLenFar) + wingFlare)
    readonly property real strokeNearCornerX: fp + slNear + rNear
    readonly property real strokeFarCornerX: fp + la - slFar - rFar
    readonly property real strokeMidStart: fp + (la - centerGap) / 2
    readonly property real strokeMidEnd: fp + (la + centerGap) / 2
    readonly property real wingNearStartX: fp - wLenNear - wTNear
    readonly property real wingNearCornerX: fp - wLenNear + wRNear
    readonly property real wingFarCornerX: fp + la + wLenFar - wRFar
    readonly property real wingFarEndX: fp + la + wLenFar + wTFar
    readonly property real fillAlphaRatio: DropStyle.fill.a > 0.001 ? (root.fill.a / DropStyle.fill.a) : root.fill.a
    readonly property real strokeAlphaRatio: DropStyle.strokeColor.a > 0.001 ? (root.strokeColor.a / DropStyle.strokeColor.a) : root.strokeColor.a
    readonly property real shapeOpacity: Math.max(0.0, Math.min(1.0, Math.max(fillAlphaRatio, strokeAlphaRatio)))

    // the shape is always drawn "hanging from the top"; for vertical it is rotated onto the left edge; for fromRight onto right edge
    Item {
        id: frame
        width: root.la
        height: root.ld
        x: root.fromRight ? root.width : 0
        y: root.fromBottom ? root.height : (root.vertical ? root.height : 0)
        rotation: root.fromRight ? 90 : (root.vertical ? -90 : 0)
        transformOrigin: Item.TopLeft
        transform: root.fromBottom ? bottomFlip : null

        Scale {
            id: bottomFlip
            yScale: -1
            origin.y: 0
        }

        Shape {
            x: -root.fp
            width: root.la + 2 * root.fp
            height: root.ld
            opacity: root.shapeOpacity
            visible: root.width > 1 && root.height > 1 && opacity > 0.001
            layer.enabled: true
            layer.samples: 4

            // 1. Filled interior polygon (no stroke along the screen edge or under a parent strip)
            ShapePath {
                fillColor: root.fill.a > 0.001 ? root.fill : DropStyle.primaryFill
                strokeColor: DropStyle.fillStrokeColor
                strokeWidth: 0
                startX: root.hasNearWing ? root.wingNearStartX : (root.fp - root.tNear)
                startY: 0

                PathLine { x: root.hasFarWing ? root.wingFarEndX : (root.fp + root.la + root.tFar); y: 0 }
                // Far wing outer fillet & corner (collapses to (fp + la + tFar, tpeFar) when hasFarWing is false)
                PathQuad {
                    x: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.fp + root.la + root.tFar)
                    y: root.hasFarWing ? root.wTFar : root.tpeFar
                    controlX: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.fp + root.la + root.tFar)
                    controlY: 0
                }
                PathLine {
                    x: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.fp + root.la + root.tFar)
                    y: root.hasFarWing ? (root.tpeFar - root.wRFar) : root.tpeFar
                }
                PathQuad {
                    x: root.hasFarWing ? root.wingFarCornerX : (root.fp + root.la + root.tFar)
                    y: root.tpeFar
                    controlX: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.fp + root.la + root.tFar)
                    controlY: root.tpeFar
                }
                PathLine { x: root.fp + root.la + root.tFar; y: root.tpeFar }
                // concave fillet, far side
                PathQuad {
                    x: root.fp + root.la - root.txFar; y: root.tpeFar + root.tyFar
                    controlX: root.fp + root.la; controlY: root.tpeFar
                }
                PathLine { x: root.fp + root.la - root.slFar + root.dxFar; y: root.ld - root.dyFar }
                // convex corner, far side
                PathQuad {
                    x: root.strokeFarCornerX; y: root.ld
                    controlX: root.fp + root.la - root.slFar; controlY: root.ld
                }
                PathLine { x: root.strokeNearCornerX; y: root.ld }
                // convex corner, near side
                PathQuad {
                    x: root.fp + root.slNear - root.dxNear; y: root.ld - root.dyNear
                    controlX: root.fp + root.slNear; controlY: root.ld
                }
                PathLine { x: root.fp + root.txNear; y: root.tpeNear + root.tyNear }
                // concave fillet, near side
                PathQuad {
                    x: root.fp - root.tNear; y: root.tpeNear
                    controlX: root.fp; controlY: root.tpeNear
                }
                // Near wing outer corner & fillet
                PathLine {
                    x: root.hasNearWing ? root.wingNearCornerX : (root.fp - root.tNear)
                    y: root.tpeNear
                }
                PathQuad {
                    x: root.hasNearWing ? (root.fp - root.wLenNear) : (root.fp - root.tNear)
                    y: root.hasNearWing ? (root.tpeNear - root.wRNear) : root.tpeNear
                    controlX: root.hasNearWing ? (root.fp - root.wLenNear) : (root.fp - root.tNear)
                    controlY: root.tpeNear
                }
                PathLine {
                    x: root.hasNearWing ? (root.fp - root.wLenNear) : (root.fp - root.tNear)
                    y: root.hasNearWing ? root.wTNear : root.tpeNear
                }
                PathQuad {
                    x: root.hasNearWing ? root.wingNearStartX : (root.fp - root.tNear)
                    y: 0
                    controlX: root.hasNearWing ? (root.fp - root.wLenNear) : (root.fp - root.tNear)
                    controlY: 0
                }
            }

            // 2. Liquid Glass multi-stop refractive sheen & caustic edge gradient overlay
            ShapePath {
                strokeColor: DropStyle.fillStrokeColor
                strokeWidth: 0
                fillGradient: LinearGradient {
                    x1: root.fp
                    y1: 0
                    x2: root.fp + root.la * 0.25
                    y2: root.ld
                    GradientStop { position: 0.0; color: DropStyle.glassSheenTop }
                    GradientStop { position: 0.32; color: DropStyle.glassSheenMid }
                    GradientStop { position: 0.68; color: DropStyle.glassSheenCore }
                    GradientStop { position: 1.0; color: DropStyle.glassSheenBottom }
                }
                startX: root.hasNearWing ? root.wingNearStartX : (root.fp - root.tNear)
                startY: 0

                PathLine { x: root.hasFarWing ? root.wingFarEndX : (root.fp + root.la + root.tFar); y: 0 }
                PathQuad {
                    x: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.fp + root.la + root.tFar)
                    y: root.hasFarWing ? root.wTFar : root.tpeFar
                    controlX: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.fp + root.la + root.tFar)
                    controlY: 0
                }
                PathLine {
                    x: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.fp + root.la + root.tFar)
                    y: root.hasFarWing ? (root.tpeFar - root.wRFar) : root.tpeFar
                }
                PathQuad {
                    x: root.hasFarWing ? root.wingFarCornerX : (root.fp + root.la + root.tFar)
                    y: root.tpeFar
                    controlX: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.fp + root.la + root.tFar)
                    controlY: root.tpeFar
                }
                PathLine { x: root.fp + root.la + root.tFar; y: root.tpeFar }
                PathQuad {
                    x: root.fp + root.la - root.txFar; y: root.tpeFar + root.tyFar
                    controlX: root.fp + root.la; controlY: root.tpeFar
                }
                PathLine { x: root.fp + root.la - root.slFar + root.dxFar; y: root.ld - root.dyFar }
                PathQuad {
                    x: root.strokeFarCornerX; y: root.ld
                    controlX: root.fp + root.la - root.slFar; controlY: root.ld
                }
                PathLine { x: root.strokeNearCornerX; y: root.ld }
                PathQuad {
                    x: root.fp + root.slNear - root.dxNear; y: root.ld - root.dyNear
                    controlX: root.fp + root.slNear; controlY: root.ld
                }
                PathLine { x: root.fp + root.txNear; y: root.tpeNear + root.tyNear }
                PathQuad {
                    x: root.fp - root.tNear; y: root.tpeNear
                    controlX: root.fp; controlY: root.tpeNear
                }
                PathLine {
                    x: root.hasNearWing ? root.wingNearCornerX : (root.fp - root.tNear)
                    y: root.tpeNear
                }
                PathQuad {
                    x: root.hasNearWing ? (root.fp - root.wLenNear) : (root.fp - root.tNear)
                    y: root.hasNearWing ? (root.tpeNear - root.wRNear) : root.tpeNear
                    controlX: root.hasNearWing ? (root.fp - root.wLenNear) : (root.fp - root.tNear)
                    controlY: root.tpeNear
                }
                PathLine {
                    x: root.hasNearWing ? (root.fp - root.wLenNear) : (root.fp - root.tNear)
                    y: root.hasNearWing ? root.wTNear : root.tpeNear
                }
                PathQuad {
                    x: root.hasNearWing ? root.wingNearStartX : (root.fp - root.tNear)
                    y: 0
                    controlX: root.hasNearWing ? (root.fp - root.wLenNear) : (root.fp - root.tNear)
                    controlY: 0
                }
            }

            // 3. 3D inner refractive bevel glow along exposed glass contour
            ShapePath {
                fillColor: DropStyle.fillStrokeColor
                strokeColor: DropStyle.glassInnerBevel
                strokeWidth: Math.min(DropStyle.bevelStrokeWidth, root.hh * 0.5)
                startX: root.hasNearWing ? root.wingNearStartX : (root.roundNearEnd ? (root.fp - root.tNear) : root.strokeNearCornerX)
                startY: root.hasNearWing ? 0 : (root.roundNearEnd ? root.tpeNear : root.ld)

                PathQuad {
                    x: root.hasNearWing ? (root.fp - root.wLenNear) : (root.roundNearEnd ? (root.fp - root.tNear) : root.strokeNearCornerX)
                    y: root.hasNearWing ? root.wTNear : (root.roundNearEnd ? root.tpeNear : root.ld)
                    controlX: root.hasNearWing ? (root.fp - root.wLenNear) : (root.roundNearEnd ? (root.fp - root.tNear) : root.strokeNearCornerX)
                    controlY: root.hasNearWing ? 0 : (root.roundNearEnd ? root.tpeNear : root.ld)
                }
                PathLine {
                    x: root.hasNearWing ? (root.fp - root.wLenNear) : (root.roundNearEnd ? (root.fp - root.tNear) : root.strokeNearCornerX)
                    y: root.hasNearWing ? (root.tpeNear - root.wRNear) : (root.roundNearEnd ? root.tpeNear : root.ld)
                }
                PathQuad {
                    x: root.hasNearWing ? root.wingNearCornerX : (root.roundNearEnd ? (root.fp - root.tNear) : root.strokeNearCornerX)
                    y: root.hasNearWing ? root.tpeNear : (root.roundNearEnd ? root.tpeNear : root.ld)
                    controlX: root.hasNearWing ? (root.fp - root.wLenNear) : (root.roundNearEnd ? (root.fp - root.tNear) : root.strokeNearCornerX)
                    controlY: root.hasNearWing ? root.tpeNear : (root.roundNearEnd ? root.tpeNear : root.ld)
                }
                PathLine {
                    x: root.roundNearEnd ? (root.fp - root.tNear) : root.strokeNearCornerX
                    y: root.roundNearEnd ? root.tpeNear : root.ld
                }
                PathQuad {
                    x: root.roundNearEnd ? (root.fp + root.txNear) : root.strokeNearCornerX
                    y: root.roundNearEnd ? (root.tpeNear + root.tyNear) : root.ld
                    controlX: root.roundNearEnd ? root.fp : root.strokeNearCornerX
                    controlY: root.roundNearEnd ? root.tpeNear : root.ld
                }
                PathLine {
                    x: root.roundNearEnd ? (root.fp + root.slNear - root.dxNear) : root.strokeNearCornerX
                    y: root.roundNearEnd ? (root.ld - root.dyNear) : root.ld
                }
                PathQuad {
                    x: root.strokeNearCornerX; y: root.ld
                    controlX: root.fp + root.slNear; controlY: root.ld
                }
                PathLine {
                    x: root.centerGap > 0 ? Math.max(root.strokeNearCornerX, root.strokeMidStart) : root.strokeFarCornerX
                    y: root.ld
                }
                PathMove {
                    x: root.centerGap > 0 ? Math.min(root.strokeFarCornerX, root.strokeMidEnd) : root.strokeFarCornerX
                    y: root.ld
                }
                PathLine {
                    x: root.strokeFarCornerX
                    y: root.ld
                }
                PathQuad {
                    x: root.roundFarEnd ? (root.fp + root.la - root.slFar + root.dxFar) : root.strokeFarCornerX
                    y: root.roundFarEnd ? (root.ld - root.dyFar) : root.ld
                    controlX: root.roundFarEnd ? (root.fp + root.la - root.slFar) : root.strokeFarCornerX
                    controlY: root.ld
                }
                PathLine {
                    x: root.roundFarEnd ? (root.fp + root.la - root.txFar) : root.strokeFarCornerX
                    y: root.roundFarEnd ? (root.tpeFar + root.tyFar) : root.ld
                }
                PathQuad {
                    x: root.roundFarEnd ? (root.fp + root.la + root.tFar) : root.strokeFarCornerX
                    y: root.roundFarEnd ? root.tpeFar : root.ld
                    controlX: root.roundFarEnd ? (root.fp + root.la) : root.strokeFarCornerX
                    controlY: root.roundFarEnd ? root.tpeFar : root.ld
                }
                PathLine {
                    x: root.hasFarWing ? root.wingFarCornerX : (root.roundFarEnd ? (root.fp + root.la + root.tFar) : root.strokeFarCornerX)
                    y: root.hasFarWing ? root.tpeFar : (root.roundFarEnd ? root.tpeFar : root.ld)
                }
                PathQuad {
                    x: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.roundFarEnd ? (root.fp + root.la + root.tFar) : root.strokeFarCornerX)
                    y: root.hasFarWing ? (root.tpeFar - root.wRFar) : (root.roundFarEnd ? root.tpeFar : root.ld)
                    controlX: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.roundFarEnd ? (root.fp + root.la + root.tFar) : root.strokeFarCornerX)
                    controlY: root.hasFarWing ? root.tpeFar : (root.roundFarEnd ? root.tpeFar : root.ld)
                }
                PathLine {
                    x: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.roundFarEnd ? (root.fp + root.la + root.tFar) : root.strokeFarCornerX)
                    y: root.hasFarWing ? root.wTFar : (root.roundFarEnd ? root.tpeFar : root.ld)
                }
                PathQuad {
                    x: root.hasFarWing ? root.wingFarEndX : (root.roundFarEnd ? (root.fp + root.la + root.tFar) : root.strokeFarCornerX)
                    y: root.hasFarWing ? 0 : (root.roundFarEnd ? root.tpeFar : root.ld)
                    controlX: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.roundFarEnd ? (root.fp + root.la + root.tFar) : root.strokeFarCornerX)
                    controlY: root.hasFarWing ? 0 : (root.roundFarEnd ? root.tpeFar : root.ld)
                }
            }

            // 4. Outer exposed specular border (never strokes y=0 screen edge, vertical walls inside tp, or centerGap seam)
            ShapePath {
                fillColor: DropStyle.fillStrokeColor
                strokeColor: root.strokeColor
                strokeWidth: root.strokeWidth
                startX: root.hasNearWing ? root.wingNearStartX : (root.roundNearEnd ? (root.fp - root.tNear) : root.strokeNearCornerX)
                startY: root.hasNearWing ? 0 : (root.roundNearEnd ? root.tpeNear : root.ld)

                PathQuad {
                    x: root.hasNearWing ? (root.fp - root.wLenNear) : (root.roundNearEnd ? (root.fp - root.tNear) : root.strokeNearCornerX)
                    y: root.hasNearWing ? root.wTNear : (root.roundNearEnd ? root.tpeNear : root.ld)
                    controlX: root.hasNearWing ? (root.fp - root.wLenNear) : (root.roundNearEnd ? (root.fp - root.tNear) : root.strokeNearCornerX)
                    controlY: root.hasNearWing ? 0 : (root.roundNearEnd ? root.tpeNear : root.ld)
                }
                PathLine {
                    x: root.hasNearWing ? (root.fp - root.wLenNear) : (root.roundNearEnd ? (root.fp - root.tNear) : root.strokeNearCornerX)
                    y: root.hasNearWing ? (root.tpeNear - root.wRNear) : (root.roundNearEnd ? root.tpeNear : root.ld)
                }
                PathQuad {
                    x: root.hasNearWing ? root.wingNearCornerX : (root.roundNearEnd ? (root.fp - root.tNear) : root.strokeNearCornerX)
                    y: root.hasNearWing ? root.tpeNear : (root.roundNearEnd ? root.tpeNear : root.ld)
                    controlX: root.hasNearWing ? (root.fp - root.wLenNear) : (root.roundNearEnd ? (root.fp - root.tNear) : root.strokeNearCornerX)
                    controlY: root.hasNearWing ? root.tpeNear : (root.roundNearEnd ? root.tpeNear : root.ld)
                }
                PathLine {
                    x: root.roundNearEnd ? (root.fp - root.tNear) : root.strokeNearCornerX
                    y: root.roundNearEnd ? root.tpeNear : root.ld
                }
                // concave fillet, near side
                PathQuad {
                    x: root.roundNearEnd ? (root.fp + root.txNear) : root.strokeNearCornerX
                    y: root.roundNearEnd ? (root.tpeNear + root.tyNear) : root.ld
                    controlX: root.roundNearEnd ? root.fp : root.strokeNearCornerX
                    controlY: root.roundNearEnd ? root.tpeNear : root.ld
                }
                PathLine {
                    x: root.roundNearEnd ? (root.fp + root.slNear - root.dxNear) : root.strokeNearCornerX
                    y: root.roundNearEnd ? (root.ld - root.dyNear) : root.ld
                }
                // convex corner, near side
                PathQuad {
                    x: root.strokeNearCornerX; y: root.ld
                    controlX: root.fp + root.slNear; controlY: root.ld
                }
                PathLine {
                    x: root.centerGap > 0 ? Math.max(root.strokeNearCornerX, root.strokeMidStart) : root.strokeFarCornerX
                    y: root.ld
                }
                PathMove {
                    x: root.centerGap > 0 ? Math.min(root.strokeFarCornerX, root.strokeMidEnd) : root.strokeFarCornerX
                    y: root.ld
                }
                PathLine {
                    x: root.strokeFarCornerX
                    y: root.ld
                }
                // convex corner, far side
                PathQuad {
                    x: root.roundFarEnd ? (root.fp + root.la - root.slFar + root.dxFar) : root.strokeFarCornerX
                    y: root.roundFarEnd ? (root.ld - root.dyFar) : root.ld
                    controlX: root.roundFarEnd ? (root.fp + root.la - root.slFar) : root.strokeFarCornerX
                    controlY: root.ld
                }
                PathLine {
                    x: root.roundFarEnd ? (root.fp + root.la - root.txFar) : root.strokeFarCornerX
                    y: root.roundFarEnd ? (root.tpeFar + root.tyFar) : root.ld
                }
                // concave fillet, far side
                PathQuad {
                    x: root.roundFarEnd ? (root.fp + root.la + root.tFar) : root.strokeFarCornerX
                    y: root.roundFarEnd ? root.tpeFar : root.ld
                    controlX: root.roundFarEnd ? (root.fp + root.la) : root.strokeFarCornerX
                    controlY: root.roundFarEnd ? root.tpeFar : root.ld
                }
                PathLine {
                    x: root.hasFarWing ? root.wingFarCornerX : (root.roundFarEnd ? (root.fp + root.la + root.tFar) : root.strokeFarCornerX)
                    y: root.hasFarWing ? root.tpeFar : (root.roundFarEnd ? root.tpeFar : root.ld)
                }
                PathQuad {
                    x: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.roundFarEnd ? (root.fp + root.la + root.tFar) : root.strokeFarCornerX)
                    y: root.hasFarWing ? (root.tpeFar - root.wRFar) : (root.roundFarEnd ? root.tpeFar : root.ld)
                    controlX: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.roundFarEnd ? (root.fp + root.la + root.tFar) : root.strokeFarCornerX)
                    controlY: root.hasFarWing ? root.tpeFar : (root.roundFarEnd ? root.tpeFar : root.ld)
                }
                PathLine {
                    x: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.roundFarEnd ? (root.fp + root.la + root.tFar) : root.strokeFarCornerX)
                    y: root.hasFarWing ? root.wTFar : (root.roundFarEnd ? root.tpeFar : root.ld)
                }
                PathQuad {
                    x: root.hasFarWing ? root.wingFarEndX : (root.roundFarEnd ? (root.fp + root.la + root.tFar) : root.strokeFarCornerX)
                    y: root.hasFarWing ? 0 : (root.roundFarEnd ? root.tpeFar : root.ld)
                    controlX: root.hasFarWing ? (root.fp + root.la + root.wLenFar) : (root.roundFarEnd ? (root.fp + root.la + root.tFar) : root.strokeFarCornerX)
                    controlY: root.hasFarWing ? 0 : (root.roundFarEnd ? root.tpeFar : root.ld)
                }
            }
        }
    }

    Item {
        id: area
        clip: true
        opacity: root.contentOpacity
        x: root.fromRight ? root.bottomInset : (root.vertical ? root.tpe : root.sl + root.inset)
        y: root.fromBottom ? root.bottomInset : (root.fromRight || root.vertical ? root.sl + root.inset : root.tpe)
        width: Math.max(0, (root.fromRight || root.vertical) ? root.ld - root.tpe - root.bottomInset
                                                             : root.la - 2 * (root.sl + root.inset))
        height: Math.max(0, (root.fromRight || root.vertical) ? root.la - 2 * (root.sl + root.inset)
                                                              : root.ld - root.tpe - root.bottomInset)
    }
}
