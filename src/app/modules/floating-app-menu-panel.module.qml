// ============================================================================
// File: modules/floating-app-menu-panel.module.qml
// Purpose: Detached floating applications launcher panel with live search filtering.
// Public API:
//   - Properties: fg, dim, accent, searchQuery, allApps, filteredApps
//   - Functions:  updateFiltered()
// Dependencies: QtQuick, "../styles", QtQuick.Layouts, Quickshell, Quickshell.Widgets
// ============================================================================
import QtQuick
import "../styles"
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// Floating Application Menu panel content:
// Search box, desktop entries list, app launcher.
Item {
    id: root

    property color fg: FloatingPanelsStyle.textPrimary
    property color dim: FloatingPanelsStyle.textDim
    property color accent: FloatingPanelsStyle.accent

    property string searchQuery: ""
    property var allApps: []
    property var filteredApps: []

    function updateFiltered() {
        var q = searchQuery.toLowerCase().trim()
        if (q === "") {
            filteredApps = allApps
        } else {
            var res = []
            for (var i = 0; i < allApps.length; i++) {
                var app = allApps[i]
                var name = (app.name || "").toLowerCase()
                var desc = (app.comment || "").toLowerCase()
                if (name.indexOf(q) !== -1 || desc.indexOf(q) !== -1) {
                    res.push(app)
                }
            }
            filteredApps = res
        }
    }

    Component.onCompleted: {
        var raw = DesktopEntries.applications.values
        var valid = []
        for (var i = 0; i < raw.length; i++) {
            var a = raw[i]
            if (!a.noDisplay && a.name && a.name.trim() !== "") {
                valid.push(a)
            }
        }
        valid.sort(function(a, b) {
            return (a.name || "").localeCompare(b.name || "")
        })
        allApps = valid
        updateFiltered()
    }

    Column {
        anchors.fill: parent
        spacing: 10

        // Search Input Box
        Rectangle {
            width: parent.width
            height: FloatingPanelsStyle.searchBoxHeight
            radius: FloatingPanelsStyle.cardRadius
            color: FloatingPanelsStyle.searchBoxBg
            border.width: 1
            border.color: searchInput.activeFocus ? root.accent : FloatingPanelsStyle.searchBoxBorder

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: 30
                cursorShape: Qt.IBeamCursor
                onClicked: searchInput.forceActiveFocus()
            }

            Row {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰍉"
                    font.family: FloatingPanelsStyle.iconFont
                    font.pixelSize: FloatingPanelsStyle.searchIconFontPx
                    color: root.accent
                }

                TextInput {
                    id: searchInput
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 50
                    color: root.fg
                    font.pixelSize: FloatingPanelsStyle.searchInputFontPx
                    clip: true

                    Text {
                        anchors.fill: parent
                        text: "Type to search apps..."
                        color: root.dim
                        font.pixelSize: FloatingPanelsStyle.searchInputFontPx
                        visible: searchInput.text === "" && !searchInput.activeFocus
                    }

                    onTextChanged: {
                        root.searchQuery = text
                        root.updateFiltered()
                    }

                    onAccepted: {
                        if (root.filteredApps.length > 0) {
                            root.filteredApps[0].execute()
                        }
                    }

                    Keys.onEscapePressed: {
                        if (text !== "") {
                            text = ""
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✕"
                    color: root.dim
                    font.pixelSize: 12
                    visible: searchInput.text !== ""
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { searchInput.text = "" }
                    }
                }
            }
        }

        // Applications List
        ListView {
            id: appListView
            width: parent.width
            height: parent.height - 46
            clip: true
            spacing: 4
            model: root.filteredApps

            delegate: Rectangle {
                id: appItem
                required property var modelData
                required property int index

                width: appListView.width
                height: FloatingPanelsStyle.appRowHeight
                radius: FloatingPanelsStyle.cardRadius
                color: itemMouse.containsMouse ? FloatingPanelsStyle.itemHoverBg : FloatingPanelsStyle.transparent

                // App Name & Comment
                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: appItem.modelData.name || ""
                        color: itemMouse.containsMouse ? root.accent : root.fg
                        font.pixelSize: FloatingPanelsStyle.appTitleFontPx
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        width: parent.width
                    }

                    Text {
                        text: appItem.modelData.comment || appItem.modelData.genericName || ""
                        color: root.dim
                        font.pixelSize: FloatingPanelsStyle.appCommentFontPx
                        elide: Text.ElideRight
                        width: parent.width
                        visible: text !== ""
                    }
                }

                MouseArea {
                    id: itemMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        appItem.modelData.execute()
                    }
                }
            }
        }
    }
}
