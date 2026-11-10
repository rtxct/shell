// ============================================================================
// File: styles/media-control-bar.style.qml
// Purpose: Geometry, merge physics, audio wave perimeter constants, and Theme tokens for MediaControlBar.
// Dependencies: QtQuick, Theme (../theme)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color textPrimary: Theme.textPrimary
    readonly property color textDim: Theme.textDim
    readonly property color accent: Theme.accent
    readonly property color fill: Theme.backgroundPrimary
    readonly property color danger: Theme.danger
    readonly property color circleHoverBg: Theme.surfaceWhite08
    readonly property color circleIdleBorder: Theme.borderWhite
    readonly property color sliderTrackBg: Theme.surfaceWhite16
    readonly property color sliderThumbBorder: Theme.shadowBlack40
    readonly property color dropActiveStrokeColor: Theme.transparent
    readonly property color dropActiveFillColor: Theme.transparent
    readonly property color glassSheenTop: Theme.glassSheenTop
    readonly property color glassSheenMid: Theme.glassSheenMid
    readonly property color glassSheenCore: Theme.glassSheenCore
    readonly property color glassSheenBottom: Theme.glassSheenBottom
    readonly property color glassInnerBevel: Theme.glassInnerBevel

    readonly property real floatWidth: 500
    readonly property real floatHeight: 560
    readonly property real floatBarWidth: 334
    readonly property real floatBarHeight: 36
    readonly property real floatBarPaddingX: 8
    readonly property real floatBarSpacing: 6
    readonly property real floatBarBtnSize: 20
    readonly property real floatBarBtnRadius: 5
    readonly property real floatBarDragGripWidth: 10
    readonly property real floatBarDragDotSize: 3
    readonly property real floatBarDragDotSpacing: 2
    readonly property real detachThresholdY: 14
    readonly property real detachThresholdHypot: 18
    readonly property real wheelVolumeStep: 0.03

    readonly property real mediaBaseWidth: 260
    readonly property real barHeight: 36
    readonly property real circleDiameter: 26
    readonly property real circleSpacing: 10
    readonly property real dropGap: 12
    readonly property int autoUnmergeMs: 280
    readonly property real circleMergedScale: 0.25
    readonly property real circlePressedScale: 0.90
    readonly property int colorAnimDurationMs: 120
    readonly property int circleScaleDurationMs: 200
    readonly property int circleFadeDurationMs: 180
    readonly property int circleMoveDurationMs: 220
    readonly property int circleIconFontPx: 11

    readonly property real dropSlant: 20
    readonly property real dropRadius: 12
    readonly property real dropFlare: 12
    readonly property real dropInset: 8
    readonly property real dropBottomInset: 4
    readonly property int mergeDurationMs: 240

    readonly property real mediaControlSpacing: 22
    readonly property int mediaFadeDurationMs: 160
    readonly property real mediaBtnWidth: 28
    readonly property real mediaBtnHeight: 26
    readonly property real playBtnWidth: 30
    readonly property real btnPressedScale: 0.88
    readonly property real prevNextHoverScale: 1.12
    readonly property real playHoverScale: 1.14
    readonly property int btnScaleDurationMs: 90
    readonly property int btnColorDurationMs: 100
    readonly property int prevNextIconFontPx: 13
    readonly property int playPauseIconFontPx: 15
    readonly property real btnHitPadding: 4
    readonly property int nowPlayingTitleFontPx: 11
    readonly property int nowPlayingAppFontPx: 9
    readonly property int nowPlayingIconFontPx: 10
    readonly property real nowPlayingSpacing: 1
    readonly property real nowPlayingIconSpacing: 5
    readonly property real nowPlayingHorizontalPadding: 6

    readonly property int contentSwitchDurationMs: 180
    readonly property real sliderMuteBtnWidth: 28
    readonly property int sliderMuteIconFontPx: 15
    readonly property real sliderPctWidth: 38
    readonly property int sliderPctFontPx: 12
    readonly property real sliderHorizontalMargin: 8
    readonly property real sliderTrackHeight: 6
    readonly property real sliderTrackRadius: 3
    readonly property real sliderThumbSize: 12
    readonly property real sliderThumbRadius: 6
    readonly property real sliderThumbPressedScale: 1.25
    readonly property real sliderThumbHoverScale: 1.15
    readonly property int sliderThumbScaleDurationMs: 100

    readonly property real wavePadX: 24
    readonly property real wavePadY: 40
    readonly property real waveBottomPad: 4
    readonly property int waveFadeDurationMs: 200
    readonly property int waveTickIntervalMs: 16
    readonly property real waveAmplitudeScale: 15.0
    readonly property real waveDecayFactor: 0.84
    readonly property real waveStrokeWidth: 1.2
}
