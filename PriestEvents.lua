local _, addon = ...
local results = {}
local priority = { crit = 6, hit = 5, graze = 4, resist = 3, absorb = 2, miss = 1 }

local function Supported(key, source)
    local db = addon.db
    if not db or not db.enabled or not source or not source:match("^Player%-")
        or (not db.allSources and source ~= UnitGUID("player")) then return false end
    local pack = addon.soundPacks[db.soundPack]
    return pack and not pack.meleeOnly and not pack.mageOnly and (pack.weapons or pack.weapon == key)
end

function addon.ResetPriestResults()
    wipe(results)
end

local function BeginNova(source)
    local now = GetTime()
    for token, group in pairs(results) do if now > group.expires then results[token] = nil end end
    local group = { expires = now + 1 }
    results[source] = group
    return group
end

local function QueueNova(source, category)
    local group = results[source]
    if not group or GetTime() > group.expires then group = BeginNova(source) end
    if group.played then return end
    if not group.category or priority[category] > priority[group.category] then group.category = category end
    if group.pending then return end
    group.pending = true
    local function Play()
        if results[source] ~= group or not Supported("holynova", source) then return end
        group.played = true
        addon.PlayCategory(group.category, false, source, "holy", "holynova")
    end
    -- Damage targets share one reaction; healing events never enter this queue.
    if C_Timer and C_Timer.After then C_Timer.After(0.08, Play) else Play() end
end

function addon.HandlePriestCombatLog(event, source, id, amountOrMiss, resisted, blocked, critical)
    local key = addon.priestSpellByID[id]
    if not key then return false end
    if not Supported(key, source) then return true end
    local spell = addon.priestSpells[key]
    if event == "SPELL_CAST_SUCCESS" then
        if spell.aoe then BeginNova(source) end
        return true
    end
    local category
    if event == "SPELL_MISSED" then
        category = amountOrMiss == "RESIST" and "resist" or amountOrMiss == "ABSORB" and "absorb" or "miss"
    elseif spell.auraHit then
        -- Shadow Word: Pain has no direct damage or crits in Classic Era.
        -- A successful application/refresh is its one spoken normal hit.
        if (event ~= "SPELL_AURA_APPLIED" and event ~= "SPELL_AURA_REFRESH") or amountOrMiss ~= "DEBUFF" then return true end
        category = "hit"
    elseif event == "SPELL_DAMAGE" then
        local crit = spell.canCrit and (critical == true or critical == 1)
        local partial = type(amountOrMiss) == "number" and amountOrMiss > 0
            and ((type(resisted) == "number" and resisted > 0) or (type(blocked) == "number" and blocked > 0))
        category = crit and "crit" or partial and addon.db.graze and "graze" or "hit"
    else
        return true -- No periodic ticks, heals, aura removal, or cast-start clips.
    end
    if spell.aoe then QueueNova(source, category)
    else addon.PlayCategory(category, false, source, spell.school, key) end
    return true
end
