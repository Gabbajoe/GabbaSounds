local _, addon = ...
addon.meleeOrder = { "blade", "blunt", "dagger", "fist" }
addon.meleeLabels = { blade = "Schwerter / Äxte", blunt = "Streitkolben / Stäbe",
    dagger = "Dolche", fist = "Faustwaffen / unbewaffnet", melee = "unbekannte Nahkampfwaffe" }
local subclasses = { [0] = "blade", [1] = "blade", [7] = "blade", [8] = "blade",
    [4] = "blunt", [5] = "blunt", [10] = "blunt", [15] = "dagger", [13] = "fist" }
local known = {}
local lastPrune = 0

function addon.ResetMeleeWeapons(unit)
    if not unit then wipe(known)
    else
        local guid = UnitGUID(unit)
        if guid then known[guid] = nil end
    end
end

function addon.ResolveMeleeWeapon(guid, offHand)
    local now, slot = GetTime(), offHand and 17 or 16
    if now - lastPrune > 30 then
        for source, hands in pairs(known) do
            for hand, entry in pairs(hands) do
                if now - entry.seen > 120 then hands[hand] = nil end
            end
            if not next(hands) then known[source] = nil end
        end
        lastPrune = now
    end
    local unit = addon.UnitForSource(guid)
    -- Form attacks need their own sound design. Do not label claws as the
    -- equipped staff. Other druids' current form cannot be inspected reliably.
    if unit and type(UnitClass) == "function" then
        local name, class = UnitClass(unit)
        local form = unit == "player" and type(GetShapeshiftFormID) == "function" and GetShapeshiftFormID()
        if class == "DRUID" and (unit ~= "player" or (form and form ~= 0)) then
            return nil
        end
    end
    if unit and type(GetInventoryItemLink) == "function" then
        local link = GetInventoryItemLink(unit, slot)
        local weapon
        if not link then
            if unit == "player" and not offHand then weapon = "fist" end
        else
            local getInfo = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
            if type(getInfo) == "function" then
                local id, itemType, subType, equipLoc, icon, classID, subClassID = getInfo(link)
                if classID == 2 then weapon = subclasses[subClassID] end
                -- Known unsupported items (shields, polearms, fishing poles)
                -- must not become a guessed supported weapon.
                if classID and not weapon then
                    if known[guid] then known[guid][slot] = nil end
                    return nil
                end
            end
            weapon = weapon or "melee"
        end
        known[guid] = known[guid] or {}
        known[guid][slot] = weapon and { weapon = weapon, seen = now } or nil
        return weapon
    end
    local entry = known[guid] and known[guid][slot]
    return entry and now - entry.seen <= 120 and entry.weapon or "melee"
end

function addon.HandleMeleeCombatLog(event, source, ...)
    if event ~= "SWING_DAMAGE" and event ~= "SWING_MISSED" then return false end
    if not source or not source:match("^Player%-") then return true end
    local db = addon.db
    local pack = addon.soundPacks[db.soundPack]
    if pack.mageOnly or (not pack.weapons and not addon.meleeLabels[pack.weapon]) then return true end
    local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, offHand = ...
    if event == "SWING_MISSED" then offHand = overkill end
    local weapon = addon.ResolveMeleeWeapon(source, offHand == true or offHand == 1)
    if not weapon then return true end
    if weapon == "melee" then
        -- Use a neutral reserve only with complete global melee replacement;
        -- never cache this as an identification of the unseen player's weapon.
        if not addon.meleeOriginalsMuted then return true end
        weapon = "blade"
    end
    if not pack.weapons and pack.weapon ~= weapon then return true end
    local category
    if event == "SWING_MISSED" then
        category = amount == "RESIST" and "resist" or amount == "ABSORB" and "absorb" or "miss"
    else
        local partial = type(amount) == "number" and amount > 0
            and ((type(resisted) == "number" and resisted > 0) or (type(blocked) == "number" and blocked > 0))
        category = (critical == true or critical == 1) and "crit"
            or ((glancing == true or glancing == 1 or partial) and db.graze and "graze") or "hit"
    end
    addon.PlayCategory(category, false, source, "neutral", weapon, true)
    return true
end
