// ============================================================================
// File: styles/polkit-agent.style.qml
// Purpose: Colors, modal card dimensions, typography, and timings for PolkitAuth / PolkitDialog.
// Dependencies: QtQuick, Theme (../../../themes)
// ============================================================================
pragma Singleton
import QtQuick
import "../../../themes"

QtObject {
    readonly property color scrimColor: Theme.polkitScrimColor
    readonly property color background: Theme.polkitBackground
    readonly property color borderColor: Theme.polkitBorderColor
    readonly property color innerGlowColor: Theme.polkitInnerGlowColor
    readonly property color glassSheenTop: Theme.polkitGlassSheenTop
    readonly property color glassSheenMid: Theme.polkitGlassSheenMid
    readonly property color glassSheenCore: Theme.polkitGlassSheenCore
    readonly property color glassSheenBottom: Theme.polkitGlassSheenBottom
    readonly property color glassInnerBevel: Theme.polkitGlassInnerBevel
    readonly property color glassRimHighlight: Theme.polkitGlassRimHighlight
    readonly property color iconBadgeBg: Theme.polkitIconBadgeBg
    readonly property color iconBadgeBorder: Theme.polkitIconBadgeBorder
    readonly property color iconColor: Theme.polkitIconColor
    readonly property color titleColor: Theme.polkitTitleColor
    readonly property color messageColor: Theme.polkitMessageColor
    readonly property color detailColor: Theme.polkitDetailColor
    readonly property color identityBg: Theme.polkitIdentityBg
    readonly property color identityHoverBg: Theme.polkitIdentityHoverBg
    readonly property color identityBorder: Theme.polkitIdentityBorder
    readonly property color identityTextColor: Theme.polkitIdentityTextColor
    readonly property color identitySubTextColor: Theme.polkitIdentitySubTextColor
    readonly property color inputBg: Theme.polkitInputBg
    readonly property color inputBorder: Theme.polkitInputBorder
    readonly property color inputBorderFocused: Theme.polkitInputBorderFocused
    readonly property color inputBorderError: Theme.polkitInputBorderError
    readonly property color inputTextColor: Theme.polkitInputTextColor
    readonly property color inputPlaceholderColor: Theme.polkitInputPlaceholderColor
    readonly property color errorColor: Theme.polkitErrorColor
    readonly property color infoColor: Theme.polkitInfoColor
    readonly property color cancelBtnBg: Theme.polkitCancelBtnBg
    readonly property color cancelBtnHoverBg: Theme.polkitCancelBtnHoverBg
    readonly property color cancelBtnPressedBg: Theme.polkitCancelBtnPressedBg
    readonly property color cancelBtnBorder: Theme.polkitCancelBtnBorder
    readonly property color cancelBtnText: Theme.polkitCancelBtnText
    readonly property color authBtnBg: Theme.polkitAuthBtnBg
    readonly property color authBtnHoverBg: Theme.polkitAuthBtnHoverBg
    readonly property color authBtnDisabledBg: Theme.polkitAuthBtnDisabledBg
    readonly property color authBtnText: Theme.polkitAuthBtnText
    readonly property color authBtnDisabledText: Theme.polkitAuthBtnDisabledText
    readonly property color transparent: Theme.transparent

    readonly property real dialogWidth: 420
    readonly property real dialogRadius: 16
    readonly property real dialogPadding: 24
    readonly property real contentSpacing: 14
    readonly property real iconBadgeSize: 52
    readonly property real iconBadgeRadius: 26
    readonly property int iconFontPx: 24
    readonly property int titleFontPx: 18
    readonly property int messageFontPx: 13
    readonly property int detailFontPx: 11
    readonly property real identityHeight: 40
    readonly property real identityRadius: 10
    readonly property int identityFontPx: 13
    readonly property real inputHeight: 42
    readonly property real inputRadius: 10
    readonly property int inputFontPx: 14
    readonly property real buttonHeight: 38
    readonly property real buttonRadius: 10
    readonly property real buttonSpacing: 10
    readonly property int buttonFontPx: 13
    readonly property real closedScale: 0.92
    readonly property int fadeDurationMs: 160
    readonly property int scaleDurationMs: 180
    readonly property int colorAnimDurationMs: 120
    readonly property string iconFont: "Symbols Nerd Font"
}
