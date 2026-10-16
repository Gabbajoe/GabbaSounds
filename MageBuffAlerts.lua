-- Local reminders for Minibobsel, following Gabba's PriestBuffAlert state model.
local addonName, addon = ...
local buffs = {
    { key = "intellect", label = "Arkane Intelligenz / Brillanz", option = "mageBuffIntellect",
      ids = { 1459, 1460, 1461, 10156, 10157, 23028 } },
    { key = "armor", label = "Magier-Rüstungsbuff", option = "mageBuffArmor", selfOnly = true,
      ids = { 168, 7300, 7301, 7302, 7320, 10219, 10220, 6117, 22782, 22783 } },
}
local states, known, displayed, queued, lastSound = {}, {}, {}, {}, {}
local frame, banner, text, activeHandle, activeUntil, displayUntil
local ready, scanAfter, elapsed = false, math.huge, 0

function addon.IsMageBuffCharacter()
    local _, class = UnitClass("player")
    return class == "MAGE" and type(UnitName) == "function" and UnitName("player") == "Minibobsel"
end

local function Enabled()
    return ready and addon.db and addon.db.enabled and addon.db.mageBuffAlerts and addon.IsMageBuffCharacter()
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
    for _, buff in ipairs(buffs) do
        local entry = { ids = {}, names = {} }
        local learned = false
        for _, id in ipairs(buff.ids) do
            entry.ids[id] = true
            local name = SpellName(id)
            if name then entry.names[name] = true end
            if type(isKnown) == "function" and isKnown(id) then learned = true end
        end
        if learned then known[buff.key] = entry end
    end
end

local function AliveAndHere(unit)
    return UnitIsConnected(unit) and UnitIsVisible(unit) and not UnitIsDeadOrGhost(unit)
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
        if guid and states[guid] and states[guid][key] == phase and AliveAndHere(unit) then return true end
    end
    return false
end

local function PlayVoice(key, phase, preview)
    local sound = addon.buffAlertSounds[key] and addon.buffAlertSounds[key][phase]
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
    if not addon.db or (key ~= "intellect" and key ~= "armor") or (phase ~= "expiring" and phase ~= "missing") then return false end
    addon.StopMageBuffAudio()
    return PlayVoice(key, phase, true)
end

local function PumpAudio()
    if activeUntil and GetTime() < activeUntil then return end
    activeHandle, activeUntil = nil, nil
    while #queued > 0 do
        local item = table.remove(queued, 1)
        local token = item.key .. ":" .. item.phase
        if addon.db.mageBuffSound and StillNeeded(item.key, item.phase)
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
                local current, previous = {}, states[guid] or {}
                local _, class = UnitClass(unit)
                for _, buff in ipairs(buffs) do
                    if known[buff.key] and addon.db[buff.option]
                        and (not buff.selfOnly or unit == "player")
                        and (buff.key ~= "intellect" or (class ~= "WARRIOR" and class ~= "ROGUE")) then
                        local remaining = active[buff.key]
                        local phase = (not remaining or remaining <= 0) and "missing" or remaining <= 120 and "expiring" or "ok"
                        current[buff.key] = phase
                        if phase ~= "ok" and phase ~= previous[buff.key] then
                            warnings[#warnings + 1] = { guid = guid, key = buff.key, phase = phase,
                                message = (GetUnitName(unit, true) or unit) .. ": " .. buff.label
                                    .. (phase == "missing" and " fehlt!" or " läuft in höchstens 2 Min. ab!") }
                        end
                    end
                end
                nextStates[guid], observed[guid] = current, current
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
    if key == "enabled" or key == "mageBuffAlerts" or key == "mageBuffIntellect" or key == "mageBuffArmor" then addon.ResetMageBuffAlerts() end
    if key == "mageBuffSound" and not addon.db.mageBuffSound then addon.StopMageBuffAudio() end
    if addon.RefreshMageBuffUI then addon.RefreshMageBuffUI() end
end

function addon.InitializeMageBuffAlerts()
    if frame or not addon.IsMageBuffCharacter() then return end
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
