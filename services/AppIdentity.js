.pragma library

function normalize(value) { return String(value || "").trim().toLowerCase().replace(/\.desktop$/, "") }

function override(value, overrides) {
    const key = normalize(value)
    for (const candidate of Object.keys(overrides || {})) {
        if (normalize(candidate) === key && typeof overrides[candidate] === "string" && overrides[candidate].trim()) return overrides[candidate].trim()
    }
    const known = {"obs":"com.obsproject.Studio", "ghostty":"com.mitchellh.ghostty"}
    return known[key] || String(value || "").trim()
}

function key(app, overrides) {
    if (!app) return ""
    return normalize(override(app.canonicalId || app.desktopId || app.appId, overrides))
}

function excluded(app, exclusions, overrides) {
    const keys = [app && app.appId, app && app.desktopId, app && app.canonicalId].map(normalize)
    keys.push(key(app, overrides))
    return (exclusions || []).some(value => keys.includes(normalize(value)) || keys.includes(normalize(override(value, overrides))))
}

function reorder(items, fromKey, beforeKey, overrides) {
    const result = items.slice()
    const from = result.findIndex(app => key(app, overrides) === fromKey)
    if (from < 0 || fromKey === beforeKey) return result
    if (beforeKey && !result.some(app => key(app, overrides) === beforeKey)) return result
    const moved = result.splice(from, 1)[0]
    const index = beforeKey ? result.findIndex(app => key(app, overrides) === beforeKey) : result.length
    result.splice(index, 0, moved)
    return result
}
