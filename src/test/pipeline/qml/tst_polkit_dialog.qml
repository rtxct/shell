import QtQuick
import QtTest
import "../../../../themes"
import "../../../app/styles"
import "../../../app/components"

Item {
    id: root
    width: 640
    height: 520

    readonly property var idAlice: ({ id: "alice", displayName: "Alice User", isGroup: false })
    readonly property var idRoot: ({ id: "root", displayName: "Super User", isGroup: false })

    QtObject {
        id: mockFlow
        property string message: "Authentication is required to modify system configuration."
        property string actionId: "org.freedesktop.policykit.exec"
        property string inputPrompt: "Password: "
        property bool responseVisible: false
        property bool isResponseRequired: true
        property bool isCompleted: false
        property bool failed: false
        property bool supplementaryIsError: false
        property string supplementaryMessage: ""
        property var identities: [idAlice, idRoot]
        property var selectedIdentity: idAlice
        property string lastSubmitted: ""
        property int submitCalls: 0
        property int cancelCalls: 0

        signal authenticationFailed()

        function submit(value) {
            lastSubmitted = value
            submitCalls++
        }

        function cancelAuthenticationRequest() {
            cancelCalls++
        }
    }

    PolkitDialog {
        id: dialog
        anchors.centerIn: parent
        active: false
        flow: mockFlow
        fallbackUserName: "fallback"
    }

    SignalSpy {
        id: submitSpy
        target: dialog
        signalName: "submitRequested"
    }

    SignalSpy {
        id: cancelSpy
        target: dialog
        signalName: "cancelRequested"
    }

    TestCase {
        name: "PolkitDialogTests"
        when: windowShown

        function findVisibleText(node, targetText) {
            if (!node) return false
            if (node.visible && node.text !== undefined && String(node.text) === targetText) {
                return true
            }
            var kids = node.children || []
            for (var i = 0; i < kids.length; i++) {
                if (findVisibleText(kids[i], targetText)) return true
            }
            return false
        }

        function resetState() {
            mockFlow.selectedIdentity = idAlice
            mockFlow.failed = false
            mockFlow.supplementaryIsError = false
            mockFlow.supplementaryMessage = ""
            mockFlow.isCompleted = false
            mockFlow.isResponseRequired = true
            mockFlow.responseVisible = false
            mockFlow.lastSubmitted = ""
            mockFlow.submitCalls = 0
            mockFlow.cancelCalls = 0
            dialog.active = false
            dialog.isAuthenticating = false
            dialog.flow = mockFlow
            submitSpy.clear()
            cancelSpy.clear()
            wait(20)
            dialog.active = true
            tryVerify(function() { return dialog.opacity > 0.9 && dialog.inputField.activeFocus }, 1000)
        }

        function test_renders_prompt_action_and_identity() {
            resetState()
            verify(findVisibleText(dialog, "Authentication Required"))
            verify(findVisibleText(dialog, mockFlow.message))
            verify(findVisibleText(dialog, mockFlow.actionId))
            compare(dialog.identityPrimaryText, "Alice User")
            compare(dialog.identitySecondaryText, "(alice)")
            compare(dialog.promptPlaceholder, "Password")
            verify(findVisibleText(dialog, "Alice User"))
        }

        function test_submit_password_via_enter_key_and_button() {
            resetState()
            compare(dialog.isAuthenticating, false)
            compare(dialog.inputField.enabled, true)

            dialog.passwordText = "hunter2"
            dialog.inputField.forceActiveFocus()
            wait(10)
            keyClick(Qt.Key_Return)

            compare(submitSpy.count, 1)
            compare(submitSpy.signalArguments[0][0], "hunter2")
            compare(mockFlow.submitCalls, 1)
            compare(mockFlow.lastSubmitted, "hunter2")
            compare(dialog.passwordText, "")
            compare(dialog.isAuthenticating, true)
            compare(dialog.inputField.enabled, false)

            mockFlow.authenticationFailed()
            compare(dialog.isAuthenticating, false)
            compare(dialog.inputField.enabled, true)
            tryVerify(function() { return dialog.inputField.activeFocus }, 1000)

            dialog.passwordText = "second-secret"
            dialog.submitPassword()
            compare(submitSpy.count, 2)
            compare(mockFlow.submitCalls, 2)
            compare(mockFlow.lastSubmitted, "second-secret")
            compare(dialog.passwordText, "")
            compare(dialog.isAuthenticating, true)
            compare(dialog.inputField.enabled, false)
        }

        function test_cancel_via_escape_key_and_method() {
            resetState()
            dialog.passwordText = "partial"
            dialog.inputField.forceActiveFocus()
            wait(10)
            keyClick(Qt.Key_Escape)

            compare(cancelSpy.count, 1)
            compare(mockFlow.cancelCalls, 1)
            compare(dialog.passwordText, "")

            dialog.cancelAuth()
            compare(cancelSpy.count, 2)
            compare(mockFlow.cancelCalls, 2)
        }

        function test_failed_auth_clears_password_shows_error_and_refocuses() {
            resetState()
            dialog.passwordText = "wrong-pass"
            dialog.submitPassword()
            compare(dialog.isAuthenticating, true)
            compare(dialog.inputField.enabled, false)
            compare(dialog.passwordText, "")

            mockFlow.supplementaryMessage = "Sorry, try again."
            mockFlow.supplementaryIsError = true
            mockFlow.failed = true
            mockFlow.authenticationFailed()

            compare(dialog.isAuthenticating, false)
            compare(dialog.inputField.enabled, true)
            compare(dialog.passwordText, "")
            compare(dialog.statusIsError, true)
            compare(dialog.statusText, "Sorry, try again.")
            verify(findVisibleText(dialog, "Sorry, try again."))
            tryVerify(function() { return dialog.inputField.activeFocus }, 1000)
        }

        function test_cycle_identity_switches_selected_user() {
            resetState()
            compare(mockFlow.selectedIdentity, idAlice)

            dialog.cycleIdentity()
            compare(mockFlow.selectedIdentity, idRoot)
            compare(dialog.identityPrimaryText, "Super User")
            compare(dialog.identitySecondaryText, "(root)")

            dialog.cycleIdentity()
            compare(mockFlow.selectedIdentity, idAlice)
            compare(dialog.identityPrimaryText, "Alice User")
        }
    }
}
