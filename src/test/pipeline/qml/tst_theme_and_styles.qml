import QtQuick
import QtTest
import "../../../../themes"
import "../../../app/styles"

TestCase {
    name: "ThemeAndStylesTests"

    function verifyColor(c, label) {
        verify(c !== undefined && c !== null, label + " must be defined")
        verify(c.a >= 0.0 && c.a <= 1.0, label + " alpha in [0, 1]")
        verify(c.r >= 0.0 && c.r <= 1.0, label + " red in [0, 1]")
        verify(c.g >= 0.0 && c.g <= 1.0, label + " green in [0, 1]")
        verify(c.b >= 0.0 && c.b <= 1.0, label + " blue in [0, 1]")
    }

    function verifyNonNegativeFinite(val, label) {
        verify(typeof val === "number" && isFinite(val), label + " must be finite number")
        verify(val >= 0, label + " must be >= 0 (got " + val + ")")
    }

    function verifyStyleObject(obj, objName) {
        verify(obj !== undefined && obj !== null, objName + " singleton must load")
        var keys = Object.keys(obj)
        var checked = 0
        for (var i = 0; i < keys.length; i++) {
            var k = keys[i]
            if (k === "objectName" || k.indexOf("Changed") !== -1) continue
            var v = obj[k]
            if (typeof v === "function") continue
            if (typeof v === "number") {
                verify(isFinite(v), objName + "." + k + " must be finite")
                if (k.indexOf("detachThreshold") === -1) {
                    verifyNonNegativeFinite(v, objName + "." + k)
                }
                checked++
            } else if (typeof v === "object" && v !== null && v.r !== undefined && v.a !== undefined) {
                verifyColor(v, objName + "." + k)
                checked++
            }
        }
        verify(checked > 0, objName + " must expose at least 1 style property")
    }

    function test_theme_colors_valid() {
        verifyStyleObject(Theme, "Theme")
        verifyStyleObject(GlassTheme, "GlassTheme")
        verifyStyleObject(DefaultTheme, "DefaultTheme")
        verifyColor(Theme.transparent, "Theme.transparent")
        compare(Theme.transparent.a, 0.0)
        verifyColor(Theme.backgroundPrimary, "Theme.backgroundPrimary")
        verifyColor(Theme.backgroundBlack, "Theme.backgroundBlack")
        verifyColor(Theme.weatherPanelSurface, "Theme.weatherPanelSurface")
        verifyColor(Theme.textPrimary, "Theme.textPrimary")
        verifyColor(Theme.textBright, "Theme.textBright")
        verifyColor(Theme.textSecondary, "Theme.textSecondary")
        verifyColor(Theme.textDim, "Theme.textDim")
        verifyColor(Theme.textMuted, "Theme.textMuted")
        verifyColor(Theme.textOnAccent, "Theme.textOnAccent")
        verifyColor(Theme.accent, "Theme.accent")
        verifyColor(Theme.danger, "Theme.danger")
        verifyColor(Theme.dangerClampedTint18, "Theme.dangerClampedTint18")

        // Specific glass theme translucency and Liquid Glass optical assertions
        verify(GlassTheme.backgroundPrimary.a < 1.0, "GlassTheme backgroundPrimary must be translucent")
        verify(GlassTheme.backgroundBlack.a < 1.0, "GlassTheme backgroundBlack must be translucent")
        verify(GlassTheme.borderWhite.a < 1.0, "GlassTheme borderWhite must be a translucent specular rim")
        verify(GlassTheme.glassSheenTop.a > 0.25, "GlassTheme glassSheenTop must have strong top specular sheen")
        verify(GlassTheme.glassSheenBottom.a > 0.15, "GlassTheme glassSheenBottom must have caustic bottom reflection")
        verify(GlassTheme.glassInnerBevel.a > 0.15, "GlassTheme glassInnerBevel must have 3D inner bevel glow")
        verify(GlassTheme.glassRimHighlight.a > 0.50, "GlassTheme glassRimHighlight must have bright top crest highlight")
        compare(DefaultTheme.glassSheenTop.a, 0.0, "DefaultTheme glassSheenTop must be transparent so pitch-black theme is unchanged")
        compare(DefaultTheme.glassInnerBevel.a, 0.0, "DefaultTheme glassInnerBevel must be transparent")
    }

    function test_all_24_style_singletons() {
        var singletons = [
            [DropStyle, "DropStyle"],
            [StripStyle, "StripStyle"],
            [IslandStyle, "IslandStyle"],
            [SideBarStyle, "SideBarStyle"],
            [CircleStyle, "CircleStyle"],
            [MiddleBarStyle, "MiddleBarStyle"],
            [WorkspaceIslandStyle, "WorkspaceIslandStyle"],
            [MonthGridStyle, "MonthGridStyle"],
            [EventsListStyle, "EventsListStyle"],
            [LocationPickerStyle, "LocationPickerStyle"],
            [WeatherCardStyle, "WeatherCardStyle"],
            [WeatherViewStyle, "WeatherViewStyle"],
            [CalendarPanelStyle, "CalendarPanelStyle"],
            [WorkspaceCentralStyle, "WorkspaceCentralStyle"],
            [PanelPlaceholderStyle, "PanelPlaceholderStyle"],
            [NotificationCardStyle, "NotificationCardStyle"],
            [NotificationOverlayStyle, "NotificationOverlayStyle"],
            [NotificationCenterBarStyle, "NotificationCenterBarStyle"],
            [AppLauncherStyle, "AppLauncherStyle"],
            [AppMenuStyle, "AppMenuStyle"],
            [MediaControlBarStyle, "MediaControlBarStyle"],
            [StickNotesBarStyle, "StickNotesBarStyle"],
            [FloatingWindowStyle, "FloatingWindowStyle"],
            [FloatingPanelsStyle, "FloatingPanelsStyle"],
            [ScreenLockerStyle, "ScreenLockerStyle"]
        ]
        compare(singletons.length, 25)
        for (var i = 0; i < singletons.length; i++) {
            verifyStyleObject(singletons[i][0], singletons[i][1])
        }
    }
}
