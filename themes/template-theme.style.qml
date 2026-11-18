// ============================================================================
// File: themes/template-theme.style.qml
// Purpose: Fully documented Solid Color theme template exposing every global and component color token.
// Public API: TemplateTheme singleton (copy to e.g. themes/my-theme.style.qml and register as Theme in themes/qmldir).
// Dependencies: QtQuick
// ============================================================================
// HOW TO CREATE AND ACTIVATE A CUSTOM THEME
//
// 1. Copy this file to e.g. `themes/my-solid-theme.style.qml`.
// 2. To activate your theme across the entire shell, edit `themes/qmldir`:
//       singleton Theme 1.0 my-solid-theme.style.qml
//    (All `src/app/styles/*.style.qml` files read exclusively from `Theme`.)
// 3. SOLID vs LIQUID GLASS MODE:
//    - Solid Color Theme (default in this template):
//      Use opaque `#RRGGBB` colors for `backgroundPrimary`, `backgroundBlack`,
//      `weatherPanelSurface`, `borderWhite`, and `surfaceWhite*`, and leave all
//      6 `glassSheen*` / `glassInnerBevel` / `glassRimHighlight` tokens as
//      `Qt.rgba(0.0, 0.0, 0.0, 0.0)` so glass overlays and bevels disappear.
//    - Liquid Glass / Translucent Theme:
//      Set `backgroundPrimary` / `backgroundBlack` to translucent `Qt.rgba(r, g, b, alpha)`
//      and restore non-zero alpha highlights on `glassSheenTop..Bottom`,
//      `glassInnerBevel`, and `glassRimHighlight`.
// 4. GLOBAL vs PER-COMPONENT EDITING:
//    - Editing Section A ("GLOBAL BASE TOKENS") re-themes every component at once.
//    - Editing Section B ("COMPONENT OVERRIDE GROUPS 1-14") overrides individual
//      panels, bars, cards, buttons, sliders, or notifications independently.
// 5. Validation: run `make test` after editing; Qt/Python tests verify parity with `glass-theme.style.qml`.
// ============================================================================
pragma Singleton
import QtQuick

