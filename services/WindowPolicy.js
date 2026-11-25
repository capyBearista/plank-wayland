.pragma library

function addressOf(win) {
    const raw = String(win && (win.address || (win.lastIpcObject && win.lastIpcObject.address)) || "")
    const hex = raw.replace(/^0x/i, "")
    return /^[0-9a-fA-F]+$/.test(hex) ? "0x" + hex.toLowerCase() : ""
}

function sameWorkspace(workspace, focused) {
    return !!(workspace && focused && workspace.id === focused.id && workspace.name === focused.name)
}

function recoveryWorkspace(name) {
    const match = /^special:plank-minimized-([1-9][0-9]*)(?:--([a-zA-Z0-9_.-]+))?$/.exec(String(name || ""))
    return match ? {id: Number(match[1]), monitor: match[2] || ""} : null
}

function actionFor(state) {
    if (state.recovery) return "restore-workspace"
    if (state.minimized) return "restore-native"
    if (!state.current || state.protectedWindow) return "focus"
    if (state.mode === "workspace" && state.numericWorkspace && !state.special) return "minimize-workspace"
    if (state.mode === "native" && state.hasHandle) return "minimize-native"
    return "focus"
}
