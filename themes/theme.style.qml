// ============================================================================
// File: theme/theme.style.qml
// Purpose: Centralized QML Singleton storing every color token and alpha
//          variant used across the entire Quickshell desktop shell.
// Public API:
//   - Base surfaces: backgroundPrimary, backgroundBlack, weatherPanelSurface,
//                    circleOverrideExample, transparent
//   - Foregrounds:   textPrimary, textBright, textSecondary, textDim,
//                    textMuted, textPlaceholder, textSubtle, textOnAccent
//   - Brand/Status:  accent, danger, editSwipeBg, editSwipeIcon
//   - White alphas:  surfaceWhite04 .. surfaceWhite75
//   - Black alphas:  shadowBlack40
//   - Accent alphas: accentBorderDragging, accentGlowNearDock
//   - Danger alphas: dangerTint18, dangerTint20, dangerTint25,
//                    dangerClampedTint18
//   - Info alphas:   editTint25
// Dependencies: QtQuick
// ============================================================================
pragma Singleton
import QtQuick

QtObject {
    // ── Primary Surfaces & Backgrounds ───────────────────────────────────────
    /** Primary pitch-black fill used by bars, strips, drops, cards, and panels. */
    readonly property color backgroundPrimary: "#000000"

    /** Named black color literal used by Drop default fill. */
    readonly property color backgroundBlack: "black"

    /** Dark elevated card surface used as the weather card backdrop on the calendar panel. */
    readonly property color weatherPanelSurface: "#0f0f0f"

    /** Reference override color for launcher circle customization examples. */
    readonly property color circleOverrideExample: "#1a1a1a"

    /** Fully transparent color token for unstyled backgrounds and stroke resets. */
    readonly property color transparent: "transparent"

    // ── Typography & Foreground Colors ───────────────────────────────────────
    /** Primary off-white text and icon foreground color. */
    readonly property color textPrimary: "#ececec"

    /** Pure white foreground used for hover states and swipe action icons. */
    readonly property color textBright: "#ffffff"

    /** Pure white 1px border color for all shell items. */
    readonly property color borderWhite: "#ffffff"

    /** Secondary light-gray text used for notification body copy. */
    readonly property color textSecondary: "#9e9e9e"

    /** Standard dimmed gray text used for labels, subtitles, and inactive icons. */
    readonly property color textDim: "#7a7a7a"

    /** Muted gray text used for calendar day headers and card close glyphs. */
    readonly property color textMuted: "#6f6f6f"

    /** Placeholder text color in search inputs. */
    readonly property color textPlaceholder: "#666666"

    /** Subtle dark gray text used for timestamps and empty-state captions. */
    readonly property color textSubtle: "#555555"

    /** Dark text rendered atop high-contrast accent orange backgrounds. */
    readonly property color textOnAccent: "#000000"

    // ── Brand & Semantic Accents ─────────────────────────────────────────────
    /** Primary brand orange accent for active states, focus rings, and normal urgency. */
    readonly property color accent: "#f39c34"

    /** Semantic red for critical urgency, mute indicators, and destructive actions. */
    readonly property color danger: "#e5484d"

    /** Semantic blue background for swipe-to-edit action in floating stick notes. */
    readonly property color editSwipeBg: "#3b82f6"

    /** Semantic light-blue icon color for swipe-to-edit action in docked stick notes. */
    readonly property color editSwipeIcon: "#60a5fa"

    // ── White Alpha Overlays (Qt.rgba(1, 1, 1, alpha)) ───────────────────────
    /** 4% white overlay: inner subtle border on floating windows. */
    readonly property color surfaceWhite04: Qt.rgba(1, 1, 1, 0.04)

    /** 5% white overlay: empty workspace tiles, notification cards, and subtle dividers. */
    readonly property color surfaceWhite05: Qt.rgba(1, 1, 1, 0.05)

    /** 6% white overlay: standard card background, search box fill, and hover rows. */
    readonly property color surfaceWhite06: Qt.rgba(1, 1, 1, 0.06)

    /** 7% white overlay: stick note drawer card background. */
    readonly property color surfaceWhite07: Qt.rgba(1, 1, 1, 0.07)

    /** 8% white overlay: section dividers, icon badges, and button hover fills. */
    readonly property color surfaceWhite08: Qt.rgba(1, 1, 1, 0.08)

    /** 9% white overlay: notification history row hover fill and stick note item background. */
    readonly property color surfaceWhite09: Qt.rgba(1, 1, 1, 0.09)

    /** 10% white overlay: circle launcher border, current location row, and subtle borders. */
    readonly property color surfaceWhite10: Qt.rgba(1, 1, 1, 0.10)

    /** 12% white overlay: occupied workspace tiles, selected app row, and button active hover. */
    readonly property color surfaceWhite12: Qt.rgba(1, 1, 1, 0.12)

    /** 14% white overlay: volume slider tracks and floating panel button borders. */
    readonly property color surfaceWhite14: Qt.rgba(1, 1, 1, 0.14)

    /** 16% white overlay: primary outer border for panels, floating windows, and circles. */
    readonly property color surfaceWhite16: Qt.rgba(1, 1, 1, 0.16)

    /** 20% white overlay: workspace tile hover fill and empty notification bell icon. */
    readonly property color surfaceWhite20: Qt.rgba(1, 1, 1, 0.20)

    /** 25% white overlay: drag pill handles, scrollbars, and low-urgency history bars. */
    readonly property color surfaceWhite25: Qt.rgba(1, 1, 1, 0.25)

    /** 28% white overlay: low-urgency notification toast card border. */
    readonly property color surfaceWhite28: Qt.rgba(1, 1, 1, 0.28)

    /** 45% white overlay: rising water-bubble border and overflow indicator pill. */
    readonly property color surfaceWhite45: Qt.rgba(1, 1, 1, 0.45)

    /** 75% white overlay: specular shine highlight inside rising notification water bubbles. */
    readonly property color surfaceWhite75: Qt.rgba(1, 1, 1, 0.75)

    // ── Black Alpha Overlays ─────────────────────────────────────────────────
    /** 40% black overlay: volume slider thumb contrast border. */
    readonly property color shadowBlack40: Qt.rgba(0, 0, 0, 0.4)

    // ── Accent Orange Alpha Overlays ─────────────────────────────────────────
    /** 70% accent orange: floating window outer border while actively dragging. */
    readonly property color accentBorderDragging: Qt.rgba(243 / 255, 156 / 255, 52 / 255, 0.7)

    /** 40% accent orange: floating window inner glow border when near dock snap zone. */
    readonly property color accentGlowNearDock: Qt.rgba(243 / 255, 156 / 255, 52 / 255, 0.4)

    // ── Danger Red Alpha Overlays ────────────────────────────────────────────
    /** 18% danger red (normalized floats): muted button fill in FloatingNotifPanel. */
    readonly property color dangerTint18: Qt.rgba(229 / 255, 72 / 255, 77 / 255, 0.18)

    /** 20% danger red: floating window close button hover background. */
    readonly property color dangerTint20: Qt.rgba(229 / 255, 72 / 255, 77 / 255, 0.2)

    /** 25% danger red: stick note delete button hover and swipe-left delete background. */
    readonly property color dangerTint25: Qt.rgba(0.9, 0.28, 0.3, 0.25)

    /**
     * Preserved clamped tint from NotificationCenterBar (`Qt.rgba(229, 72, 77, 0.18)`).
     * Because Qt.rgba expects 0.0..1.0 floats, passing 229, 72, 77 clamps RGB to 1.0, 1.0, 1.0
     * at runtime. Preserved verbatim to guarantee zero visual regression.
     */
    readonly property color dangerClampedTint18: Qt.rgba(229, 72, 77, 0.18)

    // ── Info / Edit Blue Alpha Overlays ──────────────────────────────────────
    /** 25% info blue: docked stick note swipe-right edit background. */
    readonly property color editTint25: Qt.rgba(0.2, 0.6, 1.0, 0.25)

    // ── Liquid Glass Optical Tokens (Transparent in solid pitch-black theme) ─
    /** Top specular catchlight gradient stop for liquid glass surfaces. */
    readonly property color glassSheenTop: Qt.rgba(0, 0, 0, 0)

    /** Upper-middle frosted refraction gradient stop for liquid glass surfaces. */
    readonly property color glassSheenMid: Qt.rgba(0, 0, 0, 0)

    /** Center core translucent gradient stop for liquid glass surfaces. */
    readonly property color glassSheenCore: Qt.rgba(0, 0, 0, 0)

    /** Far/bottom edge internal caustic bounce gradient stop for liquid glass surfaces. */
    readonly property color glassSheenBottom: Qt.rgba(0, 0, 0, 0)

    /** Wide inner 3D refractive bevel glow along curved glass edges. */
    readonly property color glassInnerBevel: Qt.rgba(0, 0, 0, 0)

    /** Crisp specular lip highlight on the top crest of glass cards and spheres. */
    readonly property color glassRimHighlight: Qt.rgba(0, 0, 0, 0)

    // ── Stick Note Color Palette Swatches ────────────────────────────────────
    readonly property color paletteBlue: "#3b82f6"
    readonly property color paletteOrange: "#f39c34"
    readonly property color paletteRed: "#e5484d"
    readonly property color paletteYellow: "#eab308"
    readonly property color paletteGreen: "#22c55e"
    readonly property color paletteCyan: "#06b6d4"
    readonly property color palettePurple: "#a855f7"
    readonly property color palettePink: "#ec4899"
}