QtObject {
    // =========================================================================
    // SECTION A: GLOBAL BASE TOKENS
    // =========================================================================

    // --- Core Backgrounds & Transparent Sentinel ---
    // Main panel/drawer background used across islands, sidebars, menus, notification cards, and locker
    readonly property color backgroundPrimary: "#111318"
    // Deeper outer drop/shape fill used behind bars, edge strips, and container drops
    readonly property color backgroundBlack: "#0b0d12"
    // Embedded weather summary card container background inside the Calendar panel
    readonly property color weatherPanelSurface: "#171a22"
    // Alternative dark surface (also used for the detached Media vinyl CD surface)
    readonly property color circleOverrideExample: "#181c26"
    // Required transparent sentinel used for invisible strokes, idle close buttons, and PanelWindow clears
    readonly property color transparent: "transparent"

    // --- Text Hierarchy & Borders ---
    // Primary readable foreground text (titles, labels, clock, main items)
    readonly property color textPrimary: "#eef0f4"
    // Highest-contrast text & hover emphasis (hovered sort labels, focused locker input, close icons)
    readonly property color textBright: "#ffffff"
    // Primary 1px crisp borders on circles, cards, drop outlines, and focused inputs
    readonly property color borderWhite: "#2b3040"
    // Secondary descriptive body text (notifications body copy, dates, weather details)
    readonly property color textSecondary: "#c4c9d4"
    // Muted labels, timestamps, inactive glyphs, and metadata
    readonly property color textDim: "#8f96a6"
    // De-emphasized metadata & other-month calendar day numbers
    readonly property color textMuted: "#6c7385"
    // Input placeholder text (AppMenu search box, ScreenLocker password hint)
    readonly property color textPlaceholder: "#5b6273"
    // Faintest status labels & empty-state sub-labels
    readonly property color textSubtle: "#484e5e"
    // Text/icon color rendered ON TOP of an `accent`-colored badge, today pill, or active tile
    readonly property color textOnAccent: "#0b0d12"

    // --- Semantic Accents, Danger & Swipe Actions ---
    // Primary highlight accent (active workspace, today pill, focused icons, interactive highlights)
    readonly property color accent: "#7aa2f7"
    // Error/critical indicator (urgent workspace, critical notification bar, mute/delete/power danger)
    readonly property color danger: "#f7768e"
    // Floating stick-note edit swipe reveal background
    readonly property color editSwipeBg: "#7aa2f7"
    // Icon ink drawn inside the stick-note edit swipe reveal
    readonly property color editSwipeIcon: "#0b0d12"

    // --- Elevated Surface & Hover Steps (low -> high contrast) ---
    // In a Solid theme these form opaque stepped surfaces/borders instead of white-alpha washes.
    // Very faint inner glow / divider wash (idle FloatingWindow inner glow, AppMenu row dividers, empty tiles)
    readonly property color surfaceWhite04: "#141720"
    readonly property color surfaceWhite05: "#161a24"
    // Subtle card fill & hover rows (events cards, weather cards, search box, action buttons, AppMenu row hover)
    readonly property color surfaceWhite06: "#191d28"
    readonly property color surfaceWhite07: "#1b202c"
    // Input fields, secondary tracks, subtle dividers, circle hover backgrounds, icon badge fill
    readonly property color surfaceWhite08: "#1e2330"
    readonly property color surfaceWhite09: "#212736"
    // Card hover fills, search box borders, selected location row, perf graph fill
    readonly property color surfaceWhite10: "#242a3b"
    // Selected menu rows, occupied workspace tiles, calendar hover circle, notification/hover buttons
    readonly property color surfaceWhite12: "#293042"
    // Track backgrounds, card borders, add-button borders, CD groove ring
    readonly property color surfaceWhite14: "#2e364a"
    // Slider tracks & StickNotes input border
    readonly property color surfaceWhite16: "#333c52"
    // Hovered workspace tiles, calendar selected day ring, scrollbars, empty bell icon
    readonly property color surfaceWhite20: "#3b455e"
    // Drag handles, low-urgency notification stripe, perf row hover
    readonly property color surfaceWhite25: "#46516e"
    // ScreenLocker idle password field border
    readonly property color surfaceWhite28: "#525e7d"
    // Unused ramp step kept for full token compatibility with glass themes
    readonly property color surfaceWhite45: "#7884a6"
    // Specular bubble shine bar on rising notification bubbles
    readonly property color surfaceWhite75: "#b4bed8"

    // --- Shadows, Drag Glows & Status Tints ---
    // Slider thumb outline & CD center overlay dim
    readonly property color shadowBlack40: Qt.rgba(0.0, 0.0, 0.0, 0.45)
    // FloatingWindow outline while actively dragging
    readonly property color accentBorderDragging: "#9ece6a"
    // FloatingWindow dock-snap inner glow & active detached tab highlight badge
    readonly property color accentGlowNearDock: Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.35)
    // Muted audio toggle tint in floating audio panel
    readonly property color dangerTint18: Qt.rgba(247 / 255, 118 / 255, 142 / 255, 0.18)
    // FloatingWindow close button hover background
    readonly property color dangerTint20: Qt.rgba(247 / 255, 118 / 255, 142 / 255, 0.25)
    // Circle danger hover & StickNotes delete-swipe hover tint
    readonly property color dangerTint25: Qt.rgba(247 / 255, 118 / 255, 142 / 255, 0.32)
    // NotificationCenter muted/DND clamped tint fill
    readonly property color dangerClampedTint18: Qt.rgba(229 / 255, 72 / 255, 77 / 255, 0.18)
    // StickNotes edit-swipe tint overlay
    readonly property color editTint25: Qt.rgba(122 / 255, 162 / 255, 247 / 255, 0.40)

    // --- Liquid Glass Specular / Bevel Highlights ---
    // Set to 0-alpha for a crisp Solid Color theme; raise alpha to re-enable Liquid Glass sheen.
    readonly property color glassSheenTop: Qt.rgba(0.0, 0.0, 0.0, 0.0)
    readonly property color glassSheenMid: Qt.rgba(0.0, 0.0, 0.0, 0.0)
    readonly property color glassSheenCore: Qt.rgba(0.0, 0.0, 0.0, 0.0)
    readonly property color glassSheenBottom: Qt.rgba(0.0, 0.0, 0.0, 0.0)
    readonly property color glassInnerBevel: Qt.rgba(0.0, 0.0, 0.0, 0.0)
    readonly property color glassRimHighlight: Qt.rgba(0.0, 0.0, 0.0, 0.0)

    // --- Sticky Note Color Tag Palette (shared by StickNotesBar & FloatingStickNotesPanel) ---
    readonly property color paletteBlue: "#0a84ff"
    readonly property color paletteOrange: "#ff9f0a"
    readonly property color paletteRed: "#ff453a"
    readonly property color paletteYellow: "#ffd60a"
    readonly property color paletteGreen: "#30d158"
    readonly property color paletteCyan: "#64d2ff"
    readonly property color palettePurple: "#bf5af2"
    readonly property color palettePink: "#ff375f"

    // =========================================================================
    // SECTION B: COMPONENT OVERRIDE GROUPS
    // =========================================================================

    // -------------------------------------------------------------------------
    // Group 1: Base Drops & Edge Strips (drop.style.qml, strip.style.qml)
    // Controls the curved Bar/Island/Drawer backdrops (`Drop`) and top/side
    // collapsed trigger strips (`Strip`).
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
    // Group 2: Top Islands, Middle Clock & Panel Placeholder
    // (island.style.qml, middle-bar.style.qml, panel-placeholder.style.qml)
    // Controls top island pill fills/text, center clock digits, and placeholder views.
    // -------------------------------------------------------------------------
    readonly property color islandFill: backgroundPrimary
    readonly property color islandTextPrimary: textPrimary
    readonly property color islandTextDim: textDim
    readonly property color islandAccent: accent
    readonly property color middleBarTextPrimary: textPrimary
    readonly property color panelPlaceholderTextColor: textDim

    // -------------------------------------------------------------------------
    // Group 3: Workspace Switcher & Central Grid
    // (workspace-island.style.qml, workspace-central.style.qml)
    // Controls the top-right workspace pill and the fullscreen/expanded workspace tile grid.
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
    // Controls side launcher circles (Wi-Fi, Bluetooth, Power, etc.) and their flyout items.
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
    // Controls TopLeft/TopRight hover wings, CPU/RAM/Temp gauges, and sparkline graph cards.
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
    // Controls the Calendar popup divider, month day cells, today/selected circles, and ICS event cards.
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
    // Group 7: Weather (weather-card.style.qml, weather-view.style.qml, location-picker.style.qml)
    // Controls the compact Weather summary card, full Weather forecast view, and city picker.
    // Note: in Solid mode, `weatherCardBorderColor` uses `surfaceWhite12` so cards remain outlined
    // even when `glassInnerBevel` is transparent.
    // -------------------------------------------------------------------------
    readonly property color weatherCardTextPrimary: textPrimary
    readonly property color weatherCardTextDim: textDim
    readonly property color weatherCardColor: surfaceWhite06
    readonly property color weatherCardHoverColor: surfaceWhite10
    readonly property color weatherCardBorderColor: surfaceWhite12
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
    // Controls the bottom/left AppLauncher bar, tray dots/circles, and context menu colors.
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
    // Controls the searchable AppMenu / Clipboard popup, search input, list rows, and sort footer.
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
    // Group 10: Media Control Bar & Volume Slider (media-control-bar.style.qml)
    // Controls the MPRIS media/volume bar, transport circles, and volume slider track/thumb.
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
    // Controls floating notification toast bubbles and the expandable Notification Center drawer.
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
    // Controls the right-edge Stick Notes trigger, creation box, note cards, and swipe actions.
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
    // Controls detached FloatingWindow chrome/borders and the detached App/Audio/Media/Notes views.
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
    // Controls the lock screen overlay, clock/date typography, password input states, and power actions.
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
