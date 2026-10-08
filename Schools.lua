local addonName, addon = ...
local known = {}
local scanTooltip
local lastPrune = 0

local function EscapePattern(text)
    return (text:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
end

local function DamagePattern()
    -- Use the client's own localized weapon damage template. Capture only
    -- the school; numeric format placeholders are matched without captures.
    local template = DAMAGE_TEMPLATE_WITH_SCHOOL
    if type(template) ~= "string" then return nil end
    local parts, position = { "^%s*" }, 1
    while true do
        local first, last = template:find("%%[%d%$%.]*[dsf]", position)
        if not first then break end
        parts[#parts + 1] = EscapePattern(template:sub(position, first - 1))
        parts[#parts + 1] = template:sub(last, last) == "s" and "(.+)" or "[%d%.,]+"
        position = last + 1
    end
    parts[#parts + 1] = EscapePattern(template:sub(position)) .. "%s*$"
    return table.concat(parts)
end

function addon.SchoolFromDamageLine(text)
    if type(text) ~= "string" then return nil end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    local pattern = DamagePattern()
    local schoolText = pattern and text:match(pattern)
    -- Fallback for clients that do not export DAMAGE_TEMPLATE_WITH_SCHOOL.
    -- Requiring a leading weapon damage range excludes enchantment bonuses.
    if not pattern then
        schoolText = text:match("^%s*%d[%d%.,]*%s*%-%s*%d[%d%.,]*%s+(.+)$")
    end
    if not schoolText then return nil end
    for index = 1, 6 do
        local label = _G["RESISTANCE" .. index .. "_NAME"]
        if label and schoolText:find(label, 1, true) then
            return addon.schoolMasks[2 ^ index]
        end
    end
end

local function EquippedSchool(unit)
    if C_TooltipInfo and type(C_TooltipInfo.GetInventoryItem) == "function" then
        local data = C_TooltipInfo.GetInventoryItem(unit, 18)
        if data and data.lines then
            for _, line in ipairs(data.lines) do
                local school = addon.SchoolFromDamageLine(line.leftText)
                if school then return school end
            end
        end
        return nil
    end
    -- Era's legacy tooltip API: a separate hidden frame, never GameTooltip.
    if not scanTooltip then
        scanTooltip = CreateFrame("GameTooltip", addonName .. "SchoolScan", UIParent, "GameTooltipTemplate")
    end
    if type(scanTooltip.SetInventoryItem) ~= "function" then return nil end
    scanTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    scanTooltip:ClearLines()
    scanTooltip:SetInventoryItem(unit, 18)
    local school
    for index = 1, scanTooltip:NumLines() do
        local line = _G[addonName .. "SchoolScanTextLeft" .. index]
        school = addon.SchoolFromDamageLine(line and line:GetText())
        if school then break end
    end
    scanTooltip:Hide()
    return school
end

local function UnitForSource(guid)
    if UnitGUID("player") == guid then return "player" end
    if type(UnitTokenFromGUID) == "function" then
        local unit = UnitTokenFromGUID(guid)
        if unit and UnitGUID(unit) == guid then return unit end
    end
    for _, unit in ipairs({ "target", "focus", "mouseover" }) do
        if UnitGUID(unit) == guid then return unit end
    end
end
addon.UnitForSource = UnitForSource

function addon.ResetSchools(unit)
    if not unit then
        wipe(known)
    else
        local guid = UnitGUID(unit)
        if guid then known[guid] = nil end
    end
end

function addon.ResolveSchool(guid, damageSchool, spellSchool)
    if not guid then return "neutral" end
    local now = GetTime()
    if now - lastPrune > 30 then
        for source, entry in pairs(known) do
            if now - entry.seen > 120 then known[source] = nil end
        end
        lastPrune = now
    end
    local entry = known[guid]
    local unit = UnitForSource(guid)
    local link = unit and type(GetInventoryItemLink) == "function" and GetInventoryItemLink(unit, 18) or nil
    if entry and (now - entry.seen > 120 or (link and entry.link and link ~= entry.link)) then
        known[guid], entry = nil, nil
    end
    -- RANGE_DAMAGE's actual damageSchool is authoritative. Shoot's spell
    -- school is often physical (1), even when the wand deals shadow damage.
    local school = damageSchool and addon.schoolMasks[damageSchool]
    if damageSchool ~= nil and not school then
        known[guid] = nil
        return "neutral"
    end
    if not school then school = addon.schoolMasks[spellSchool] end
    if not school and entry then school = entry.school end
    if not school and unit then school = EquippedSchool(unit) end
    if school then
        known[guid] = { school = school, link = link or (entry and entry.link), seen = now }
    end
    return school or "neutral"
end

function addon.PreviewSchool()
    return addon.ResolveSchool(UnitGUID("player"))
end
