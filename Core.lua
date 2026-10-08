local addonName, addon = ...

local defaults = {
    enabled = true,
    muteOriginal = true,
    allSources = true,
    hit = true,
    crit = true,
    resist = true,
    miss = true,
    absorb = true,
    graze = true,
    cast = true,
    channel = "SFX",
    soundPack = "magic",
    minimapAngle = 145,
    minimapHidden = false,
}

-- All eleven Frostbolt ranks in Classic Era; spell IDs are locale independent.
local frostboltRanks = { [116] = true, [205] = true, [837] = true, [7322] = true,
    [8406] = true, [8407] = true, [8408] = true, [10179] = true,
    [10180] = true, [10181] = true, [25304] = true }

-- FileDataIDs from the Classic Era Leatrix Sounds wand launch entries.
-- MuteSoundFile applies to a file globally, including other players' wands.
local originalIDs = { 569185, 568765, 569719, 568090, 568228, 569151, 568950, 568935 }
-- Classic spell -> sound mapping checked against Resonance v1.13.1.
-- Precast, cast, missile loop and all six impact variants. These files are
-- also used by other frost spells; MuteSoundFile cannot isolate a spell.
local frostboltOriginalIDs = { 568119, 568128, 568493, 568542, 568843, 569145, 569304, 569765, 569781 }
-- Classic Era Leatrix Sounds weapon files, including draw/load, flight and
-- impact. Bow and crossbow share these sounds; release IDs also checked
-- against Resonance's Classic weapon mapping.
local bowOriginalIDs = { 567672, 567681, 567671, 567680, 567670, 567677,
    567675, 567676, 567678, 567683, 567679, 567674, 567673, 567682 }
local gunOriginalIDs = { 567721, 567718, 567722, 567719, 567720, 567723, 567617 }
local mutedByUs = {}
local warmedOriginalSounds = {}
local previous = {}
local playerGUID
local activeSounds = {}
local seenCasts = {}
local currentPlayerCast
local playbackFailed = false
local warnedAboutPlayback = false
local frame = CreateFrame("Frame")
addon.stats = { hit = 0, crit = 0, resist = 0, miss = 0, absorb = 0, graze = 0, cast = 0 }

function addon.GetBank(school, weapon)
    local pack = addon.soundPacks[addon.db.soundPack] or addon.soundPacks.magic
    if pack.weapons then
        weapon = weapon or (pack.mageOnly and "frostbolt") or addon.ResolveWeapon(UnitGUID("player")) or "wand"
        if pack.mageOnly and not addon.mageSpells[weapon] then return addon.voiceShared, pack, weapon end
        -- Auto Shot cannot identify an unseen hunter's weapon. If both native
        -- weapon banks are muted, use spoken wand takes as a neutral reserve
        -- without caching a guessed bow/gun identification.
        if weapon == "ranged" and addon.bowOriginalsMuted and addon.gunOriginalsMuted then
            return pack.weapons.wand, pack, "ranged"
        end
        return pack.weapons[weapon] or addon.voiceShared, pack, weapon
    end
    return pack.categories or pack.schools[school or "neutral"] or pack.schools.neutral, pack, pack.weapon
end

function addon.Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cffbaabffGabbaSounds:|r " .. message)
end

local function NotifyUI()
    if addon.RefreshMinimap then addon.RefreshMinimap() end
    if addon.RefreshUI then
        addon.RefreshUI()
    end
end

local function StopSoundForSource(source)
    local active = activeSounds[source]
    if active and type(StopSound) == "function" then
        StopSound(active.handle, 50)
    end
    activeSounds[source] = nil
end

local function StopAllSounds()
    for source in pairs(activeSounds) do
        StopSoundForSource(source)
    end
end

