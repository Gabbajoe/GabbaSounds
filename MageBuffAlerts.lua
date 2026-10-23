-- Local buff reminders: personal mage clips, personal/neutral priest clips.
local addonName, addon = ...
local manaClasses = { MAGE = true, PRIEST = true, WARLOCK = true, DRUID = true,
    PALADIN = true, SHAMAN = true, HUNTER = true }
addon.buffAlertProfiles = {
    mage = { character = "Minibobsel", class = "MAGE", label = "Minibobsels Magier-Buffwarnungen",
        enabled = "mageBuffAlerts", sound = "mageBuffSound", buffs = {
            { key = "intellect", label = "Intelligenz / Brillanz", option = "mageBuffIntellect", manaOnly = true,
              ids = { 1459, 1460, 1461, 10156, 10157, 23028 } },
            { key = "armor", label = "Eigener Magier-Rüstungsbuff", option = "mageBuffArmor", selfOnly = true,
              ids = { 168, 7300, 7301, 7302, 7320, 10219, 10220, 6117, 22782, 22783 } },
        } },
    priest = { character = "Bobselinchen", class = "PRIEST", label = "Priester-Buffwarnungen",
        enabled = "priestBuffAlerts", sound = "priestBuffSound", buffs = {
            { key = "fortitude", label = "Seelenstärke / Ausdauer", option = "priestBuffFortitude",
              ids = { 1243, 1244, 1245, 2791, 10937, 10938, 21562, 21564 } },
            { key = "spirit", label = "Göttlicher Willen / Willenskraft", option = "priestBuffSpirit", manaOnly = true,
              ids = { 14752, 14818, 14819, 27841, 27681 } },
            { key = "innerFire", label = "Eigenes Inneres Feuer", option = "priestBuffInnerFire", selfOnly = true,
              ids = { 588, 7128, 602, 1006, 10951, 10952 } },
            { key = "fearWard", label = "Furchtzauberschutz (Zwerg, optional)", option = "priestBuffFearWard",
              ids = { 6346 } },
        } },
}
local playerClasses = { WARRIOR = true, ROGUE = true }
for class in pairs(manaClasses) do playerClasses[class] = true end
local groupSpells = { [23028] = true, [21562] = true, [21564] = true, [27681] = true }
function addon.GetBuffAlertProfile()
    local _, class = UnitClass("player")
    return addon.buffAlertProfiles[class == "PRIEST" and "priest" or "mage"]
end
local function EligibleCharacter()
    local profile = addon.GetBuffAlertProfile()
    local _, class = UnitClass("player")
    if class == "PRIEST" then return true end
    return class == profile.class and type(UnitName) == "function" and UnitName("player") == profile.character
end
local function PersonalPriest()
    local _, class = UnitClass("player")
    return class == "PRIEST" and type(UnitName) == "function" and UnitName("player") == "Bobselinchen"
end

function addon.GetBuffAlertTitle()
    return addon.GetBuffAlertProfile().label
end

function addon.GetBuffAlertSound(key, phase)
    local priestBuff = false
    for _, buff in ipairs(addon.buffAlertProfiles.priest.buffs) do
        if buff.key == key then priestBuff = true; break end
    end
    if priestBuff then
        if PersonalPriest() then
            local personal = addon.buffAlertSounds[key]
            if personal and personal[phase] then return personal[phase] end
        end
        -- A neutral recording is safe for Bobselinchen too; never the reverse.
        local neutral = addon.priestBuffGenericSounds and addon.priestBuffGenericSounds[key]
        return neutral and neutral[phase]
    end
    local bank = addon.buffAlertSounds[key]
    return bank and bank[phase]
end

local function Buffs() return addon.GetBuffAlertProfile().buffs end
local states, known, displayed, queued, lastSound = {}, {}, {}, {}, {}
local frame, banner, text, activeHandle, activeUntil, displayUntil
local ready, scanAfter, elapsed = false, math.huge, 0

