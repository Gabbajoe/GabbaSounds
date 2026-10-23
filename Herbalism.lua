local addonName, addon = ...
local names = {
    ["Gromsblood"] = "gromsblood", ["Gromsblut"] = "gromsblood",
    ["Black Lotus"] = "blacklotus", ["Schwarzer Lotus"] = "blacklotus",
}
addon.herbLabels = { gromsblood = "Gromsblut", blacklotus = "Schwarzer Lotus" }
local lastPlayed, warned = {}, {}
local hooked, hovered, elapsed, active = false, nil, 0, nil

function addon.RefreshHerbalism()
    addon.isHerbalist = (type(IsPlayerSpell) == "function" and IsPlayerSpell(2383))
        or (type(IsSpellKnown) == "function" and IsSpellKnown(2383)) or false
end

function addon.StopHerbSound()
    if active and active.expires > GetTime() and type(StopSound) == "function" then StopSound(active.handle, 50) end
    active, hovered = nil, nil
end

function addon.ResetHerbAlerts()
    addon.StopHerbSound()
    wipe(lastPlayed)
end

function addon.PlayHerb(key, preview)
    local db, filename = addon.db, addon.herbSounds[key]
    local label = addon.herbLabels[key]
    if not db or not label then return false end
    if not preview and (not db.enabled or not db.herbAlerts or not addon.isHerbalist) then return false end
    if not filename then
        if preview then addon.Print("Aufnahme für " .. label .. " fehlt.") end
        return false
    end
    local now = GetTime()
    if not preview and lastPlayed[key] and now - lastPlayed[key] < 30 then return false end
    local prefix = "Interface\\AddOns\\" .. addonName .. "\\Sounds\\"
    local pitched = addon.NoggenfoggerSound(filename, true)
    local played, handle = PlaySoundFile(prefix .. pitched, db.channel, false)
    if not played and pitched ~= filename then played, handle = PlaySoundFile(prefix .. filename, db.channel, false) end
    if not played then
        if not warned[key] then
            addon.Print("Kräuter-Sound nicht geladen: " .. label .. ". Addon vollständig installieren und WoW neu starten.")
            warned[key] = true
        end
        return false
    end
    -- Keep alert playback independent from combat sounds and buff reminders.
    addon.StopHerbSound()
    if handle then active = { handle = handle, expires = now + (addon.soundDurations[filename] or 3) } end
    if not preview then lastPlayed[key] = now end
    return true
end

local function MouseFocus()
    if type(GetMouseFoci) == "function" then
        local foci = GetMouseFoci()
        return foci and foci[1]
    end
    if type(GetMouseFocus) == "function" then return GetMouseFocus() end
end

local function ReadHerb(tooltip)
    if not tooltip:IsShown() then return nil end
    -- An item can have the exact same name as the gatherable world object.
    if tooltip.GetItem then
        local name, link = tooltip:GetItem()
        if name or link then return nil end
    end
    if tooltip.GetSpell and tooltip:GetSpell() then return nil end
    if tooltip.GetUnit and tooltip:GetUnit() then return nil end
    local focus = MouseFocus()
    -- Native Classic tooltips can be owned by either Minimap or UIParent.
    -- Requiring the actual minimap focus excludes stored addon pins above it.
    local minimap = Minimap and focus == Minimap and
        (tooltip:IsOwned(Minimap) or tooltip:IsOwned(UIParent))
    local world = WorldFrame and focus == WorldFrame and
        (tooltip:IsOwned(WorldFrame) or tooltip:IsOwned(UIParent))
    if not minimap and not world then return nil end
    local found
    local count = minimap and tooltip.NumLines and math.min(tooltip:NumLines(), 20) or 1
    for index = 1, count do
        local line = tooltip.GetLeftLine and tooltip:GetLeftLine(index) or _G["GameTooltipTextLeft" .. index]
        local text = line and line:GetText()
        if type(text) == "string" then
            text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):match("^%s*(.-)%s*$")
            local key = names[text]
            if key == "blacklotus" then return key end
            found = found or key
        end
    end
    return found
end

function addon.InitializeHerbAlerts()
    addon.RefreshHerbalism()
    if hooked or not GameTooltip or type(GameTooltip.HookScript) ~= "function" then return end
    hooked = true
    GameTooltip:HookScript("OnHide", function() hovered = nil end)
    GameTooltip:HookScript("OnUpdate", function(tooltip, delta)
        elapsed = elapsed + delta
        if elapsed < 0.15 then return end
        elapsed = 0
        local db = addon.db
        if not db or not db.enabled or not db.herbAlerts or not addon.isHerbalist then hovered = nil; return end
        local key = ReadHerb(tooltip)
        if key and key ~= hovered then addon.PlayHerb(key, false) end
        hovered = key
    end)
end
