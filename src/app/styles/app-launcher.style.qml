// ============================================================================
// File: styles/app-launcher.style.qml
// Purpose: Dimensions, circle offsets, and Theme tokens for AppLauncher.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color textPrimary: Theme.appLauncherTextPrimary
    readonly property color textDim: Theme.appLauncherTextDim
    readonly property color accent: Theme.appLauncherAccent
    readonly property color fill: Theme.appLauncherFill
    readonly property color circleHoverBg: Theme.appLauncherCircleHoverBg
    readonly property color circleIdleBorder: Theme.appLauncherCircleIdleBorder
    readonly property color transparent: Theme.transparent
    readonly property color glassSheenTop: Theme.appLauncherGlassSheenTop
    readonly property color glassSheenMid: Theme.appLauncherGlassSheenMid
    readonly property color glassSheenCore: Theme.appLauncherGlassSheenCore
    readonly property color glassSheenBottom: Theme.appLauncherGlassSheenBottom
    readonly property color glassInnerBevel: Theme.appLauncherGlassInnerBevel

    readonly property real floatWidth: 440
    readonly property real floatHeight: 520
    readonly property real detachThresholdY: 14
    readonly property real detachThresholdHypot: 18

    readonly property real barWidth: 260
    readonly property real barHeight: 36
    readonly property real hiddenHeight: 8
    readonly property real hiddenTipSize: 8
    readonly property int unhoverDelayMs: 120
    readonly property real circleDiameter: 26
    readonly property real circleGap: 12
    readonly property real circleSpacing: 10
    readonly property int fadeDurationMs: 140
    readonly property real dropSlant: 20
    readonly property real dropRadius: 12
    readonly property real dropFlare: 12
    readonly property real dropInset: 8
    readonly property real dropBottomInset: 4
    readonly property real btnPressedScale: 0.98
    readonly property real btnHoverScale: 1.02
    readonly property int scaleAnimDurationMs: 100
    readonly property real contentRowSpacing: 10
    readonly property real iconGridSpacing: 3
    readonly property real iconDotSize: 5
    readonly property real iconDotRadius: 1.5
    readonly property int colorAnimDurationMs: 120
    readonly property int labelFontPx: 13
    readonly property real circlePressedScale: 0.90
    readonly property int circleIconFontPx: 11
    readonly property real trayCircleDiameter: 22
    readonly property real trayCircleSpacing: 8
    readonly property real trayIconSize: 13
    readonly property int trayTooltipFontPx: 11
    readonly property real trayTooltipRadius: 6
    readonly property real trayTooltipPaddingH: 8
    readonly property real trayTooltipPaddingV: 4
    readonly property real trayMenuWidth: 200
    readonly property real trayMenuItemHeight: 26
    readonly property real trayMenuSeparatorHeight: 7
    readonly property real trayMenuPadding: 6
    readonly property real trayMenuRadius: 10
    readonly property real trayMenuItemRadius: 6
    readonly property real trayMenuGap: 10
    readonly property real trayMenuHeaderHeight: 22
}