function addon.IsMageBuffCharacter()
    local _, class = UnitClass("player")
    return class == "MAGE" and type(UnitName) == "function" and UnitName("player") == "Minibobsel"
end

local function Enabled()
    return ready and addon.db and addon.db.enabled and addon.db[addon.GetBuffAlertProfile().enabled] and EligibleCharacter()
end

local function HideBanner()
    displayed = {}
    if banner then banner:Hide() end
end

function addon.StopMageBuffAudio()
    queued = {}
    if activeHandle and type(StopSound) == "function" then StopSound(activeHandle, 50) end
    activeHandle, activeUntil = nil, nil
end

function addon.ResetMageBuffAlerts()
    states, lastSound = {}, {}
    addon.StopMageBuffAudio()
    HideBanner()
end

local function SpellName(id)
    if type(GetSpellInfo) == "function" then return GetSpellInfo(id) end
    local info = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(id)
    return info and info.name
end

local function RefreshSpells()
    known = {}
    local isKnown = IsPlayerSpell or IsSpellKnown
    for _, buff in ipairs(Buffs()) do
        local entry = { ids = {}, names = {} }
        local learned = false
        for _, id in ipairs(buff.ids) do
            entry.ids[id] = true
            local name = SpellName(id)
            if name then entry.names[name] = true end
            if type(isKnown) == "function" and isKnown(id) then
                learned = true
                if not groupSpells[id] then entry.rangeID, entry.rangeName = id, name end
            end
        end
        if learned then known[buff.key] = entry end
    end
end

local function AliveAndHere(unit)
    return UnitIsConnected(unit) and UnitIsVisible(unit) and not UnitIsDeadOrGhost(unit)
end

-- Visibility alone does not guarantee that a group member is in buff range.
local function InBuffRange(unit, entry)
    if unit == "player" then return true end
    local inRange
    if C_Spell and type(C_Spell.IsSpellInRange) == "function" and entry.rangeID then
        inRange = C_Spell.IsSpellInRange(entry.rangeID, unit)
    elseif type(IsSpellInRange) == "function" and entry.rangeName then
        inRange = IsSpellInRange(entry.rangeName, unit)
    end
    if inRange ~= nil then return inRange == true or inRange == 1 end
    if type(UnitInRange) == "function" then
        local inside, checked = UnitInRange(unit)
        return (checked == true or checked == 1) and (inside == true or inside == 1)
    end
    return false -- Unknown range must never become a missing-buff alert.
end

local function NeedsBuff(unit, buff)
    local _, class = UnitClass(unit)
    return known[buff.key] and addon.db[buff.option] and AliveAndHere(unit) and playerClasses[class] == true
        and (not buff.selfOnly or unit == "player")
        and (not buff.manaOnly or manaClasses[class] == true)
        and InBuffRange(unit, known[buff.key])
end

local function Phase(remaining)
    return (not remaining or remaining <= 0) and "missing" or remaining <= 120 and "expiring" or "ok"
end

