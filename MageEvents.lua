local _, addon = ...
local results = {}
local foreignStarts = {}
local blizzardName
local lastPrune = 0
local priority = { crit = 6, hit = 5, graze = 4, resist = 3, absorb = 2, miss = 1 }

local function Supported(key, source)
    local db = addon.db
    if not db or not db.enabled or not source or not source:match("^Player%-")
        or (not db.allSources and source ~= UnitGUID("player")) then return false end
    local pack = addon.soundPacks[db.soundPack]
    return pack and not pack.meleeOnly and (pack.weapons or pack.weapon == key)
end

function addon.ResetMageResults()
    wipe(results)
    wipe(foreignStarts)
    lastPrune = 0
end

function addon.BeginMageResult(source, key)
    local spell = addon.mageSpells[key]
    if not spell or not spell.aoe then return end
    -- A new application replaces the old grouping window, including an
    -- interrupted/restarted Blizzard. Queued old callbacks then do nothing.
    local now = GetTime()
    if now - lastPrune >= 30 then
        for token, group in pairs(results) do if now > group.expires then results[token] = nil end end
        lastPrune = now
    end
    results[source .. ":" .. key] = { expires = now + (key == "blizzard" and 9 or 1), key = key }
end

local function QueueResult(source, key, category)
    local token = source .. ":" .. key
    local group = results[token]
    if not group or GetTime() > group.expires then
        addon.BeginMageResult(source, key)
        group = results[token]
    end
    if group.played then return end
    if not group.category or priority[category] > priority[group.category] then group.category = category end
    if group.pending then return end
    group.pending = true
    local function Play()
        if results[token] ~= group or not Supported(key, source) then return end
        group.played = true
        addon.PlayCategory(group.category, false, source, addon.mageSpells[key].school, key)
    end
    -- One result per application; collect the same burst's targets so a
    -- crit outranks normal hits and a successful hit outranks shared misses.
    if C_Timer and C_Timer.After then C_Timer.After(0.08, Play) else Play() end
end

local function BlizzardDamageKey(event, id, name)
    local key = addon.mageSpellByID[id]
    if key then return key end
    if event ~= "SPELL_DAMAGE" and event ~= "SPELL_PERIODIC_DAMAGE"
        and event ~= "SPELL_MISSED" and event ~= "SPELL_PERIODIC_MISSED" then return end
    -- Some combat-log clients use a triggered Blizzard tick ID. Resolve its
    -- localized name from the client rather than guessing NPC/retail IDs.
    if not blizzardName then
        if type(GetSpellInfo) == "function" then blizzardName = GetSpellInfo(10)
        elseif C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(10)
            blizzardName = info and info.name
        end
    end
    if blizzardName and name == blizzardName then return "blizzard" end
end

function addon.HandleMageCombatLog(event, source, id, name, amountOrMiss, resisted, blocked, critical)
    local key = BlizzardDamageKey(event, id, name)
    if not key then return false end
    if not Supported(key, source) then return true end
    local spell = addon.mageSpells[key]
    local own = source == UnitGUID("player")
    if event == "SPELL_CAST_START" then
        if not own and spell.castMode == "start" then
            local now = GetTime()
            for token, time in pairs(foreignStarts) do
                if now - time > 30 then foreignStarts[token] = nil end
            end
            foreignStarts[source .. ":" .. key] = now
            addon.PlayMageCast(source, nil, id)
        end
        return true
    elseif event == "SPELL_CAST_SUCCESS" then
        if not own then
            addon.BeginMageResult(source, key)
            local token = source .. ":" .. key
            local started = foreignStarts[token]
            if spell.castMode ~= "start" or not started or GetTime() - started > 30 then
                addon.PlayMageCast(source, nil, id)
            end
            foreignStarts[token] = nil
        end
        return true
    end
    -- Keep Frostbolt's existing single-target path, tested with real logs.
    if key == "frostbolt" then return false end
    if not spell.damage then return true end
    local damage = event == "SPELL_DAMAGE" or key == "blizzard" and event == "SPELL_PERIODIC_DAMAGE"
    local missed = event == "SPELL_MISSED" or key == "blizzard" and event == "SPELL_PERIODIC_MISSED"
    if not damage and not missed then return true end
    local category
    if missed then
        category = amountOrMiss == "RESIST" and "resist" or amountOrMiss == "ABSORB" and "absorb" or "miss"
    else
        local crit = spell.canCrit and (critical == true or critical == 1)
        local partial = type(amountOrMiss) == "number" and amountOrMiss > 0
            and ((type(resisted) == "number" and resisted > 0) or (type(blocked) == "number" and blocked > 0))
        category = crit and "crit" or partial and addon.db.graze and "graze" or "hit"
    end
    if spell.aoe then QueueResult(source, key, category)
    else addon.PlayCategory(category, false, source, spell.school, key) end
    return true
end
