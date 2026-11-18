// ============================================================================
// File: components/polkit-dialog.component.qml
// Purpose: GNOME-style modal Polkit authentication card supporting Liquid Glass and Solid themes.
// Public API:
//   - Properties: flow, active, fallbackUserName, passwordText, revealPassword, hasError, inputField
//   - Signals:    submitRequested(string password), cancelRequested()
//   - Functions:  focusInput(), submitPassword(), cancelAuth(), cycleIdentity()
// Dependencies: QtQuick, QtQuick.Layouts, "../styles"
// ============================================================================
import QtQuick
import QtQuick.Layouts
import "../styles"

Item {
    id: root

    property var flow: null
    property bool active: false
    property string fallbackUserName: ""
    property string passwordText: ""
    property bool revealPassword: false
    property bool hasError: false
    property bool isAuthenticating: false
    property bool pendingSubmit: false
    property string pendingSubmitValue: ""

    property alias inputField: passwordInput

    signal submitRequested(string password)
    signal cancelRequested()

    implicitWidth: PolkitAgentStyle.dialogWidth
    implicitHeight: card.height
    width: PolkitAgentStyle.dialogWidth
    height: card.height

    scale: root.active ? 1.0 : PolkitAgentStyle.closedScale
    opacity: root.active ? 1.0 : 0.0
    transformOrigin: Item.Center

    Behavior on opacity { NumberAnimation { duration: PolkitAgentStyle.fadeDurationMs; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: PolkitAgentStyle.scaleDurationMs; easing.type: Easing.OutBack } }

    readonly property var currentIdentity: {
        if (!root.flow) return null
        if (root.flow.selectedIdentity) return root.flow.selectedIdentity
        if (root.flow.identities && root.flow.identities.length > 0) return root.flow.identities[0]
        return null
    }

    readonly property string identityPrimaryText: {
        if (root.currentIdentity && root.currentIdentity.displayName && String(root.currentIdentity.displayName).length > 0) {
            return String(root.currentIdentity.displayName)
        }
        if (root.currentIdentity && root.currentIdentity.id && String(root.currentIdentity.id).length > 0) {
            return String(root.currentIdentity.id)
        }
        return root.fallbackUserName.length > 0 ? root.fallbackUserName : "Administrator"
    }

    readonly property string identitySecondaryText: {
        if (!root.currentIdentity) return ""
        var dName = root.currentIdentity.displayName ? String(root.currentIdentity.displayName) : ""
        var uid = root.currentIdentity.id ? String(root.currentIdentity.id) : ""
        if (dName.length > 0 && uid.length > 0 && dName !== uid) {
            return "(" + uid + ")"
        }
        return ""
    }

    readonly property bool hasMultipleIdentities: !!(root.flow && root.flow.identities && root.flow.identities.length > 1)

    readonly property string promptPlaceholder: {
        var raw = (root.flow && root.flow.inputPrompt) ? String(root.flow.inputPrompt).trim() : ""
        var cleaned = raw.replace(/:\s*$/, "").trim()
        return cleaned.length > 0 ? cleaned : "Password"
    }

    readonly property string statusText: {
        if (root.isAuthenticating) return ""
        if (root.flow && root.flow.supplementaryMessage) {
            var msg = String(root.flow.supplementaryMessage).trim()
            if (msg.length > 0) return msg
        }
        if (root.hasError || (root.flow && root.flow.failed)) {
            return "Authentication failed. Please try again."
        }
        return ""
    }

    readonly property bool statusIsError: !root.isAuthenticating && !!(root.hasError || (root.flow && (root.flow.failed || root.flow.supplementaryIsError)))

    readonly property bool canSubmit: !root.isAuthenticating && root.passwordText.length > 0 && (!root.flow || !root.flow.isCompleted)

    function focusInput() {
        if (root.active && !root.isAuthenticating) {
            passwordInput.forceActiveFocus()
        }
    }

    function submitPassword() {
        if (root.isAuthenticating || root.passwordText.length === 0) {
            root.focusInput()
            return
        }
        if (root.flow && root.flow.isCompleted) return

        root.hasError = false
        root.isAuthenticating = true
        var submitted = root.passwordText
        root.submitRequested(submitted)
        if (root.flow && typeof root.flow.submit === "function") {
            if (root.flow.isResponseRequired === false) {
                root.pendingSubmitValue = submitted
                root.pendingSubmit = true
            } else {
                root.pendingSubmit = false
                root.pendingSubmitValue = ""
                root.flow.submit(submitted)
            }
        }
        root.passwordText = ""
    }

    function cancelAuth() {
        root.isAuthenticating = false
        root.pendingSubmit = false
        root.pendingSubmitValue = ""
        root.passwordText = ""
        root.hasError = false
        root.revealPassword = false
        root.cancelRequested()
        if (root.flow && typeof root.flow.cancelAuthenticationRequest === "function") {
            root.flow.cancelAuthenticationRequest()
        }
    }

    function cycleIdentity() {
        if (root.isAuthenticating) return
        if (!root.flow || !root.flow.identities || root.flow.identities.length <= 1) return
        var list = root.flow.identities
        var current = root.flow.selectedIdentity
        var curIdx = 0
        for (var i = 0; i < list.length; i++) {
            if (list[i] === current || (current && list[i] && list[i].id === current.id)) {
                curIdx = i
                break
            }
        }
        var nextIdx = (curIdx + 1) % list.length
        root.flow.selectedIdentity = list[nextIdx]
        root.isAuthenticating = false
        root.passwordText = ""
        root.hasError = false
        root.pendingSubmit = false
        root.pendingSubmitValue = ""
        root.focusInput()
    }

    Timer {
        id: focusTimer
        interval: 16
        repeat: false
        onTriggered: root.focusInput()
    }

    onActiveChanged: {
        if (root.active) {
            root.isAuthenticating = false
            root.passwordText = ""
            root.hasError = !!(root.flow && root.flow.failed)
            root.revealPassword = false
            root.pendingSubmit = false
            root.pendingSubmitValue = ""
            root.focusInput()
            focusTimer.restart()
        } else {
            focusTimer.stop()
            root.isAuthenticating = false
            root.pendingSubmit = false
            root.pendingSubmitValue = ""
            root.passwordText = ""
            root.hasError = false
            root.revealPassword = false
        }
    }

    onFlowChanged: {
        root.isAuthenticating = false
        root.passwordText = ""
        root.hasError = !!(root.flow && root.flow.failed)
        root.revealPassword = false
        root.pendingSubmit = false
        root.pendingSubmitValue = ""
        if (root.active) {
            root.focusInput()
            focusTimer.restart()
        }
    }

    onIsAuthenticatingChanged: {
        if (!root.isAuthenticating && root.active) {
            root.focusInput()
            focusTimer.restart()
        }
    }

    Connections {
        target: root.flow
        ignoreUnknownSignals: true

        function onFailedChanged() {
            if (root.flow && root.flow.failed) {
                root.isAuthenticating = false
                root.hasError = true
                root.passwordText = ""
                root.focusInput()
                focusTimer.restart()
            }
        }

        function onAuthenticationFailed() {
            root.isAuthenticating = false
            root.hasError = true
            root.passwordText = ""
            root.focusInput()
            focusTimer.restart()
        }

        function onIsResponseRequiredChanged() {
            if (!root.flow || !root.flow.isResponseRequired) return
            if (root.pendingSubmit && typeof root.flow.submit === "function") {
                var value = root.pendingSubmitValue
                root.pendingSubmit = false
                root.pendingSubmitValue = ""
                root.flow.submit(value)
            } else {
                root.isAuthenticating = false
                root.focusInput()
                focusTimer.restart()
            }
        }

        function onSupplementaryIsErrorChanged() {
            if (root.flow && root.flow.supplementaryIsError) {
                root.isAuthenticating = false
                root.hasError = true
                root.focusInput()
                focusTimer.restart()
            }
        }
    }

    Rectangle {
        id: card
        width: root.width
        height: contentCol.implicitHeight + PolkitAgentStyle.dialogPadding * 2
        radius: PolkitAgentStyle.dialogRadius
        color: PolkitAgentStyle.background
        border.width: 1
        border.color: PolkitAgentStyle.borderColor

        // Prevent backdrop clicks from bubbling out of the modal dialog card
        MouseArea {
            anchors.fill: parent
            onPressed: function(mouse) {
                mouse.accepted = true
                root.focusInput()
            }
        }

        // Subtle outer glow / elevation highlight
        Rectangle {
            anchors.fill: parent
            anchors.margins: -1
            radius: PolkitAgentStyle.dialogRadius + 1
            color: PolkitAgentStyle.transparent
            border.width: 1
            border.color: PolkitAgentStyle.innerGlowColor
        }

        // Liquid Glass multi-stop refractive sheen (transparent in Solid Color themes)
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, PolkitAgentStyle.dialogRadius - 1)
            gradient: Gradient {
                GradientStop { position: 0.0; color: PolkitAgentStyle.glassSheenTop }
                GradientStop { position: 0.18; color: PolkitAgentStyle.glassSheenMid }
                GradientStop { position: 0.78; color: PolkitAgentStyle.glassSheenCore }
                GradientStop { position: 1.0; color: PolkitAgentStyle.glassSheenBottom }
            }
        }

        // 3D inner refractive bevel ring
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: Math.max(0, PolkitAgentStyle.dialogRadius - 1)
            color: PolkitAgentStyle.transparent
            border.width: 1.5
            border.color: PolkitAgentStyle.glassInnerBevel
        }

        // Top specular crest highlight
        Rectangle {
            width: Math.max(0, parent.width - PolkitAgentStyle.dialogRadius * 1.6)
            height: 1.0
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 1.5
            color: PolkitAgentStyle.glassRimHighlight
        }

        ColumnLayout {
            id: contentCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: PolkitAgentStyle.dialogPadding
            spacing: PolkitAgentStyle.contentSpacing

            // ── Shield / Lock Icon Badge ──
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: PolkitAgentStyle.iconBadgeSize
                height: PolkitAgentStyle.iconBadgeSize
                radius: PolkitAgentStyle.iconBadgeRadius
                color: PolkitAgentStyle.iconBadgeBg
                border.width: 1
                border.color: PolkitAgentStyle.iconBadgeBorder

                Text {
                    anchors.centerIn: parent
                    text: "󰌾"
                    font.family: PolkitAgentStyle.iconFont
                    font.pixelSize: PolkitAgentStyle.iconFontPx
                    color: PolkitAgentStyle.iconColor
                }
            }

            // ── GNOME-style Header & Action Prompt ──
            Text {
                Layout.fillWidth: true
                text: "Authentication Required"
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.pixelSize: PolkitAgentStyle.titleFontPx
                font.weight: Font.Bold
                color: PolkitAgentStyle.titleColor
            }

            Text {
                Layout.fillWidth: true
                text: (root.flow && root.flow.message) ? String(root.flow.message) : "Authentication is needed to perform this action."
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.pixelSize: PolkitAgentStyle.messageFontPx
                color: PolkitAgentStyle.messageColor
            }

            Text {
                Layout.fillWidth: true
                visible: text.length > 0
                text: (root.flow && root.flow.actionId) ? String(root.flow.actionId) : ""
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideMiddle
                font.pixelSize: PolkitAgentStyle.detailFontPx
                color: PolkitAgentStyle.detailColor
            }

            // ── User Identity Pill (cycles multiple identities when available) ──
            Rectangle {
                id: identityPill
                Layout.fillWidth: true
                height: PolkitAgentStyle.identityHeight
                radius: PolkitAgentStyle.identityRadius
                color: (identityMa.containsMouse && root.hasMultipleIdentities) ? PolkitAgentStyle.identityHoverBg : PolkitAgentStyle.identityBg
                border.width: 1
                border.color: PolkitAgentStyle.identityBorder
                Behavior on color { ColorAnimation { duration: PolkitAgentStyle.colorAnimDurationMs } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    Text {
                        text: ""
                        font.family: PolkitAgentStyle.iconFont
                        font.pixelSize: PolkitAgentStyle.identityFontPx
                        color: PolkitAgentStyle.identitySubTextColor
                    }

                    Text {
                        text: root.identityPrimaryText
                        font.pixelSize: PolkitAgentStyle.identityFontPx
                        font.weight: Font.DemiBold
                        color: PolkitAgentStyle.identityTextColor
                        elide: Text.ElideRight
                        Layout.fillWidth: root.identitySecondaryText.length === 0
                    }

                    Text {
                        visible: root.identitySecondaryText.length > 0
                        text: root.identitySecondaryText
                        font.pixelSize: PolkitAgentStyle.identityFontPx
                        color: PolkitAgentStyle.identitySubTextColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: root.hasMultipleIdentities
                        text: "󰅀"
                        font.family: PolkitAgentStyle.iconFont
                        font.pixelSize: PolkitAgentStyle.identityFontPx
                        color: PolkitAgentStyle.identitySubTextColor
                    }
                }

                MouseArea {
                    id: identityMa
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !root.isAuthenticating
                    cursorShape: (root.hasMultipleIdentities && !root.isAuthenticating) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (root.hasMultipleIdentities) {
                            root.cycleIdentity()
                        } else {
                            root.focusInput()
                        }
                    }
                }
            }

            // ── Password Entry Box ──
            Rectangle {
                id: inputBox
                Layout.fillWidth: true
                height: PolkitAgentStyle.inputHeight
                radius: PolkitAgentStyle.inputRadius
                color: PolkitAgentStyle.inputBg
                opacity: root.isAuthenticating ? 0.55 : 1.0
                border.width: (root.statusIsError || passwordInput.activeFocus) ? 1.5 : 1
                border.color: root.statusIsError
                    ? PolkitAgentStyle.inputBorderError
                    : (passwordInput.activeFocus ? PolkitAgentStyle.inputBorderFocused : PolkitAgentStyle.inputBorder)
                Behavior on opacity { NumberAnimation { duration: PolkitAgentStyle.colorAnimDurationMs } }
                Behavior on border.color { ColorAnimation { duration: PolkitAgentStyle.colorAnimDurationMs } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 6

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        TextInput {
                            id: passwordInput
                            anchors.fill: parent
                            focus: true
                            enabled: !root.isAuthenticating
                            color: PolkitAgentStyle.inputTextColor
                            font.pixelSize: PolkitAgentStyle.inputFontPx
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: ((root.flow && root.flow.responseVisible) || root.revealPassword) ? TextInput.Normal : TextInput.Password
                            selectByMouse: true
                            clip: true
                            text: root.passwordText

                            onTextEdited: {
                                root.passwordText = text
                                if (root.hasError && text.length > 0) {
                                    root.hasError = false
                                }
                            }

                            Keys.onReturnPressed: root.submitPassword()
                            Keys.onEnterPressed: root.submitPassword()
                            Keys.onEscapePressed: root.cancelAuth()
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: root.isAuthenticating ? "Verifying..." : root.promptPlaceholder
                            font.pixelSize: PolkitAgentStyle.inputFontPx
                            color: PolkitAgentStyle.inputPlaceholderColor
                            elide: Text.ElideRight
                            visible: root.passwordText.length === 0
                        }
                    }

                    Rectangle {
                        id: revealBtn
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 6
                        color: revealMa.containsMouse ? PolkitAgentStyle.identityHoverBg : PolkitAgentStyle.transparent
                        Behavior on color { ColorAnimation { duration: PolkitAgentStyle.colorAnimDurationMs } }

                        Text {
                            anchors.centerIn: parent
                            text: root.revealPassword ? "󰈉" : "󰈈"
                            font.family: PolkitAgentStyle.iconFont
                            font.pixelSize: PolkitAgentStyle.inputFontPx
                            color: PolkitAgentStyle.identitySubTextColor
                        }

                        MouseArea {
                            id: revealMa
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !root.isAuthenticating
                            cursorShape: !root.isAuthenticating ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                root.revealPassword = !root.revealPassword
                                root.focusInput()
                            }
                        }
                    }
                }
            }

            // ── Error / Supplementary Status Text ──
            Text {
                id: statusLabel
                Layout.fillWidth: true
                visible: root.statusText.length > 0
                text: root.statusText
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                font.pixelSize: PolkitAgentStyle.messageFontPx
                color: root.statusIsError ? PolkitAgentStyle.errorColor : PolkitAgentStyle.infoColor
            }

            // ── GNOME Bottom Action Buttons ──
            RowLayout {
                Layout.fillWidth: true
                spacing: PolkitAgentStyle.buttonSpacing

                Rectangle {
                    id: cancelBtn
                    Layout.fillWidth: true
                    height: PolkitAgentStyle.buttonHeight
                    radius: PolkitAgentStyle.buttonRadius
                    color: cancelMa.pressed
                        ? PolkitAgentStyle.cancelBtnPressedBg
                        : (cancelMa.containsMouse ? PolkitAgentStyle.cancelBtnHoverBg : PolkitAgentStyle.cancelBtnBg)
                    border.width: 1
                    border.color: PolkitAgentStyle.cancelBtnBorder
                    Behavior on color { ColorAnimation { duration: PolkitAgentStyle.colorAnimDurationMs } }

                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.pixelSize: PolkitAgentStyle.buttonFontPx
                        font.weight: Font.Medium
                        color: PolkitAgentStyle.cancelBtnText
                    }

                    MouseArea {
                        id: cancelMa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.cancelAuth()
                    }
                }

                Rectangle {
                    id: authBtn
                    Layout.fillWidth: true
                    height: PolkitAgentStyle.buttonHeight
                    radius: PolkitAgentStyle.buttonRadius
                    color: !root.canSubmit
                        ? PolkitAgentStyle.authBtnDisabledBg
                        : (authMa.containsMouse ? PolkitAgentStyle.authBtnHoverBg : PolkitAgentStyle.authBtnBg)
                    Behavior on color { ColorAnimation { duration: PolkitAgentStyle.colorAnimDurationMs } }

                    Text {
                        anchors.centerIn: parent
                        text: "Authenticate"
                        font.pixelSize: PolkitAgentStyle.buttonFontPx
                        font.weight: Font.DemiBold
                        color: root.canSubmit ? PolkitAgentStyle.authBtnText : PolkitAgentStyle.authBtnDisabledText
                    }

                    MouseArea {
                        id: authMa
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.canSubmit
                        cursorShape: root.canSubmit ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.submitPassword()
                    }
                }
            }
        }
    }
}
