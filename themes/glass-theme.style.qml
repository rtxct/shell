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

    // =========================================================================
    // COMPONENT OVERRIDE GROUPS
    // =========================================================================
    // Every color token below controls a specific UI module or component.
    // By default each property inherits from the global tokens above; replace
    // any individual token with a custom color to style that component alone.

    // -------------------------------------------------------------------------
    // Group 1: Base Drops & Edge Strips (drop.style.qml, strip.style.qml)
    // -------------------------------------------------------------------------
    readonly property color dropFill: backgroundBlack
    readonly property color dropPrimaryFill: backgroundPrimary
    readonly property color dropFillStrokeColor: transparent
    readonly property color dropStrokeColor: borderWhite
    readonly property color dropGlassSheenTop: glassSheenTop
    readonly property color dropGlassSheenMid: glassSheenMid
    readonly property color dropGlassSheenCore: glassSheenCore
    readonly property color dropGlassSheenBottom: glassSheenBottom
    readonly property color dropGlassInnerBevel: glassInnerBevel
    readonly property color stripFill: backgroundPrimary

    // -------------------------------------------------------------------------
    // Group 2: Top Islands, Middle Clock & Placeholder
    // (island.style.qml, middle-bar.style.qml, panel-placeholder.style.qml)
    // -------------------------------------------------------------------------
    readonly property color islandFill: backgroundPrimary
    readonly property color islandTextPrimary: textPrimary
    readonly property color islandTextDim: textDim
    readonly property color islandAccent: accent
    readonly property color middleBarTextPrimary: textPrimary
    readonly property color panelPlaceholderTextColor: textDim

    // -------------------------------------------------------------------------
    // Group 3: Workspaces & Central Workspace Grid
    // (workspace-island.style.qml, workspace-central.style.qml)
    // -------------------------------------------------------------------------
    readonly property color workspaceIslandUrgentColor: danger
    readonly property color workspaceIslandAccentText: textOnAccent
    readonly property color workspaceCentralTextPrimary: textPrimary
    readonly property color workspaceCentralTextDim: textDim
    readonly property color workspaceCentralAccent: accent
    readonly property color workspaceCentralTileEmpty: surfaceWhite05
    readonly property color workspaceCentralTileOccupied: surfaceWhite12
    readonly property color workspaceCentralTileHover: surfaceWhite20
    readonly property color workspaceCentralUrgentColor: danger
    readonly property color workspaceCentralAccentText: textOnAccent

    // -------------------------------------------------------------------------
    // Group 4: Quick-Action Circle Launchers & Menus (circle.style.qml)
    // -------------------------------------------------------------------------
    readonly property color circleFill: backgroundPrimary
    readonly property color circleBorderColor: borderWhite
    readonly property color circleGlyphColor: textPrimary
    readonly property color circleTextBright: textBright
    readonly property color circleTextSecondary: textSecondary
    readonly property color circleDangerColor: danger
    readonly property color circleDangerTint25: dangerTint25
    readonly property color circleAccentColor: accent
    readonly property color circleTextDim: textDim
    readonly property color circleItemBg: surfaceWhite05
    readonly property color circleItemHoverBg: surfaceWhite08
    readonly property color circleItemSelectedBg: surfaceWhite12
    readonly property color circleItemBorder: surfaceWhite10
    readonly property color circleItemSelectedBorder: surfaceWhite20
    readonly property color circleGlassSheenTop: glassSheenTop
    readonly property color circleGlassSheenMid: glassSheenMid
    readonly property color circleGlassSheenCore: glassSheenCore
    readonly property color circleGlassSheenBottom: glassSheenBottom
    readonly property color circleGlassInnerBevel: glassInnerBevel

    // -------------------------------------------------------------------------
    // Group 5: Side Bars & System Performance (side-bar.style.qml)
    // -------------------------------------------------------------------------
    readonly property color sideBarFill: backgroundPrimary
    readonly property color sideBarTextPrimary: textPrimary
    readonly property color sideBarPerfArcPrimary: accent
    readonly property color sideBarPerfArcSecondary: textSecondary
    readonly property color sideBarPerfTrackPrimary: surfaceWhite14
    readonly property color sideBarPerfTrackSecondary: surfaceWhite08
    readonly property color sideBarPerfTextDim: textDim
    readonly property color sideBarPerfCardBg: surfaceWhite06
    readonly property color sideBarPerfCardHoverBg: surfaceWhite12
    readonly property color sideBarPerfRowHoverBg: surfaceWhite25
    readonly property color sideBarPerfCardBorder: surfaceWhite14
    readonly property color sideBarPerfCardHoverBorder: borderWhite
    readonly property color sideBarPerfCardPressedBg: surfaceWhite20
    readonly property color sideBarPerfGraphFill: surfaceWhite10
    readonly property color sideBarPerfDanger: danger

    // -------------------------------------------------------------------------
    // Group 6: Calendar & Events
    // (calendar-panel.style.qml, month-grid.style.qml, events-list.style.qml)
    // -------------------------------------------------------------------------
    readonly property color calendarPanelDividerColor: surfaceWhite08
    readonly property color calendarPanelWeatherBg: weatherPanelSurface
    readonly property color monthGridTextPrimary: textPrimary
    readonly property color monthGridTextMuted: textMuted
    readonly property color monthGridAccent: accent
    readonly property color monthGridTodayText: textOnAccent
    readonly property color monthGridHoverCircleColor: surfaceWhite12
    readonly property color monthGridSelectedCircleColor: surfaceWhite20
    readonly property color monthGridTextBright: textBright
    readonly property color eventsListTextPrimary: textPrimary
    readonly property color eventsListTextDim: textDim
    readonly property color eventsListAccent: accent
    readonly property color eventsListCardColor: surfaceWhite06
    readonly property color eventsListCardHoverColor: surfaceWhite10

    // -------------------------------------------------------------------------
    // Group 7: Weather (weather-card, weather-view, location-picker)
    // -------------------------------------------------------------------------
    readonly property color weatherCardTextPrimary: textPrimary
    readonly property color weatherCardTextDim: textDim
    readonly property color weatherCardColor: surfaceWhite06
    readonly property color weatherCardHoverColor: surfaceWhite10
    readonly property color weatherCardBorderColor: glassInnerBevel
    readonly property color weatherCardGlassRimHighlight: glassRimHighlight
    readonly property color weatherViewTextPrimary: textPrimary
    readonly property color weatherViewTextDim: textDim
    readonly property color weatherViewTextSecondary: textSecondary
    readonly property color weatherViewTextSubtle: textSubtle
    readonly property color weatherViewAccent: accent
    readonly property color weatherViewCardColor: surfaceWhite06
    readonly property color weatherViewCardHoverColor: surfaceWhite10
    readonly property color weatherViewDividerColor: surfaceWhite08
    readonly property color weatherViewScrollBarColor: surfaceWhite20
    readonly property color locationPickerTextPrimary: textPrimary
    readonly property color locationPickerAccent: accent
    readonly property color locationPickerRowHover: surfaceWhite06
    readonly property color locationPickerRowCurrent: surfaceWhite10

    // -------------------------------------------------------------------------
    // Group 8: App Launcher & System Tray (app-launcher.style.qml)
    // -------------------------------------------------------------------------
    readonly property color appLauncherTextPrimary: textPrimary
    readonly property color appLauncherTextDim: textDim
    readonly property color appLauncherAccent: accent
    readonly property color appLauncherFill: backgroundPrimary
    readonly property color appLauncherCircleHoverBg: surfaceWhite08
    readonly property color appLauncherCircleIdleBorder: borderWhite
    readonly property color appLauncherGlassSheenTop: glassSheenTop
    readonly property color appLauncherGlassSheenMid: glassSheenMid
    readonly property color appLauncherGlassSheenCore: glassSheenCore
    readonly property color appLauncherGlassSheenBottom: glassSheenBottom
    readonly property color appLauncherGlassInnerBevel: glassInnerBevel

    // -------------------------------------------------------------------------
    // Group 9: App Menu & Clipboard History (app-menu.style.qml)
    // -------------------------------------------------------------------------
    readonly property color appMenuTextPrimary: textPrimary
    readonly property color appMenuTextDim: textDim
    readonly property color appMenuTextPlaceholder: textPlaceholder
    readonly property color appMenuTextOnAccent: textOnAccent
    readonly property color appMenuAccent: accent
    readonly property color appMenuCardBg: backgroundPrimary
    readonly property color appMenuDragPillColor: surfaceWhite25
    readonly property color appMenuSearchBoxBg: surfaceWhite06
    readonly property color appMenuSearchBoxBorder: surfaceWhite10
    readonly property color appMenuRowSelectedBg: surfaceWhite12
    readonly property color appMenuRowHoverBg: surfaceWhite06
    readonly property color appMenuRowDividerColor: surfaceWhite05
    readonly property color appMenuSortDividerColor: borderWhite
    readonly property color appMenuSortTextColor: textDim
    readonly property color appMenuSortTextHoverColor: textBright

    // -------------------------------------------------------------------------
    // Group 10: Media Control Bar & Audio (media-control-bar.style.qml)
    // -------------------------------------------------------------------------
    readonly property color mediaControlBarTextPrimary: textPrimary
    readonly property color mediaControlBarTextDim: textDim
    readonly property color mediaControlBarAccent: accent
    readonly property color mediaControlBarFill: backgroundPrimary
    readonly property color mediaControlBarDanger: danger
    readonly property color mediaControlBarCircleHoverBg: surfaceWhite08
    readonly property color mediaControlBarCircleIdleBorder: borderWhite
    readonly property color mediaControlBarSliderTrackBg: surfaceWhite16
    readonly property color mediaControlBarSliderThumbBorder: shadowBlack40
    readonly property color mediaControlBarDropActiveStrokeColor: transparent
    readonly property color mediaControlBarDropActiveFillColor: transparent
    readonly property color mediaControlBarGlassSheenTop: glassSheenTop
    readonly property color mediaControlBarGlassSheenMid: glassSheenMid
    readonly property color mediaControlBarGlassSheenCore: glassSheenCore
    readonly property color mediaControlBarGlassSheenBottom: glassSheenBottom
    readonly property color mediaControlBarGlassInnerBevel: glassInnerBevel

    // -------------------------------------------------------------------------
    // Group 11: Notifications & Notification Center
    // (notification-card.style.qml, notification-center-bar.style.qml)
    // -------------------------------------------------------------------------
    readonly property color notificationCardBackground: backgroundPrimary
    readonly property color notificationCardUrgencyCritical: danger
    readonly property color notificationCardUrgencyNormal: accent
    readonly property color notificationCardUrgencyLow: borderWhite
    readonly property color notificationCardRisingBorder: borderWhite
    readonly property color notificationCardBubbleShine: surfaceWhite75
    readonly property color notificationCardIconBadgeBg: surfaceWhite08
    readonly property color notificationCardIconBadgeBorder: surfaceWhite12
    readonly property color notificationCardSummaryText: textPrimary
    readonly property color notificationCardBodyText: textSecondary
    readonly property color notificationCardCloseTextIdle: textMuted
    readonly property color notificationCardCloseTextHover: textBright
    readonly property color notificationCardCloseBtnHoverBg: surfaceWhite12
    readonly property color notificationCardCloseBtnIdleBg: transparent
    readonly property color notificationCardGlassSheenTop: glassSheenTop
    readonly property color notificationCardGlassSheenMid: glassSheenMid
    readonly property color notificationCardGlassSheenCore: glassSheenCore
    readonly property color notificationCardGlassSheenBottom: glassSheenBottom
    readonly property color notificationCardGlassInnerBevel: glassInnerBevel
    readonly property color notificationCardGlassRimHighlight: glassRimHighlight
    readonly property color notificationCenterTextPrimary: textPrimary
    readonly property color notificationCenterTextDim: textDim
    readonly property color notificationCenterTextSecondary: textSecondary
    readonly property color notificationCenterTextSubtle: textSubtle
    readonly property color notificationCenterTextOnAccent: textOnAccent
    readonly property color notificationCenterAccent: accent
    readonly property color notificationCenterFill: backgroundPrimary
    readonly property color notificationCenterDanger: danger
    readonly property color notificationCenterDividerColor: surfaceWhite08
    readonly property color notificationCenterButtonBg: surfaceWhite06
    readonly property color notificationCenterButtonHoverBg: surfaceWhite12
    readonly property color notificationCenterButtonBorder: surfaceWhite10
    readonly property color notificationCenterDangerClampedTint: dangerClampedTint18
    readonly property color notificationCenterEmptyBellColor: surfaceWhite20
    readonly property color notificationCenterRowBg: surfaceWhite05
    readonly property color notificationCenterRowHoverBg: surfaceWhite09
    readonly property color notificationCenterRowBorder: surfaceWhite08
    readonly property color notificationCenterUrgencyLowBar: surfaceWhite25

    // -------------------------------------------------------------------------
    // Group 12: Stick Notes Bar (stick-notes-bar.style.qml)
    // -------------------------------------------------------------------------
    readonly property color stickNotesBarTextPrimary: textPrimary
    readonly property color stickNotesBarTextDim: textDim
    readonly property color stickNotesBarTextOnAccent: textOnAccent
    readonly property color stickNotesBarAccent: accent
    readonly property color stickNotesBarFill: backgroundPrimary
    readonly property color stickNotesBarDanger: danger
    readonly property color stickNotesBarCardBg: surfaceWhite07
    readonly property color stickNotesBarInputBg: surfaceWhite08
    readonly property color stickNotesBarInputBorder: surfaceWhite16
    readonly property color stickNotesBarDeleteHoverTint: dangerTint25
    readonly property color stickNotesBarAddBtnBg: surfaceWhite06
    readonly property color stickNotesBarAddBtnHoverBg: surfaceWhite12
    readonly property color stickNotesBarAddBtnBorder: surfaceWhite14
    readonly property color stickNotesBarItemRowBg: surfaceWhite09
    readonly property color stickNotesBarEditSwipeTint: editTint25
    readonly property color stickNotesBarEditSwipeIcon: editSwipeIcon
    readonly property color stickNotesBarEditInputBorder: surfaceWhite12
    readonly property color stickNotesBarTextBright: textBright

    // -------------------------------------------------------------------------
    // Group 13: Floating Windows & Detached Panels
    // (floating-window.style.qml, floating-panels.style.qml)
    // -------------------------------------------------------------------------
    readonly property color floatingWindowBackground: backgroundPrimary
    readonly property color floatingWindowAccent: accent
    readonly property color floatingWindowDanger: danger
    readonly property color floatingWindowTextPrimary: textPrimary
    readonly property color floatingWindowTextDim: textDim
    readonly property color floatingWindowBorderDragging: accentBorderDragging
    readonly property color floatingWindowBorderIdle: borderWhite
    readonly property color floatingWindowInnerGlowNearDock: accentGlowNearDock
    readonly property color floatingWindowInnerGlowIdle: surfaceWhite04
    readonly property color floatingWindowTitlebarDivider: surfaceWhite08
    readonly property color floatingWindowCloseBtnHoverBg: dangerTint20
    readonly property color floatingWindowGlassSheenTop: glassSheenTop
    readonly property color floatingWindowGlassSheenMid: glassSheenMid
    readonly property color floatingWindowGlassSheenCore: glassSheenCore
    readonly property color floatingWindowGlassSheenBottom: glassSheenBottom
    readonly property color floatingWindowGlassInnerBevel: glassInnerBevel
    readonly property color floatingWindowGlassRimHighlight: glassRimHighlight
    readonly property color floatingPanelsTextPrimary: textPrimary
    readonly property color floatingPanelsTextDim: textDim
    readonly property color floatingPanelsTextBright: textBright
    readonly property color floatingPanelsTextOnAccent: textOnAccent
    readonly property color floatingPanelsAccent: accent
    readonly property color floatingPanelsDanger: danger
    readonly property color floatingPanelsSearchBoxBg: surfaceWhite08
    readonly property color floatingPanelsSearchBoxBorder: surfaceWhite14
    readonly property color floatingPanelsItemHoverBg: surfaceWhite10
    readonly property color floatingPanelsSliderTrackBg: surfaceWhite14
    readonly property color floatingPanelsButtonBg: surfaceWhite06
    readonly property color floatingPanelsButtonHoverBg: surfaceWhite12
    readonly property color floatingPanelsButtonBorder: surfaceWhite14
    readonly property color floatingPanelsMutedTint: dangerTint18
    readonly property color floatingPanelsCardBg: surfaceWhite05
    readonly property color floatingPanelsCardBorder: surfaceWhite12
    readonly property color floatingPanelsNoteCardBg: surfaceWhite06
    readonly property color floatingPanelsNoteCardBorder: surfaceWhite10
    readonly property color floatingPanelsEditSwipeBg: editSwipeBg
    readonly property color floatingPanelsCdSurfaceBg: circleOverrideExample
    readonly property color floatingPanelsCdGrooveBorder: surfaceWhite14
    readonly property color floatingPanelsCdSpindleBg: backgroundPrimary
    readonly property color floatingPanelsCdOverlayBg: shadowBlack40
    readonly property color floatingPanelsActiveBadgeBg: accentGlowNearDock

    // -------------------------------------------------------------------------
    // Group 14: Screen Locker (screen-locker.style.qml)
    // -------------------------------------------------------------------------
    readonly property color screenLockerBackgroundColor: backgroundPrimary
    readonly property color screenLockerScrimColor: backgroundPrimary
    readonly property color screenLockerClockColor: textBright
    readonly property color screenLockerDateColor: textSecondary
    readonly property color screenLockerUserColor: textBright
    readonly property color screenLockerUserIconColor: textDim
    readonly property color screenLockerInputColor: textBright
    readonly property color screenLockerPlaceholderColor: textPlaceholder
    readonly property color screenLockerInputBorder: surfaceWhite28
    readonly property color screenLockerInputBorderFocused: borderWhite
    readonly property color screenLockerInputBorderError: danger
    readonly property color screenLockerActionColor: textSecondary
    readonly property color screenLockerActionHoverColor: textBright
    readonly property color screenLockerActionDangerHoverColor: danger

    // -------------------------------------------------------------------------
    // Group 15: Polkit Authentication Agent (polkit-agent.style.qml)
    // Controls the centered GNOME-style Polkit modal overlay, glass/solid card,
    // lock badge, user identity selector pill, password input, and action buttons.
    // -------------------------------------------------------------------------
    readonly property color polkitScrimColor: shadowBlack40
    readonly property color polkitBackground: backgroundPrimary
    readonly property color polkitBorderColor: borderWhite
    readonly property color polkitInnerGlowColor: surfaceWhite04
    readonly property color polkitGlassSheenTop: glassSheenTop
    readonly property color polkitGlassSheenMid: glassSheenMid
    readonly property color polkitGlassSheenCore: glassSheenCore
    readonly property color polkitGlassSheenBottom: glassSheenBottom
    readonly property color polkitGlassInnerBevel: glassInnerBevel
    readonly property color polkitGlassRimHighlight: glassRimHighlight
    readonly property color polkitIconBadgeBg: surfaceWhite08
    readonly property color polkitIconBadgeBorder: surfaceWhite14
    readonly property color polkitIconColor: accent
    readonly property color polkitTitleColor: textBright
    readonly property color polkitMessageColor: textSecondary
    readonly property color polkitDetailColor: textSubtle
    readonly property color polkitIdentityBg: surfaceWhite06
    readonly property color polkitIdentityHoverBg: surfaceWhite10
    readonly property color polkitIdentityBorder: surfaceWhite12
    readonly property color polkitIdentityTextColor: textPrimary
    readonly property color polkitIdentitySubTextColor: textDim
    readonly property color polkitInputBg: surfaceWhite08
    readonly property color polkitInputBorder: surfaceWhite16
    readonly property color polkitInputBorderFocused: borderWhite
    readonly property color polkitInputBorderError: danger
    readonly property color polkitInputTextColor: textBright
    readonly property color polkitInputPlaceholderColor: textPlaceholder
    readonly property color polkitErrorColor: danger
    readonly property color polkitInfoColor: textSecondary
    readonly property color polkitCancelBtnBg: surfaceWhite08
    readonly property color polkitCancelBtnHoverBg: surfaceWhite14
    readonly property color polkitCancelBtnPressedBg: surfaceWhite20
    readonly property color polkitCancelBtnBorder: surfaceWhite12
    readonly property color polkitCancelBtnText: textPrimary
    readonly property color polkitAuthBtnBg: accent
    readonly property color polkitAuthBtnHoverBg: textBright
    readonly property color polkitAuthBtnDisabledBg: surfaceWhite08
    readonly property color polkitAuthBtnText: textOnAccent
    readonly property color polkitAuthBtnDisabledText: textMuted
}