local function ReleaseOriginals()
    if type(UnmuteSoundFile) == "function" then
        for id in pairs(mutedByUs) do
            UnmuteSoundFile(id)
        end
    end
    wipe(mutedByUs)
    addon.originalsMuted = false
    addon.frostboltOriginalsMuted = false
    addon.bowOriginalsMuted = false
    addon.gunOriginalsMuted = false
    addon.mageOriginalsMuted = {}
end

local function WarmOriginalSound(id)
    if warmedOriginalSounds[id] or type(PlaySoundFile) ~= "function" or type(StopSound) ~= "function" then return end
    -- Classic may defer muting an asset it has never loaded. Load it under a
    -- temporary mute, stop its handle immediately, and balance that mute
    -- before applying the persistent mute below. No replacement/stats change.
    MuteSoundFile(id)
    local played, handle = PlaySoundFile(id, "SFX", false)
    if played and handle then StopSound(handle) end
    UnmuteSoundFile(id)
    warmedOriginalSounds[id] = true
end

local function CompleteVoiceBank(pack, weapon, db)
    local bank = pack and (pack.weapons and pack.weapons[weapon]
        or pack.weapon == weapon and pack.categories)
    if not bank then return false end
    for _, category in ipairs({ "hit", "crit", "miss", "resist", "absorb" }) do
        if not bank[category] or #bank[category] == 0 then return false end
    end
    return not db.graze or (bank.graze and #bank.graze > 0)
end

function addon.IsSpokenOnly()
    local db = addon.db
    local pack = db and addon.soundPacks[db.soundPack]
    return not not (pack and pack.weapons and not pack.mageOnly and db.muteOriginal and db.allSources and db.cast
        and db.hit and db.crit and db.resist and db.miss and db.absorb)
end

function addon.UpdateOriginalMuting()
    local db = addon.db
    local pack = db and addon.soundPacks[db.soundPack]
    local canMute = db and db.enabled and db.muteOriginal and pack
        and db.allSources and db.hit and db.crit and db.resist and db.miss and db.absorb
        and not playbackFailed
        and type(MuteSoundFile) == "function" and type(UnmuteSoundFile) == "function"
    local wandMute = canMute and not pack.mageOnly and (pack.weapon == "wand" or pack.weapons)
    local frostMute = canMute and CompleteVoiceBank(pack, "frostbolt", db)
    local bowMute = canMute and not pack.mageOnly and CompleteVoiceBank(pack, "bow", db)
    local gunMute = canMute and not pack.mageOnly and CompleteVoiceBank(pack, "gun", db)
    -- Unknown foreign Auto Shots need a normal/crit reserve when both types
    -- are silent. Do not mute them if that reserve is incomplete.
    if pack and pack.weapons and not pack.mageOnly and not CompleteVoiceBank(pack, "wand", db) then
        wandMute, bowMute, gunMute = false, false, false
    end
    addon.originalsMuted = not not wandMute
    addon.frostboltOriginalsMuted = not not frostMute
    addon.bowOriginalsMuted = not not bowMute
    addon.gunOriginalsMuted = not not gunMute
    local wanted = {}
    addon.mageOriginalsMuted = {}
    for key, spell in pairs(addon.mageSpells) do
        local covered = canMute and (pack.weapons or pack.weapon == key)
        local bank = covered and (pack.weapons and pack.weapons[key] or pack.categories)
        if covered and key ~= "frostbolt" then
            covered = db.cast and bank and bank.cast and #bank.cast > 0
            if covered and spell.damage then
                for _, kind in ipairs({ "hit", "miss", "resist", "absorb" }) do
                    if not bank[kind] or #bank[kind] == 0 then covered = false end
                end
                if spell.canCrit and (not bank.crit or #bank.crit == 0) then covered = false end
                if db.graze and (not bank.graze or #bank.graze == 0) then covered = false end
            end
        elseif key == "frostbolt" then covered = frostMute end
        addon.mageOriginalsMuted[key] = not not covered
        if covered then for _, id in ipairs(spell.originalIDs) do wanted[id] = true end end
    end
    if wandMute then for _, id in ipairs(originalIDs) do wanted[id] = true end end
    if frostMute then for _, id in ipairs(frostboltOriginalIDs) do wanted[id] = true end end
    if bowMute then for _, id in ipairs(bowOriginalIDs) do wanted[id] = true end end
    if gunMute then for _, id in ipairs(gunOriginalIDs) do wanted[id] = true end end
    for id in pairs(mutedByUs) do
        if not wanted[id] and type(UnmuteSoundFile) == "function" then
            UnmuteSoundFile(id)
            mutedByUs[id] = nil
        end
    end
    local warmGroups = { frostboltOriginalIDs, bowOriginalIDs, gunOriginalIDs }
    for _, spell in pairs(addon.mageSpells) do warmGroups[#warmGroups + 1] = spell.originalIDs end
    local warmedThisUpdate = {}
    for _, group in ipairs(warmGroups) do
        for _, id in ipairs(group) do
            if wanted[id] and not mutedByUs[id] and not warmedThisUpdate[id] then
                WarmOriginalSound(id); warmedThisUpdate[id] = true
            end
        end
    end
    for id in pairs(wanted) do
        if not mutedByUs[id] then
            MuteSoundFile(id)
            mutedByUs[id] = true
        end
    end
end

function addon.SetOption(key, value)
    -- A convenience mode derived from the existing saved settings, so pack,
    -- source and category changes cannot leave a stale "spoken only" flag.
    if key == "spokenOnly" then
        if not addon.db or type(value) ~= "boolean" then return false end
        if value then
            StopAllSounds()
            addon.ResetMageResults()
            addon.db.soundPack = "spoken"
            addon.db.allSources = true
            for _, category in ipairs({ "hit", "crit", "resist", "miss", "absorb", "graze", "cast" }) do
                addon.db[category] = true
            end
        end
        addon.db.muteOriginal = value
        playbackFailed, warnedAboutPlayback = false, false
        addon.UpdateOriginalMuting()
        NotifyUI()
        return true
    end
    if not addon.db or defaults[key] == nil then
        return false
    end
    if key == "soundPack" then
        if type(value) ~= "string" or not addon.soundPacks[value] then
            return false
        end
    elseif key == "channel" then
        if value ~= "SFX" and value ~= "Master" then
            return false
        end
    elseif key == "minimapAngle" then
        if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return false end
        value = value % 360
    elseif type(value) ~= "boolean" then
        return false
    end
    addon.db[key] = value
    -- An explicit enable/muting change permits retry after fixing missing files.
    if (key == "enabled" or key == "muteOriginal" or key == "soundPack") and value then
        playbackFailed = false
        warnedAboutPlayback = false
    end
    if (key == "enabled" and not value) or key == "soundPack" then
        StopAllSounds()
        addon.ResetMageResults()
    elseif key == "cast" and not value then
        for source in pairs(activeSounds) do
            if source:sub(-5) == ":cast" then StopSoundForSource(source) end
        end
    end
    addon.UpdateOriginalMuting()
    NotifyUI()
    return true
end

function addon.PlayCategory(category, preview, sourceGUID, school, weapon)
    local db = addon.db
    if not db then return false end
    school = school or (preview and addon.PreviewSchool()) or "neutral"
    local bank, pack, voiceWeapon = addon.GetBank(school, weapon)
    if category == "cast" and not addon.mageSpells[voiceWeapon] then
        if preview then addon.Print("Cast-Sounds gehören zu den Magier-Sprachpaketen.") end
        return false
    end
    local pool = bank[category] or (preview and category == "graze" and addon.sharedGraze)
    if not db or not pool or #pool == 0 then
        if preview and addon.mageSpells[voiceWeapon] then
            local spell = addon.mageSpells[voiceWeapon]
            if not spell.damage and (category == "hit" or category == "crit") then
                addon.Print(spell.label .. " verwendet nur einen Sound beim Aktivieren. Nutze Cast hören.")
            elseif voiceWeapon == "blizzard" and category == "crit" then
                addon.Print("Blizzard hat in Classic Era keine kritischen Treffer.")
            else
                addon.Print("Für " .. spell.label .. " sind noch keine " .. (category == "cast" and "Cast-" or category == "crit" and "Crit-" or "Treffer-") .. "Aufnahmen eingebaut.")
            end
        end
        return false
    end
    if not preview and (not db.enabled or not db[category]) then
        return false
    end
    local count = #pool
    local common = category == "miss" or category == "graze" or category == "resist" or category == "absorb"
    local key = db.soundPack .. ":" .. (pack.weapons and (common and "shared" or voiceWeapon) or pack.categories and "all" or school) .. ":" .. category
    local index
    if count > 1 and previous[key] and pack.repeatGroups then
        local lastGroup = pack.repeatGroups[pool[previous[key]]]
        local choices = {}
        for candidate, filename in ipairs(pool) do
            if candidate ~= previous[key] and (not lastGroup or pack.repeatGroups[filename] ~= lastGroup) then
                choices[#choices + 1] = candidate
            end
        end
        -- If a future recording has only one family, still alternate takes.
        if #choices == 0 then
            for candidate = 1, count do
                if candidate ~= previous[key] then choices[#choices + 1] = candidate end
            end
        end
        index = choices[math.random(#choices)]
    elseif count > 1 and previous[key] then
        -- Uniform selection among all entries except the previous one.
        index = math.random(count - 1)
        if index >= previous[key] then
            index = index + 1
        end
    else
        index = math.random(count)
    end
    local now = GetTime()
    for source, active in pairs(activeSounds) do
        if active.expires <= now then
            activeSounds[source] = nil
        end
    end
    local source = preview and "preview" or sourceGUID or playerGUID or "player"
    if not preview and category == "cast" then source = source .. ":cast" end
    -- A new shot replaces only the same shooter's previous tail. Different
    -- shooters can overlap without cutting each other's sounds off.
    StopSoundForSource(source)
    local played, handle = PlaySoundFile(
        "Interface\\AddOns\\" .. addonName .. "\\Sounds\\" .. pool[index], db.channel, false)
    if not played then
        playbackFailed = true
        addon.UpdateOriginalMuting()
        if not warnedAboutPlayback then
            addon.Print("Sound konnte nicht abgespielt werden. Prüfe die Soundeinstellungen und den Ordner Sounds. Die Original-Stummschaltung wurde aufgehoben.")
            warnedAboutPlayback = true
        end
        NotifyUI()
        return false
    end
    previous[key] = index
    if handle then
        activeSounds[source] = { handle = handle, expires = now + addon.soundDurations[pool[index]] }
    end
    if playbackFailed then
        playbackFailed = false
        warnedAboutPlayback = false
        addon.UpdateOriginalMuting()
    end
    if not preview then
        addon.stats[category] = addon.stats[category] + 1
    end
    NotifyUI()
    return true
end

function addon.PlayMageCast(sourceGUID, castGUID, spellID)
    local spellKey = addon.mageSpellByID[spellID]
    local db = addon.db
    if not db or not db.enabled or not db.cast or not spellKey
        or not sourceGUID or not sourceGUID:match("^Player%-")
        or (not db.allSources and sourceGUID ~= playerGUID) then return end
    local pack = addon.soundPacks[db.soundPack]
    if not pack.weapons and pack.weapon ~= spellKey then return end
    local now = GetTime()
    for id, time in pairs(seenCasts) do
        if now - time > 30 then seenCasts[id] = nil end
    end
    if castGUID then
        if seenCasts[castGUID] then return end
        seenCasts[castGUID] = now
    end
    addon.PlayCategory("cast", false, sourceGUID, addon.mageSpells[spellKey].school, spellKey)
end

local function HandleCombatLog()
    if not addon.db or not addon.db.enabled then
        return
    end
    local timestamp, event, hideCaster, sourceGUID, sourceName, sourceFlags,
        sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags,
        spellID, spellName, spellSchool, arg15, overkill, damageSchool,
        resisted, blocked, absorbed, critical = CombatLogGetCurrentEventInfo()
    if not sourceGUID or (not addon.db.allSources and sourceGUID ~= playerGUID) then
        return
    end
    if addon.HandleMageCombatLog(event, sourceGUID, spellID, spellName, arg15, resisted, blocked, critical) then return end
    local isFrostbolt = frostboltRanks[spellID] and sourceGUID:match("^Player%-")
    if not isFrostbolt and spellID ~= 5019 and spellID ~= 75 and spellID ~= 2480 and spellID ~= 7918 and spellID ~= 7919 then return end
    if event ~= "RANGE_DAMAGE" and event ~= "SPELL_DAMAGE" and event ~= "RANGE_MISSED" and event ~= "SPELL_MISSED" then return end
    if isFrostbolt and event ~= "SPELL_DAMAGE" and event ~= "SPELL_MISSED" then return end
    local weapon = isFrostbolt and "frostbolt" or addon.ResolveWeapon(sourceGUID, spellID)
    local pack = addon.soundPacks[addon.db.soundPack]
    if pack.mageOnly and not addon.mageSpells[weapon] then return end
    if not pack.weapons and pack.weapon ~= weapon
        and not (weapon == "ranged" and (pack.weapon == "bow" or pack.weapon == "gun")) then return end
    -- Classic 1.15.9 reports Shoot as RANGE_DAMAGE / RANGE_MISSED. The spell
    -- equivalents use the same payload layout and cover alternative clients.
    if event == "RANGE_DAMAGE" or event == "SPELL_DAMAGE" then
        local school = isFrostbolt and "frost" or weapon == "wand" and addon.ResolveSchool(sourceGUID, damageSchool, spellSchool) or "neutral"
        local isCrit = critical == true or critical == 1
        local partial = type(arg15) == "number" and arg15 > 0
            and ((type(resisted) == "number" and resisted > 0) or (type(blocked) == "number" and blocked > 0))
        local category = isCrit and "crit" or (partial and addon.db.graze and pack.categories and "graze") or "hit"
        addon.PlayCategory(category, false, sourceGUID, school, weapon)
    elseif event == "RANGE_MISSED" or event == "SPELL_MISSED" then
        local category = arg15 == "RESIST" and "resist" or arg15 == "ABSORB" and "absorb" or "miss"
        local school = isFrostbolt and "frost" or weapon == "wand" and addon.ResolveSchool(sourceGUID, nil, spellSchool) or "neutral"
        addon.PlayCategory(category, false, sourceGUID, school, weapon)
    end
end

local function Initialize()
    if type(GabbaSoundsDB) ~= "table" then
        GabbaSoundsDB = {}
        -- The local upgrade copies the legacy saved-variable file under the
        -- new addon filename. Copy only supported settings, then validate them.
        if type(GabbaWandSoundsDB) == "table" then
            for key in pairs(defaults) do
                GabbaSoundsDB[key] = GabbaWandSoundsDB[key]
            end
        end
    end
    for key, default in pairs(defaults) do
        local value = GabbaSoundsDB[key]
        if (key == "channel" and value ~= "SFX" and value ~= "Master")
            or (key == "soundPack" and (type(value) ~= "string" or not addon.soundPacks[value]))
            or (key == "minimapAngle" and (type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge))
            or (key ~= "channel" and key ~= "soundPack" and key ~= "minimapAngle" and type(value) ~= "boolean") then
            GabbaSoundsDB[key] = default
        end
    end
    addon.db = GabbaSoundsDB
    addon.db.minimapAngle = addon.db.minimapAngle % 360
    playerGUID = UnitGUID("player")
    addon.UpdateOriginalMuting()
    if addon.InitializeMinimap then addon.InitializeMinimap() end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
frame:RegisterEvent("UNIT_INVENTORY_CHANGED")
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
frame:RegisterEvent("UNIT_SPELLCAST_START")
frame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
frame:SetScript("OnEvent", function(self, event, loadedName, castGUID, spellID)
    if event == "ADDON_LOADED" and loadedName == addonName then
        Initialize()
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        playerGUID = UnitGUID("player")
        addon.UpdateOriginalMuting()
        if addon.db and addon.db.enabled then
            addon.Print("Aktiv – " .. addon.soundPacks[addon.db.soundPack].label .. "; " .. (addon.db.allSources and "eigene und fremde Angriffe" or "eigene Angriffe") .. ". Einstellungen: /gabbasounds")
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        playerGUID = UnitGUID("player")
        addon.ResetSchools()
        addon.ResetWeapons()
        wipe(seenCasts)
        addon.ResetMageResults()
        currentPlayerCast = nil
    elseif (event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START"
        or event == "UNIT_SPELLCAST_SUCCEEDED") and loadedName == "player" then
        local key = addon.mageSpellByID[spellID]
        local spell = key and addon.mageSpells[key]
        if spell and ((event == "UNIT_SPELLCAST_START" and spell.castMode == "start")
            or (event == "UNIT_SPELLCAST_CHANNEL_START" and spell.castMode == "channel")
            or (event == "UNIT_SPELLCAST_SUCCEEDED" and spell.castMode ~= "channel")) then
            currentPlayerCast = castGUID
            if event == "UNIT_SPELLCAST_SUCCEEDED" or spell.castMode == "channel" then addon.BeginMageResult(playerGUID, key) end
            addon.PlayMageCast(playerGUID, castGUID, spellID)
        end
    elseif (event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED"
        or event == "UNIT_SPELLCAST_CHANNEL_STOP") and loadedName == "player"
        and castGUID == currentPlayerCast and addon.mageSpellByID[spellID] then
        StopSoundForSource(playerGUID .. ":cast")
        currentPlayerCast = nil
    elseif event == "PLAYER_EQUIPMENT_CHANGED" and loadedName == 18 then
        addon.ResetSchools("player")
        addon.ResetWeapons("player")
    elseif event == "UNIT_INVENTORY_CHANGED" and type(loadedName) == "string" then
        addon.ResetSchools(loadedName)
        addon.ResetWeapons(loadedName)
    elseif event == "PLAYER_LOGOUT" then
        addon.ResetMageResults()
        StopAllSounds()
        ReleaseOriginals()
    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        HandleCombatLog()
    end
end)

SLASH_GABBASOUNDS1 = "/gabbasounds"
SLASH_GABBASOUNDS2 = "/gws"
SLASH_GABBASOUNDS3 = "/zauberstab"
SlashCmdList.GABBASOUNDS = function(message)
    local command, argument = (message or ""):lower():match("^%s*(%S*)%s*(.-)%s*$")
    if command == "" then
        if addon.ToggleUI then
            addon.ToggleUI()
        end
    elseif command == "on" or command == "off" then
        addon.SetOption("enabled", command == "on")
        addon.Print(command == "on" and "Aktiviert." or "Deaktiviert; Original-Stummschaltung aufgehoben.")
    elseif command == "pack" then
        local aliases = { magie = "magic", custom = "spoken", eigene = "spoken", wand = "spoken_wand", bow = "spoken_bow", gun = "spoken_gun", pfeile = "spoken_bow", gewehr = "spoken_gun", frostbolt = "spoken_frostbolt", frostblitz = "spoken_frostbolt", mage = "spoken_mage", magier = "spoken_mage" }
        local selected = aliases[argument] or (addon.mageSpells[argument] and "spoken_" .. argument) or argument
        if addon.SetOption("soundPack", selected) then
            addon.Print("Soundpaket: " .. addon.soundPacks[selected].label)
        else
            addon.Print("Soundpaket wählen: /gws pack magic|spoken|wand|bow|gun|mage|frostbolt|fireball|blizzard …")
        end
    elseif command == "test" then
        local category, school = argument:match("^(%S+)%s*(%S*)$")
        local previewSpell = addon.mageSpells[school] and school
        local aliases = { schatten = "shadow", feuer = "fire", frost = "frost", kaelte = "frost", arkan = "arcane", natur = "nature", heilig = "holy" }
        school = aliases[school] or school
        if school == "" then school = nil end
        if (not addon.sounds[category] and category ~= "graze" and category ~= "cast") or (school and not previewSpell and not addon.schoolSounds[school]) then
            addon.Print("Hörprobe: /gws test hit|crit|resist|miss|absorb|graze|cast [Schadensart oder Zauber, z.B. fireball]")
        else
            addon.PlayCategory(category, true, nil, previewSpell and addon.mageSpells[previewSpell].school or school,
                previewSpell or category == "cast" and "frostbolt" or nil)
        end
    elseif command == "spokenonly" or command == "mute" or command == "all" or command == "hit" or command == "crit" or command == "resist" or command == "miss" or command == "absorb" or command == "graze" or command == "cast" then
        if argument ~= "on" and argument ~= "off" then
            addon.Print("Verwendung: /gws " .. command .. " on oder off")
        else
            addon.SetOption(command == "spokenonly" and "spokenOnly" or command == "mute" and "muteOriginal" or command == "all" and "allSources" or command, argument == "on")
            addon.Print(command .. ": " .. argument)
        end
    elseif command == "minimap" then
        if argument == "on" or argument == "off" then
            addon.SetOption("minimapHidden", argument == "off")
        else
            addon.Print("Minimap-Symbol: /gws minimap on oder off")
        end
    elseif command == "channel" then
        if argument == "sfx" or argument == "master" then
            addon.SetOption("channel", argument == "sfx" and "SFX" or "Master")
            addon.Print("Soundkanal: " .. addon.db.channel)
        else
            addon.Print("Verwendung: /gws channel sfx oder master")
        end
    elseif command == "status" then
        local mutedMage = 0
        for _, key in ipairs(addon.mageOrder) do if addon.mageOriginalsMuted[key] then mutedMage = mutedMage + 1 end end
        addon.Print((addon.db.enabled and "Aktiv" or "Deaktiviert") .. "; " .. (addon.db.allSources and "alle Schützen" or "eigene Schüsse")
            .. "; Zauberstab-Originale: " .. (addon.originalsMuted and "stumm" or "hörbar") .. "; Kanal: " .. addon.db.channel
            .. "; Frostblitz-Originale: " .. (addon.frostboltOriginalsMuted and "stumm" or "hörbar")
            .. "; Bogen/Armbrust-Originale: " .. (addon.bowOriginalsMuted and "stumm" or "hörbar")
            .. "; Gewehr-Originale: " .. (addon.gunOriginalsMuted and "stumm" or "hörbar")
            .. "; Magier-Stummschaltung: " .. mutedMage .. "/15 Zauber abgedeckt"
            .. "; Soundpaket: " .. addon.soundPacks[addon.db.soundPack].label
            .. "; Magier-Cast: " .. (addon.db.cast and "an" or "aus") .. " (" .. addon.stats.cast .. " abgespielt)"
            .. "; abgespielt: " .. addon.stats.hit .. " Treffer, " .. addon.stats.crit .. " Crits, " .. addon.stats.resist .. " Widerstände, " .. addon.stats.miss .. " Fehlschläge, " .. addon.stats.absorb .. " Absorptionen, " .. addon.stats.graze .. " Teiltreffer.")
    else
        addon.Print("/gws öffnet Einstellungen. Befehle: on, off, pack magic|spoken, spokenonly on|off, test hit|crit|resist|miss|absorb, all on|off, mute on|off, channel sfx|master, status")
    end
end
