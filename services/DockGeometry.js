.pragma library

// All measurements are in dock-local logical pixels. Interaction slots remain fixed.
function layout(count, size, spacing, width, pointer, progress, maximum) {
    const step = size + spacing
    const start = (width - (count * size + Math.max(0, count - 1) * spacing)) / 2 + size / 2
    const radius = step * 1.6
    const amount = Math.max(0, Math.min(1, progress)) * Math.max(0, maximum - 1)
    const glyph = Math.max(1, size - 10)
    const gap = Math.min(6, Math.max(0, step - glyph))
    const result = []
    for (let i = 0; i < count; i++) {
        const home = start + i * step
        const distance = Math.min(1, Math.abs(pointer - home) / radius)
        const weight = (1 + Math.cos(Math.PI * distance)) / 2
        const scale = 1 + amount * weight
        result.push({home: home, center: home, scale: scale, half: glyph * scale / 2})
    }
    if (!count || amount === 0) return result
    const index = Math.max(0, Math.min(count - 1, (pointer - start) / step))
    const left = Math.floor(index)
    const right = Math.min(count - 1, left + 1)
    const fraction = index - left
    // Keep the cursor's fractional position between the two nearest icons stable.
    if (right !== left) {
        const extra = Math.max(0, result[left].half + result[right].half + gap - step)
        result[left].center -= extra * fraction
        result[right].center += extra * (1 - fraction)
    }
    // Only push a neighboring glyph when its actual visible bounds would overlap.
    for (let i = left - 1; i >= 0; i--)
        result[i].center = Math.min(result[i].home, result[i + 1].center - result[i + 1].half - result[i].half - gap)
    for (let i = right + 1; i < count; i++)
        result[i].center = Math.max(result[i].home, result[i - 1].center + result[i - 1].half + result[i].half + gap)
    return result
}

function bounds(items, width, barWidth, padding) {
    let left = (width - barWidth) / 2
    let right = left + barWidth
    for (const item of items) {
        left = Math.min(left, item.center - item.half - padding)
        right = Math.max(right, item.center + item.half + padding)
    }
    return {left: left, width: right - left}
}
