local addonName, addon = ...
local panel
local checks = {}
local channelButton
local statsText
local noteText
local schoolButton
local previewIndex = 0
local packButton
local previewWeaponIndex = 0
local weaponOrder = { "wand", "bow", "gun" }
for _, key in ipairs(addon.mageOrder) do weaponOrder[#weaponOrder + 1] = key end
local weaponLabels = { wand = "Zauberstab", bow = "Pfeile / Armbrust", gun = "Schusswaffen", frostbolt = "Frostblitz", ranged = "unbekannte Fernkampfwaffe" }

for key, spell in pairs(addon.mageSpells) do weaponLabels[key] = spell.label end

local function PreviewWeapon()
    local pack = addon.db and addon.soundPacks[addon.db.soundPack]
    if pack and not pack.weapons then return pack.weapon end
    if pack and pack.mageOnly then return addon.mageOrder[previewWeaponIndex] or "frostbolt" end
    return weaponOrder[previewWeaponIndex] or addon.ResolveWeapon(UnitGUID("player")) or "wand"
end

local function CastPreviewWeapon()
    local selected = PreviewWeapon()
    return addon.mageSpells[selected] and selected or "frostbolt"
end

function addon.RefreshUI()
    if not panel or not panel:IsShown() or not addon.db then
        return
    end
    local pack = addon.soundPacks[addon.db.soundPack]
    packButton:SetText("Soundpaket: " .. pack.label)
    for key, check in pairs(checks) do
        if key == "spokenOnly" then
            check:SetChecked(addon.IsSpokenOnly())
        else
            check:SetChecked(addon.db[key])
        end
    end
    channelButton:SetText("Kanal: " .. (addon.db.channel == "SFX" and "Soundeffekte" or "Gesamtlautstärke"))
    schoolButton:SetText(pack.weapons and "Hörprobe: " .. weaponLabels[PreviewWeapon()] .. (previewWeaponIndex == 0 and " (automatisch)" or "")
        or pack.categories and "Hörprobe: " .. weaponLabels[pack.weapon]
        or previewIndex == 0 and "Hörprobe: eigener Zauberstab (" .. addon.schoolLabels[addon.PreviewSchool()] .. ")"
        or "Hörprobe: " .. addon.schoolLabels[addon.schoolOrder[previewIndex]])
    local labels = { hit = "Normale Treffer", crit = "Kritische Treffer", resist = "Widerstand", miss = "Verfehlen / Abprallen", absorb = "Absorbierte Schüsse", graze = "Teiltreffer (nur gesprochen)" }
    local bank = addon.GetBank("neutral", PreviewWeapon())
    for category, label in pairs(labels) do
        local pool = bank[category] or (category == "graze" and addon.sharedGraze) or {}
        checks[category].label:SetText(label .. ": " .. #pool .. " Varianten" .. (pack.schools and category ~= "graze" and " je Schadensart" or ""))
    end
    local castSpell = CastPreviewWeapon()
    local casts = #(addon.voiceBanks[castSpell].cast or {})
    checks.cast.label:SetText("Magier-Casts: " .. addon.mageSpells[castSpell].label .. " (" .. (casts > 0 and casts .. " Varianten" or "Aufnahme fehlt") .. ")")
    local pending = PreviewWeapon() == "frostbolt" or pack.weapon == "frostbolt"
    pending = pending and (#addon.voiceBanks.frostbolt.hit == 0 or #addon.voiceBanks.frostbolt.crit == 0)
    local mutedMage = 0
    for _, key in ipairs(addon.mageOrder) do if addon.mageOriginalsMuted and addon.mageOriginalsMuted[key] then mutedMage = mutedMage + 1 end end
    noteText:SetText((pending and "Frostblitz-Aufnahmen fehlen. " or "")
        .. "Originale: Stab " .. (addon.originalsMuted and "stumm" or "hörbar")
        .. ", Bogen " .. (addon.bowOriginalsMuted and "stumm" or "hörbar")
        .. ", Gewehr " .. (addon.gunOriginalsMuted and "stumm" or "hörbar")
        .. ". Magier-Stummschaltung: " .. mutedMage .. "/15 Zauber abgedeckt. Dateien global, teils geteilt.")
    statsText:SetText(string.format("Diese Sitzung: %d Treffer · %d Crits · %d Widerstände\n%d Fehlschläge · %d Absorptionen · %d Teiltreffer\n%d Magier-Casts",
        addon.stats.hit, addon.stats.crit, addon.stats.resist, addon.stats.miss, addon.stats.absorb, addon.stats.graze, addon.stats.cast))
end

local function BuildPanel()
    panel = CreateFrame("Frame", "GabbaSoundsPanel", UIParent, "BackdropTemplate")
    panel:SetSize(430, 790)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
    panel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    panel:SetScript("OnShow", addon.RefreshUI)
    tinsert(UISpecialFrames, "GabbaSoundsPanel")

    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -5, -5)

    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 25, -25)
    title:SetText("GabbaSounds")

    packButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    packButton:SetSize(375, 25)
    packButton:SetPoint("TOPLEFT", 25, -58)
    packButton:SetScript("OnClick", function()
        local selected = 1
        for index, key in ipairs(addon.packOrder) do
            if key == addon.db.soundPack then selected = index; break end
        end
        addon.SetOption("soundPack", addon.packOrder[selected % #addon.packOrder + 1])
    end)

    local function Checkbox(key, label, y)
        local check = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        check:SetPoint("TOPLEFT", 22, y)
        local text = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        text:SetPoint("LEFT", check, "RIGHT", 4, 0)
        text:SetText(label)
        check.label = text
        check:SetScript("OnClick", function(self) addon.SetOption(key, not not self:GetChecked()) end)
        checks[key] = check
    end
    Checkbox("enabled", "Addon aktiv", -103)
    Checkbox("allSources", "Eigene und fremde Angriffe", -137)
    Checkbox("muteOriginal", "Originalgeräusche stummschalten", -171)
    Checkbox("spokenOnly", "Nur gesprochene Sounds (alle unterstützten)", -205)
    checks.spokenOnly:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Nur gesprochene Sounds")
        GameTooltip:AddLine("An: alle gesprochenen Pakete automatisch, alle Trefferarten und fremde Angriffe; Originale stumm.", 1, 1, 1, true)
        GameTooltip:AddLine("Aus: Originale wieder hörbar, gesprochene Sounds bleiben ausgewählt.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    checks.spokenOnly:SetScript("OnLeave", function() GameTooltip:Hide() end)
    noteText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    noteText:SetPoint("TOPLEFT", 29, -243)
    noteText:SetWidth(367)
    noteText:SetJustifyH("LEFT")
    Checkbox("hit", "Normale Treffer", -301)
    Checkbox("crit", "Kritische Treffer", -333)
    Checkbox("resist", "Widerstand", -365)
    Checkbox("miss", "Verfehlen / Abprallen", -397)
    Checkbox("absorb", "Absorbierte Schüsse", -429)
    Checkbox("graze", "Teiltreffer-Sprüche nutzen", -461)

    schoolButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    schoolButton:SetSize(375, 25)
    schoolButton:SetPoint("TOPLEFT", 25, -508)
    schoolButton:SetScript("OnClick", function()
        if addon.soundPacks[addon.db.soundPack].weapons then
            local choices = addon.soundPacks[addon.db.soundPack].mageOnly and #addon.mageOrder or #weaponOrder
            previewWeaponIndex = (previewWeaponIndex + 1) % (choices + 1)
            addon.RefreshUI()
            return
        end
        if addon.soundPacks[addon.db.soundPack].categories then return end
        previewIndex = (previewIndex + 1) % (#addon.schoolOrder + 1)
        addon.RefreshUI()
    end)

    for index, item in ipairs({ { "hit", "Treffer hören" }, { "crit", "Crit hören" }, { "resist", "Widerstand hören" }, { "miss", "Fehlschlag hören" }, { "absorb", "Absorption hören" }, { "graze", "Teiltreffer hören" } }) do
        local category = item[1]
        local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        button:SetSize(120, 25)
        button:SetPoint("TOPLEFT", 25 + ((index - 1) % 3) * 130, -552 - math.floor((index - 1) / 3) * 32)
        button:SetText(item[2])
        button:SetScript("OnClick", function() addon.PlayCategory(category, true, nil, addon.schoolOrder[previewIndex], PreviewWeapon()) end)
    end
    Checkbox("cast", "Magier-Casts", -620)
    local castPreview = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    castPreview:SetSize(110, 25)
    castPreview:SetPoint("TOPLEFT", 290, -677)
    castPreview:SetText("Cast hören")
    castPreview:SetScript("OnClick", function() addon.PlayCategory("cast", true, nil, addon.mageSpells[CastPreviewWeapon()].school, CastPreviewWeapon()) end)

    channelButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    channelButton:SetSize(260, 25)
    channelButton:SetPoint("TOPLEFT", 25, -677)
    channelButton:SetScript("OnClick", function()
        addon.SetOption("channel", addon.db.channel == "SFX" and "Master" or "SFX")
    end)

    statsText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    statsText:SetPoint("TOPLEFT", 29, -721)
    statsText:SetWidth(372)
    statsText:SetJustifyH("LEFT")
    panel:Hide()
end

function addon.OpenUI()
    if not addon.db then return end
    if not panel then BuildPanel() end
    panel:Show()
end

function addon.ToggleUI()
    if not addon.db then
        return
    end
    if not panel then
        BuildPanel()
    end
    if panel:IsShown() then
        panel:Hide()
    else
        panel:Show()
    end
end
