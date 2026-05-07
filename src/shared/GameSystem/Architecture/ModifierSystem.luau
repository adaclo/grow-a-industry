local ModifierSystem = {}

-- format: { [statName] = { [sourceId] = {Value = number, Type = "Add" | "Multiply"} } }
local modifiers = {}

function ModifierSystem.Register(statName, sourceId, value, modType)
    if not modifiers[statName] then
        modifiers[statName] = {}
    end
    modifiers[statName][sourceId] = {Value = value, Type = modType or "Add"}
    print(string.format("[ModifierSystem] Registered '%s' for '%s' (Value: %s, Type: %s)", sourceId, statName, tostring(value), tostring(modType or "Add")))
end

function ModifierSystem.Remove(statName, sourceId)
    if modifiers[statName] then
        modifiers[statName][sourceId] = nil
    end
end

-- Remove a sourceId from ALL stat tables at once
function ModifierSystem.Clear(sourceId)
    for statName, sources in pairs(modifiers) do
        if sources[sourceId] then
            sources[sourceId] = nil
            print(string.format("[ModifierSystem] Cleared '%s' from '%s'", sourceId, statName))
        end
    end
end

function ModifierSystem.Calculate(statName, baseValue)
    local finalValue = baseValue or 0
    local multiplier = 1

    if modifiers[statName] then
        for _, mod in pairs(modifiers[statName]) do
            if mod.Type == "Add" then
                finalValue += mod.Value
            elseif mod.Type == "Multiply" then
                multiplier += mod.Value
            end
        end
    end
    
    return finalValue * multiplier
end

-- Returns raw modifiers table (read-only use only)
function ModifierSystem.List()
    return modifiers
end

-- Prints a human-readable dump of all active modifiers
function ModifierSystem.Snapshot()
    print("[ModifierSystem] ── Snapshot ──────────────────────")
    local empty = true
    for statName, sources in pairs(modifiers) do
        for sourceId, mod in pairs(sources) do
            print(string.format("  %s | %s → %s %s", statName, sourceId, tostring(mod.Value), mod.Type))
            empty = false
        end
    end
    if empty then print("  (no active modifiers)") end
    print("[ModifierSystem] ─────────────────────────────────")
end

return ModifierSystem
