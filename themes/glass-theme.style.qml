// ============================================================================
// File: theme/glass-theme.style.qml
// Purpose: Apple iOS Liquid Glass theme with translucent smoky black glass
//          substrates, multi-stop refractive sheen gradients, 3D inner
//          caustic bevels, crisp specular rims, and high-contrast monochrome accents.
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
//   - Glass optics:  glassSheenTop, glassSheenMid, glassSheenCore,
//                    glassSheenBottom, glassInnerBevel, glassRimHighlight
// Dependencies: QtQuick
// ============================================================================
pragma Singleton
import QtQuick

QtObject {
    // ── Primary Surfaces & Backgrounds (Translucent Black Glass Substrates) ──
    /** Luminous frosted dark glass fill used by panels, drawers, and cards. */
    readonly property color backgroundPrimary: Qt.rgba(0.0, 0.0, 0.0, 0.70)

    /** Frosted liquid dark glass substrate used by Drop procedural vector shapes. */
    readonly property color backgroundBlack: Qt.rgba(0.0, 0.0, 0.0, 0.65)

    /** Elevated frosted dark glass card surface used as the weather card backdrop. */
    readonly property color weatherPanelSurface: Qt.rgba(0.08, 0.08, 0.08, 0.60)

    /** Reference override color for launcher circle customization examples. */
    readonly property color circleOverrideExample: Qt.rgba(0.10, 0.10, 0.10, 0.65)

    /** Fully transparent color token for unstyled backgrounds and stroke resets. */
    readonly property color transparent: "transparent"

    // ── Typography & Foreground Colors ───────────────────────────────────────
    /** Primary Apple off-white text and icon foreground color (iOS system label). */
    readonly property color textPrimary: "#f5f5f7"

    /** Pure white foreground used for hover states, active glyphs, and swipe action icons. */
    readonly property color textBright: "#ffffff"

    /** Bright crystalline specular glass rim highlight for all shell borders. */
    readonly property color borderWhite: Qt.rgba(1.0, 1.0, 1.0, 0.65)

    /** Secondary vibrant light-gray text used for subtitles and notification body copy. */
    readonly property color textSecondary: Qt.rgba(0.96, 0.96, 0.96, 0.80)

    /** Standard dimmed vibrant gray text used for tertiary labels and inactive icons. */
    readonly property color textDim: Qt.rgba(0.92, 0.92, 0.92, 0.62)

    /** Muted gray text used for calendar day headers and card close glyphs. */
    readonly property color textMuted: Qt.rgba(0.90, 0.90, 0.90, 0.48)

    /** Placeholder text color in search inputs. */
    readonly property color textPlaceholder: Qt.rgba(0.90, 0.90, 0.90, 0.40)

    /** Subtle gray text used for timestamps and empty-state captions. */
    readonly property color textSubtle: Qt.rgba(0.88, 0.88, 0.88, 0.32)

    /** High-contrast text rendered atop vibrant accent backgrounds. */
    readonly property color textOnAccent: "#000000"

    // ── Brand & Semantic Accents ─────────────────────────────────────────────
    /** Crisp monochrome white accent for active states, focus rings, and normal urgency. */
    readonly property color accent: "#ffffff"

    /** Apple iOS system red for critical urgency, mute indicators, and destructive actions. */
    readonly property color danger: "#ff453a"

    /** Semantic monochrome white background for swipe-to-edit action in floating stick notes. */
    readonly property color editSwipeBg: "#ffffff"

    /** High-contrast dark icon color for swipe-to-edit action. */
    readonly property color editSwipeIcon: "#000000"

    // ── White Alpha Overlays (Frosted Glass Plates) ──────────────────────────
    /** 8% white overlay: inner subtle border on floating windows. */
    readonly property color surfaceWhite04: Qt.rgba(1, 1, 1, 0.08)

    /** 10% white overlay: empty workspace tiles, notification cards, and subtle dividers. */
    readonly property color surfaceWhite05: Qt.rgba(1, 1, 1, 0.10)

    /** 13% white overlay: standard glass card background, search box fill, and hover rows. */
    readonly property color surfaceWhite06: Qt.rgba(1, 1, 1, 0.13)

    /** 15% white overlay: stick note drawer card background. */
    readonly property color surfaceWhite07: Qt.rgba(1, 1, 1, 0.15)

    /** 17% white overlay: section dividers, icon badges, and button hover fills. */
    readonly property color surfaceWhite08: Qt.rgba(1, 1, 1, 0.17)

    /** 19% white overlay: notification history row hover fill and stick note item background. */
    readonly property color surfaceWhite09: Qt.rgba(1, 1, 1, 0.19)

    /** 22% white overlay: circle launcher border, current location row, and subtle borders. */
    readonly property color surfaceWhite10: Qt.rgba(1, 1, 1, 0.22)

    /** 25% white overlay: occupied workspace tiles, selected app row, and button active hover. */
    readonly property color surfaceWhite12: Qt.rgba(1, 1, 1, 0.25)

    /** 28% white overlay: volume slider tracks and floating panel button borders. */
    readonly property color surfaceWhite14: Qt.rgba(1, 1, 1, 0.28)

    /** 32% white overlay: primary outer border for panels, floating windows, and circles. */
    readonly property color surfaceWhite16: Qt.rgba(1, 1, 1, 0.32)

    /** 36% white overlay: workspace tile hover fill and empty notification bell icon. */
    readonly property color surfaceWhite20: Qt.rgba(1, 1, 1, 0.36)

    /** 42% white overlay: drag pill handles, scrollbars, and low-urgency history bars. */
    readonly property color surfaceWhite25: Qt.rgba(1, 1, 1, 0.42)

    /** 48% white overlay: low-urgency notification toast card border. */
    readonly property color surfaceWhite28: Qt.rgba(1, 1, 1, 0.48)

    /** 62% white overlay: rising water-bubble border and overflow indicator pill. */
    readonly property color surfaceWhite45: Qt.rgba(1, 1, 1, 0.62)

    /** 90% white overlay: specular shine highlight inside rising notification water bubbles. */
    readonly property color surfaceWhite75: Qt.rgba(1, 1, 1, 0.90)

    // ── Black Alpha Overlays ─────────────────────────────────────────────────
    /** 35% black overlay: volume slider thumb contrast border. */
    readonly property color shadowBlack40: Qt.rgba(0, 0, 0, 0.35)

    // ── Accent Alpha Overlays (Monochrome White) ─────────────────────────────
    /** 85% accent white: floating window outer border while actively dragging. */
    readonly property color accentBorderDragging: Qt.rgba(1.0, 1.0, 1.0, 0.85)

    /** 50% accent white: floating window inner glow border when near dock snap zone. */
    readonly property color accentGlowNearDock: Qt.rgba(1.0, 1.0, 1.0, 0.50)

    // ── Danger Red Alpha Overlays (Apple Red) ────────────────────────────────
    /** 20% danger red (normalized floats): muted button fill in FloatingNotifPanel. */
    readonly property color dangerTint18: Qt.rgba(255 / 255, 69 / 255, 58 / 255, 0.20)

    /** 25% danger red: floating window close button hover background. */
    readonly property color dangerTint20: Qt.rgba(255 / 255, 69 / 255, 58 / 255, 0.25)

    /** 32% danger red: stick note delete button hover and swipe-left delete background. */
    readonly property color dangerTint25: Qt.rgba(255 / 255, 69 / 255, 58 / 255, 0.32)

    /** Preserved clamped tint from NotificationCenterBar for full compatibility. */
    readonly property color dangerClampedTint18: Qt.rgba(229, 72, 77, 0.18)

    // ── Info / Edit Alpha Overlays ───────────────────────────────────────────
    /** 70% white overlay: docked stick note swipe-right edit background pill. */
    readonly property color editTint25: Qt.rgba(1.0, 1.0, 1.0, 0.70)

    // ── Liquid Glass Optical Tokens (Multi-Stop Refraction & Specular Bevel) ─
    /** Top specular catchlight gradient stop simulating light hitting frosted glass. */
    readonly property color glassSheenTop: Qt.rgba(1.0, 1.0, 1.0, 0.34)

    /** Upper-middle frosted refraction gradient stop across glass pane. */
    readonly property color glassSheenMid: Qt.rgba(1.0, 1.0, 1.0, 0.14)

    /** Deep clear glass core stop creating 3D optical depth in the middle of the pane. */
    readonly property color glassSheenCore: Qt.rgba(0.0, 0.0, 0.0, 0.15)

    /** Far/bottom edge internal caustic bounce reflection along curved glass tips. */
    readonly property color glassSheenBottom: Qt.rgba(1.0, 1.0, 1.0, 0.22)

    /** Wide inner 3D refractive bevel glow along curved glass edges. */
    readonly property color glassInnerBevel: Qt.rgba(1.0, 1.0, 1.0, 0.25)

    /** Crisp specular lip highlight on the top crest of glass cards and spheres. */
    readonly property color glassRimHighlight: Qt.rgba(1.0, 1.0, 1.0, 0.68)

    // ── Stick Note Color Palette Swatches (Apple iOS System Colors) ──────────
    readonly property color paletteBlue: "#0a84ff"
    readonly property color paletteOrange: "#ff9f0a"
    readonly property color paletteRed: "#ff453a"
    readonly property color paletteYellow: "#ffd60a"
    readonly property color paletteGreen: "#30d158"
    readonly property color paletteCyan: "#64d2ff"
    readonly property color palettePurple: "#bf5af2"
    readonly property color palettePink: "#ff375f"
}
