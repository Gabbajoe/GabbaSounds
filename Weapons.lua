local _, addon = ...
local known = {}
local lastPrune = 0
local explicit = { [5019] = "wand", [2480] = "bow", [7919] = "bow", [7918] = "gun" }
local subclasses = { [2] = "bow", [3] = "gun", [18] = "bow", [19] = "wand" }

function addon.ResetWeapons(unit)
    if not unit then
        wipe(known)
    else
        local guid = UnitGUID(unit)
        if guid then known[guid] = nil end
    end
end

function addon.ResolveWeapon(guid, spellID)
    if not guid then return nil end
    local now = GetTime()
    if now - lastPrune > 30 then
        for source, entry in pairs(known) do
            if now - entry.seen > 120 then known[source] = nil end
        end
        lastPrune = now
    end
    local unit = addon.UnitForSource(guid)
    local link = unit and type(GetInventoryItemLink) == "function" and GetInventoryItemLink(unit, 18)
    local entry = known[guid]
    if entry and (now - entry.seen > 120 or (link and entry.link and entry.link ~= link)) then
        known[guid], entry = nil, nil
    end
    local weapon = explicit[spellID]
    if not weapon and link then
        local getInfo = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
        if type(getInfo) == "function" then
            local id, itemType, subType, equipLoc, icon, classID, subClassID = getInfo(link)
            if classID == 2 then weapon = subclasses[subClassID] end
        end
    end
    weapon = weapon or (entry and entry.weapon)
    if weapon then known[guid] = { weapon = weapon, link = link, seen = now } end
    -- Auto Shot (75) doesn't identify bow versus gun in the combat log.
    -- Keep it unknown unless equipment or a prior explicit shot identifies it.
    return weapon or (spellID == 75 and "ranged" or nil)
end