local function Units()
    local units = { "player" }
    local raid = IsInRaid()
    local count = raid and GetNumGroupMembers() or GetNumSubgroupMembers()
    for i = 1, count do
        local unit = (raid and "raid" or "party") .. i
        if not UnitIsUnit(unit, "player") then units[#units + 1] = unit end
    end
    return units
end

local function ReadAuras(unit)
    local active = {}
    for i = 1, 255 do
        local name, id, expires
        if C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function" then
            local aura = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL")
            if not aura then break end
            name, id, expires = aura.name, aura.spellId, aura.expirationTime
        elseif type(UnitBuff) == "function" then
            local auraName, _, _, _, _, expiration, _, _, _, spellID = UnitBuff(unit, i)
            name = auraName
            if not name then break end
            id, expires = spellID, expiration
        else
            return nil -- No reliable aura source; never treat an API failure as missing buffs.
        end
        local remaining = expires and expires > 0 and expires - GetTime() or math.huge
        for key, entry in pairs(known) do
            if (id and entry.ids[id]) or (name and entry.names[name]) then
                active[key] = math.max(active[key] or -math.huge, remaining)
            end
        end
    end
    return active
end

local function StillNeeded(key, phase)
    if not Enabled() or UnitIsDeadOrGhost("player") or UnitOnTaxi("player") then return false end
    for _, unit in ipairs(Units()) do
        local guid = UnitGUID(unit)
        if guid and states[guid] and states[guid][key] == phase then
            for _, buff in ipairs(Buffs()) do
                if buff.key == key and NeedsBuff(unit, buff) then
                    local active = ReadAuras(unit)
                    if active and Phase(active[key]) == phase then return true end
                end
            end
        end
    end
    return false
end

local function PlayVoice(key, phase, preview)
    local sound = addon.GetBuffAlertSound(key, phase)
    if not sound then
        if preview then addon.Print("Diese Buff-Warnung ist noch nicht eingesprochen/importiert.") end
        return false
    end
    local prefix = "Interface\\AddOns\\" .. addonName .. "\\Sounds\\"
    local filename = addon.NoggenfoggerSound(sound, true)
    local played, handle = PlaySoundFile(prefix .. filename, addon.db.channel, false)
    if not played and filename ~= sound then played, handle = PlaySoundFile(prefix .. sound, addon.db.channel, false) end
    if not played then
        addon.Print("Buff-Warnsound nicht geladen. Addon vollständig installieren und WoW neu starten.")
        return false
    end
    activeHandle, activeUntil = handle, GetTime() + (addon.soundDurations[sound] or 3)
    return true
end

function addon.PreviewMageBuff(key, phase)
    local valid = false
    for _, profile in pairs(addon.buffAlertProfiles) do
        for _, buff in ipairs(profile.buffs) do if buff.key == key then valid = true end end
    end
    if not addon.db or not valid or (phase ~= "expiring" and phase ~= "missing") then return false end
    addon.StopMageBuffAudio()
    return PlayVoice(key, phase, true)
end

local function PumpAudio()
    if activeUntil and GetTime() < activeUntil then return end
    activeHandle, activeUntil = nil, nil
    while #queued > 0 do
        local item = table.remove(queued, 1)
        local token = item.key .. ":" .. item.phase
        if addon.db[addon.GetBuffAlertProfile().sound] and StillNeeded(item.key, item.phase)
            and (not lastSound[token] or GetTime() - lastSound[token] >= 30) then
            if PlayVoice(item.key, item.phase, false) then
                lastSound[token] = GetTime()
                return
            end
        end
    end
end

local function Message(lines)
    local messages = {}
    for i = 1, math.min(#lines, 5) do messages[#messages + 1] = lines[i].message end
    if #lines > 5 then messages[#messages + 1] = "Weitere Warnungen im Chat: " .. (#lines - 5) end
    return table.concat(messages, "\n")
end

local function ShowWarnings(warnings)
    if not banner then
        banner = CreateFrame("Frame", "GabbaSoundsBuffWarning", UIParent)
        banner:SetSize(900, 240)
        banner:SetPoint("CENTER", UIParent, "CENTER", 0, 140)
        banner:SetFrameStrata("HIGH")
        text = banner:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", 28, "OUTLINE")
        text:SetPoint("CENTER")
        text:SetWidth(880)
        text:SetJustifyH("CENTER")
        text:SetTextColor(1, .5, .1)
    end
    displayed, displayUntil = warnings, GetTime() + 12
    text:SetText(Message(warnings))
    banner:SetAlpha(1)
    banner:Show()
end

local function CheckBuffs()
    if not Enabled() then addon.ResetMageBuffAlerts(); return end
    if GetTime() < scanAfter then return end
    if UnitIsDeadOrGhost("player") or UnitOnTaxi("player") then
        HideBanner(); addon.StopMageBuffAudio(); return
    end
    local nextStates, observed, warnings = {}, {}, {}
    for _, unit in ipairs(Units()) do
        local guid = UnitGUID(unit)
        if guid and AliveAndHere(unit) then
            local active = ReadAuras(unit)
            if active then
                local current, seen, previous = {}, {}, states[guid] or {}
                for key, value in pairs(previous) do current[key] = value end
                for _, buff in ipairs(Buffs()) do
                    if NeedsBuff(unit, buff) then
                        local phase = Phase(active[buff.key])
                        seen[buff.key] = phase
                        current[buff.key] = phase
                        if phase ~= "ok" and phase ~= previous[buff.key] then
                            warnings[#warnings + 1] = { guid = guid, key = buff.key, phase = phase,
                                message = (GetUnitName(unit, true) or unit) .. ": " .. buff.label
                                    .. (phase == "missing" and " fehlt!" or " läuft in höchstens 2 Min. ab!") }
                        end
                    end
                end
                nextStates[guid], observed[guid] = current, seen
            else nextStates[guid] = states[guid] end
        elseif guid then nextStates[guid] = states[guid] end
    end
    states = nextStates
    if #warnings > 0 then
        ShowWarnings(warnings)
        for _, warning in ipairs(warnings) do addon.Print(warning.message) end
        local pending = {}
        for _, item in ipairs(queued) do pending[item.key .. ":" .. item.phase] = true end
        -- Missing buffs take precedence; one clip per category/state, even for a raid.
        for _, phase in ipairs({ "missing", "expiring" }) do
            for _, warning in ipairs(warnings) do
                local token = warning.key .. ":" .. phase
                if phase == warning.phase and not pending[token] then
                    queued[#queued + 1] = { key = warning.key, phase = phase }
                    pending[token] = true
                end
            end
        end
    elseif #displayed > 0 then
        local remaining = {}
        for _, warning in ipairs(displayed) do
            if observed[warning.guid] and observed[warning.guid][warning.key] == warning.phase then
                remaining[#remaining + 1] = warning
            end
        end
        displayed = remaining
        if #remaining == 0 then HideBanner() else text:SetText(Message(remaining)) end
    end
end

function addon.MageBuffOptionsChanged(key)
    local profile = addon.GetBuffAlertProfile()
    local reset = key == "enabled" or key == profile.enabled
    for _, buff in ipairs(profile.buffs) do if key == buff.option then reset = true end end
    if reset then addon.ResetMageBuffAlerts() end
    if key == profile.sound and not addon.db[profile.sound] then addon.StopMageBuffAudio() end
    if addon.RefreshMageBuffUI then addon.RefreshMageBuffUI() end
end

function addon.InitializeMageBuffAlerts()
    if frame or not EligibleCharacter() then return end
    ready, scanAfter = true, GetTime() + 5
    RefreshSpells()
    frame = CreateFrame("Frame")
    for _, event in ipairs({ "PLAYER_LOGIN", "SPELLS_CHANGED", "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD", "PLAYER_LOGOUT" }) do frame:RegisterEvent(event) end
    frame:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_LEAVING_WORLD" or event == "PLAYER_LOGOUT" then
            scanAfter = math.huge
            addon.StopMageBuffAudio(); HideBanner()
        elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_LOGIN" then
            scanAfter = GetTime() + 5
            addon.StopMageBuffAudio(); HideBanner(); RefreshSpells()
        elseif event == "SPELLS_CHANGED" then RefreshSpells() end
    end)
    frame:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= 1 then elapsed = 0; CheckBuffs() end
        PumpAudio()
        if banner and banner:IsShown() and displayUntil then
            if GetTime() >= displayUntil then HideBanner()
            else banner:SetAlpha(math.min(1, (displayUntil - GetTime()) / 2)) end
        end
    end)
end

-- Gabba's legacy module yields for every priest to avoid duplicate alerts.
function GabbaSoundsOwnsPriestBuffAlerts()
    return ready and addon.GetBuffAlertProfile() == addon.buffAlertProfiles.priest and EligibleCharacter()
end
