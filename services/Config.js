.pragma library

function merge(defaults, supplied) {
    const result = Object.assign({}, defaults)
    if (!supplied || typeof supplied !== "object" || Array.isArray(supplied)) return result
    for (const key of Object.keys(defaults)) {
        if (!(key in supplied)) continue
        const value = supplied[key], base = defaults[key]
        if (typeof base === "number" && typeof value === "number" && Number.isFinite(value)) result[key] = value
        else if (Array.isArray(base) && Array.isArray(value) && value.every(v => typeof v === "string")) result[key] = value.slice()
        else if (base && typeof base === "object" && !Array.isArray(base) && value && typeof value === "object" && !Array.isArray(value)) result[key] = Object.assign({}, value)
        else if (typeof base === typeof value && typeof base !== "object") result[key] = value
    }
    return result
}

function clamp(value, low, high) { return Math.max(low, Math.min(high, value)) }

function validateDock(defaults, input) {
    const d = merge(defaults, input)
    const ranges = { iconSize:[32,96], zoomPercent:[100,300], bottomGap:[0,80], edgeTriggerHeight:[1,20], hideDelayMs:[0,5000], slideTime:[0,2000], indicatorSize:[1,16], attentionRevealMs:[0,30000], launchTimeoutMs:[500,30000], itemPadding:[0,20], horizPadding:[0,30], topPadding:[-20,30], bottomPadding:[0,30], hoverMenuDelayMs:[0,3000] }
    for (const key of Object.keys(ranges)) if (key in d) d[key] = clamp(d[key], ranges[key][0], ranges[key][1])
    if (!["system","light","dark","manual"].includes(d.themeMode)) d.themeMode = defaults.themeMode
    if (!["off","native"].includes(d.minimizeMode)) d.minimizeMode = defaults.minimizeMode
    return d
}

function validPins(value) {
    return Array.isArray(value) && value.every(p => p && typeof p === "object" && typeof p.appId === "string" && p.appId.length > 0)
}
