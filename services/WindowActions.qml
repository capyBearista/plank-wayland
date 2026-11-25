import QtQuick
import Quickshell.Hyprland

QtObject {
    function focusToplevel(win) {
        if (!win) return false

        let savedX = 0, savedY = 0
        try {
            const cur = Hyprland.cursor
            if (cur && cur.x !== undefined) {
                savedX = cur.x
                savedY = cur.y
            }
        } catch (e) {}

        let address = ""
        let from = "none"
        try {
            if (win.address !== undefined && win.address !== null && String(win.address).length > 0) {
                address = String(win.address)
                from = "win.address"
            } else if (win.lastIpcObject && win.lastIpcObject.address) {
                address = String(win.lastIpcObject.address)
                from = "lastIpcObject"
            }
        } catch (e) {}

        if (!address) {
            console.log("focusToplevel: no address found")
            return false
        }

        if (!address.startsWith("0x")) address = "0x" + address

        if (!/^0x[0-9a-fA-F]+$/.test(address)) return false
        const selector = JSON.stringify("address:" + address)
        Hyprland.dispatch("hl.dsp.focus({ window = " + selector + " })")
        Hyprland.dispatch("hl.dsp.window.alter_zorder({ window = " + selector + ", mode = \"top\" })")
        if (Number.isFinite(savedX) && Number.isFinite(savedY) && (savedX !== 0 || savedY !== 0)) {
            Hyprland.dispatch("hl.dsp.cursor.move({ x = " + Math.round(savedX) + ", y = " + Math.round(savedY) + " })")
        }
        return true
    }


    // Native foreign-toplevel minimization is optional: the compositor may ignore it.
    function activate(win, mode) {
        if (!win) return false
        const handle = win.wayland
        if (handle && handle.minimized) {
            handle.minimized = false
            handle.activate()
            return true
        }
        if (mode === "native" && win.activated && handle) {
            handle.minimized = true
            return true
        }
        return focusToplevel(win)
    }
}
