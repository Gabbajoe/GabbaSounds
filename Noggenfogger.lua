local _, addon = ...

-- Only the shrink aura; skeleton and slow-fall have different spell IDs.
local SHRINK = 16595

function addon.RefreshNoggenfogger()
    local shrunk = false
    if C_UnitAuras and type(C_UnitAuras.GetAuraDataByIndex) == "function" then
        for index = 1, 255 do
            local aura = C_UnitAuras.GetAuraDataByIndex("player", index, "HELPFUL")
            if not aura then break end
            if aura.spellId == SHRINK then shrunk = true; break end
        end
    elseif type(UnitBuff) == "function" then
        for index = 1, 255 do
            local name, _, _, _, _, _, _, _, _, spellID = UnitBuff("player", index)
            if not name then break end
            if spellID == SHRINK then shrunk = true; break end
        end
    end
    addon.noggenfoggerShrunk = shrunk
end

function addon.NoggenfoggerSound(filename, preview, sourceGUID)
    if addon.db.noggenfoggerPitch and addon.noggenfoggerShrunk
        and (preview or not sourceGUID or sourceGUID == UnitGUID("player")) then
        return "noggenfogger\\" .. filename
    end
    return filename
end
