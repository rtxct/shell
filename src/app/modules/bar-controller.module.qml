// ============================================================================
// File: modules/bar-controller.module.qml
// Purpose: State machine and choreography handshake controller coordinating travel, expansion, collapse, and return phases across bar items.
// Public API:
//   - Properties: weather, events, workspaces, now, owner, host, ownerKind, ownerTravels, bubbleLen, bubbleDepth, shownTitle, shownPanel ...
//   - Functions:  open(o), close(), travelDone(), expandDone(), collapseDone(), returnDone(), finish()
// Dependencies: QtQuick
// ============================================================================
import QtQuick

// Shared STATE for one bar (not style) + the open/close choreography.
// The top bar and the left bar each get their own controller.
//
// Only one thing per bar can be open at a time. Opening goes through these phases:
//   closed -> travelling (bubble flies to the middle, only for circles / side bars)
//          -> expanding  (bubble opens into the panel)
//          -> open
// and closing plays them in reverse:
//   open -> collapsing (panel shrinks back into the bubble)
//        -> returning  (bubble flies home) -> closed
// While anything but "closed", every other component of that bar stays invisible.
// The components run their own animations and report back with the *Done() functions.
QtObject {
    id: ctl

    property var weather: null
    property var events: null
    property var workspaces: null
    property var now: new Date()

    // ── who is open / animating ──
    property string owner: ""             // id of the component that is open, "" = none
    property string host: "island"        // "island": panel drawn by the bar's island · "own": owner draws itself
    property string ownerKind: "click"    // "click": Esc / click outside close it · "hover": mouse leave closes it
    property bool ownerTravels: false     // does it start as a bubble that flies to the middle?
    property real bubbleLen: 0            // bubble size along the bar edge
    property real bubbleDepth: 0          // bubble size away from the edge
    property string shownTitle: ""
    property var shownPanel: null         // a Component, shown inside the big panel

    property string phase: "closed"

    readonly property bool busy: phase !== "closed"
    readonly property bool clickOpen: busy && ownerKind === "click"

    // o: { id, host, kind, travels, title, panel, bubbleLen, bubbleDepth }
    function open(o) {
        if (phase !== "closed") return
        owner = o.id
        host = o.host || "island"
        ownerKind = o.kind || "click"
        ownerTravels = o.travels === true
        bubbleLen = o.bubbleLen || 0
        bubbleDepth = o.bubbleDepth || 0
        shownTitle = o.title || ""
        shownPanel = o.panel || null
        phase = ownerTravels ? "travelling" : "expanding"
    }

    function close() {
        if (phase === "travelling") phase = "returning"
        else if (phase === "expanding" || phase === "open") phase = "collapsing"
    }

    function travelDone() { if (phase === "travelling") phase = "expanding" }
    function expandDone() { if (phase === "expanding") phase = "open" }
    function collapseDone() {
        if (phase !== "collapsing") return
        if (ownerTravels) phase = "returning"
        else finish()
    }
    function returnDone() { if (phase === "returning") finish() }
    function finish() { phase = "closed"; owner = "" }

    function restoreOpen(o) {
        owner = o.id
        host = o.host || "island"
        ownerKind = o.kind || "click"
        ownerTravels = o.travels === true
        bubbleLen = o.bubbleLen || 0
        bubbleDepth = o.bubbleDepth || 0
        shownTitle = o.title || ""
        shownPanel = o.panel || null
        phase = "open"
    }
}
