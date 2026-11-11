// ============================================================================
// File: modules/notifications-service.module.qml
// Purpose: org.freedesktop.Notifications D-Bus server service tracking notification history and Do-Not-Disturb state.
// Public API:
//   - Properties: muted, history, defaultTimeoutMs, criticalTimeoutMs, maxVisibleCount, server
//   - Signals:    notificationReceived(var notification), cleared()
//   - Functions:  applyConfig(text), toggleMute(), clearAll(), removeById(id)
// Dependencies: Quickshell, Quickshell.Io, Quickshell.Services.Notifications, QtQuick
// ============================================================================
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "../components/service-parsers.js" as ServiceParsers

// Desktop notification server service binding to org.freedesktop.Notifications.
// Configuration comes from config/notifications.config.json.
Item {
    id: root

    signal notificationReceived(var notification)
    signal cleared()
    signal popupsSuppressed()

    property bool muted: false
    property bool suppressPopups: false
    property var history: []
    property int defaultTimeoutMs: 5000
    property int criticalTimeoutMs: 8000
    property int maxVisibleCount: 4

    onSuppressPopupsChanged: {
        if (root.suppressPopups) {
            root.popupsSuppressed()
        }
    }

    readonly property var groupedHistory: {
        var groups = []
        var map = {}
        for (var i = 0; i < root.history.length; i++) {
            var it = root.history[i]
            var key = it.originKey || (it.appName || it.desktopEntry || it.appIcon || "Notification").toLowerCase()
            if (map[key] === undefined) {
                var grp = {
                    originKey: key,
                    appName: it.appName || it.desktopEntry || "Notification",
                    appIcon: it.appIcon || "",
                    image: it.image || "",
                    urgency: it.urgency !== undefined ? it.urgency : 1,
                    latestTime: it.time,
                    items: [it]
                }
                map[key] = groups.length
                groups.push(grp)
            } else {
                var existing = groups[map[key]]
                existing.items.push(it)
                if (it.urgency > existing.urgency) {
                    existing.urgency = it.urgency
                }
            }
        }
        return groups
    }

    readonly property alias server: notifServer

    function applyConfig(text) {
        var parsed = ServiceParsers.parseNotificationsConfig(text, root)
        root.defaultTimeoutMs = parsed.defaultTimeoutMs
        root.criticalTimeoutMs = parsed.criticalTimeoutMs
        root.maxVisibleCount = parsed.maxVisibleCount
    }

    FileView {
        id: configFile
        path: Quickshell.shellPath("config/notifications.config.json")
        watchChanges: true
        onFileChanged: configFile.reload()
        onLoaded: root.applyConfig(configFile.text())
    }

    function toggleMute() {
        root.muted = !root.muted
    }

    function clearAll() {
        root.history = []
        root.cleared()
    }

    function removeById(id) {
        var list = []
        for (var i = 0; i < root.history.length; i++) {
            var it = root.history[i]
            if (it.id === id) {
                if (it.notificationRef) {
                    try { it.notificationRef.dismiss() } catch (e) {}
                }
            } else {
                list.push(it)
            }
        }
        root.history = list
    }

    function removeGroupByOrigin(originKey) {
        var list = []
        var target = String(originKey || "").toLowerCase()
        for (var i = 0; i < root.history.length; i++) {
            var it = root.history[i]
            var key = it.originKey || (it.appName || it.desktopEntry || it.appIcon || "Notification").toLowerCase()
            if (key === target) {
                if (it.notificationRef) {
                    try { it.notificationRef.dismiss() } catch (e) {}
                }
            } else {
                list.push(it)
            }
        }
        root.history = list
    }

    Process {
        id: focusAppProc
    }

    function activateNotification(itemOrNotif) {
        if (!itemOrNotif) return
        var notifObj = itemOrNotif.notificationRef ? itemOrNotif.notificationRef : itemOrNotif
        if (notifObj && notifObj.actions) {
            var acts = notifObj.actions
            var count = (typeof acts.length === "number") ? acts.length : (acts.count !== undefined ? acts.count : 0)
            var defAct = null
            for (var i = 0; i < count; i++) {
                var act = acts[i] || (acts.at ? acts.at(i) : null)
                if (act && act.identifier === "default") {
                    defAct = act
                    break
                }
            }
            if (!defAct && count > 0) {
                defAct = acts[0] || (acts.at ? acts.at(0) : null)
            }
            if (defAct && typeof defAct.invoke === "function") {
                try {
                    defAct.invoke()
                } catch (e) {}
            }
        }

        var appName = itemOrNotif.appName || (notifObj ? (notifObj.appName || "") : "")
        var desktopEntry = itemOrNotif.desktopEntry || (notifObj ? (notifObj.desktopEntry || "") : "")
        var appIcon = itemOrNotif.appIcon || (notifObj ? (notifObj.appIcon || "") : "")
        if (appName || desktopEntry || appIcon) {
            focusAppProc.running = false
            focusAppProc.command = ["sh", Quickshell.shellPath("src/app/scripts/notifications/focus-notification-app.sh"), String(appName), String(desktopEntry), String(appIcon)]
            focusAppProc.running = true
        }
    }

    // Automatically unseat competing daemons (swaync, mako, dunst) so Quickshell claims the bus
    Process {
        id: procReleaseBus
        command: ["sh", Quickshell.shellPath("src/app/scripts/notifications/claim-notification-bus.sh")]
        running: true
    }

    NotificationServer {
        id: notifServer
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        persistenceSupported: true

        onNotification: (notification) => {
            notification.tracked = true

            var rawOrigin = notification.appName || notification.desktopEntry || notification.appIcon || "Notification"
            // Store in history for Notification Center
            var item = {
                id: notification.id,
                summary: ServiceParsers.cleanNotificationText(notification.summary || ""),
                body: ServiceParsers.cleanNotificationText(notification.body || ""),
                appName: notification.appName || notification.desktopEntry || "Notification",
                desktopEntry: notification.desktopEntry || "",
                appIcon: notification.appIcon || "",
                image: notification.image || "",
                originKey: String(rawOrigin).toLowerCase(),
                urgency: (notification.urgency !== undefined) ? notification.urgency : 1,
                time: new Date(),
                notificationRef: notification
            }
            var list = root.history.slice(0)
            list.unshift(item)
            root.history = list

            // Only display on-screen popups if not muted and Notification Center is not open
            if (!root.muted && !root.suppressPopups) {
                root.notificationReceived(notification)
            }
        }
    }
}
