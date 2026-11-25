import QtQuick
import Quickshell.Hyprland
import "WindowPolicy.js" as Policy

Item {
    id: root
    property var pendingMoves: ({})
    readonly property int moveTimeoutMs: 1800

    function focusToplevel(win) {
        const address = Policy.addressOf(win)
        if (!address) return false
        const cursor = Hyprland.cursor
        const selector = JSON.stringify("address:" + address)
        Hyprland.dispatch("hl.dsp.focus({ window = " + selector + " })")
        Hyprland.dispatch("hl.dsp.window.alter_zorder({ window = " + selector + ", mode = \"top\" })")
        if (cursor && Number.isFinite(cursor.x) && Number.isFinite(cursor.y) && (cursor.x !== 0 || cursor.y !== 0))
            Hyprland.dispatch("hl.dsp.cursor.move({ x = " + Math.round(cursor.x) + ", y = " + Math.round(cursor.y) + " })")
        return true
    }

    function trackMove(address, expectedName, expectedId, focusAfter) {
        const next = Object.assign({}, pendingMoves)
        next[address] = {name: expectedName, id: expectedId, focusAfter: focusAfter, deadline: Date.now() + moveTimeoutMs}
        pendingMoves = next
        Hyprland.refreshToplevels()
        Hyprland.refreshWorkspaces()
    }

    function verifyMoves() {
        const now = Date.now()
        const next = Object.assign({}, pendingMoves)
        const windows = Array.from(Hyprland.toplevels.values || [])
        let changed = false
        for (const address of Object.keys(next)) {
            const move = next[address]
            const win = windows.find(w => Policy.addressOf(w) === address)
            const ws = win ? win.workspace : null
            if (ws && (move.name ? ws.name === move.name : ws.id === move.id)) {
                if (move.focusAfter) focusToplevel(win)
                console.info("WindowActions: confirmed workspace move " + address + " -> " + ws.name)
                delete next[address]
                changed = true
            } else if (now >= move.deadline) {
                console.warn("WindowActions: workspace move not confirmed for " + address + "; no retry issued")
                delete next[address]
                changed = true
            }
        }
        if (changed) pendingMoves = next
        if (Object.keys(next).length) Hyprland.refreshToplevels()
    }

    Timer {
        interval: 180
        repeat: true
        running: Object.keys(root.pendingMoves).length > 0
        onTriggered: root.verifyMoves()
    }

    function activate(win, mode) {
        if (!win) return false
        const address = Policy.addressOf(win)
        if (!address) return false
        if (pendingMoves[address]) return true
        const selector = JSON.stringify("address:" + address)
        const workspace = win.workspace
        const name = workspace ? String(workspace.name) : ""
        const recovery = Policy.recoveryWorkspace(name)
        const handle = win.wayland
        const ipc = win.lastIpcObject || {}
        const decision = Policy.actionFor({
            mode: mode,
            recovery: recovery,
            minimized: !!(handle && handle.minimized),
            current: Policy.sameWorkspace(workspace, Hyprland.focusedWorkspace),
            protectedWindow: !!(ipc.pinned || (handle && handle.fullscreen)),
            numericWorkspace: !!(workspace && workspace.id > 0),
            special: name.startsWith("special:"),
            hasHandle: !!handle
        })
        if (decision === "restore-workspace") {
            const existingWorkspace = Array.from(Hyprland.workspaces.values || []).some(w => w.id === recovery.id)
            if (!existingWorkspace && recovery.monitor && Array.from(Hyprland.monitors.values || []).some(m => m.name === recovery.monitor))
                Hyprland.dispatch("hl.dsp.focus({ monitor = " + JSON.stringify(recovery.monitor) + " })")
            Hyprland.dispatch("hl.dsp.window.move({ window = " + selector + ", workspace = " + JSON.stringify(String(recovery.id)) + ", follow = true })")
            trackMove(address, "", recovery.id, true)
            return true
        }
        if (decision === "minimize-workspace") {
            const monitorName = win.monitor ? String(win.monitor.name) : ""
            const target = "special:plank-minimized-" + workspace.id + (/^[a-zA-Z0-9_.-]+$/.test(monitorName) ? "--" + monitorName : "")
            Hyprland.dispatch("hl.dsp.window.move({ window = " + selector + ", workspace = " + JSON.stringify(target) + ", follow = false })")
            trackMove(address, target, 0, false)
            return true
        }
        if (decision === "restore-native") {
            handle.minimized = false
            handle.activate()
            return true
        }
        if (decision === "minimize-native") {
            handle.minimized = true
            return true
        }
        return focusToplevel(win)
    }
}
