local addonName, addon = ...
local ui = { pages = {}, nav = {}, checks = {}, previews = {}, selected = "general" }
addon.ui = ui
local WIDTH, HEIGHT, CONTENT = 760, 560, 538
local backdrop = { bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } }
local categories = {
    { "hit", "Normale Treffer" }, { "crit", "Kritische Treffer" },
    { "resist", "Widerstand" }, { "miss", "Verfehlen / Abprallen" },
    { "absorb", "Absorbierte Angriffe" }, { "graze", "Teiltreffer" },
}
local weaponOrder, labels = { "wand", "bow", "gun" }, { wand = "Zauberstab", bow = "Bogen / Armbrust", gun = "Gewehr" }
for _, key in ipairs(addon.meleeOrder) do weaponOrder[#weaponOrder + 1] = key; labels[key] = addon.meleeLabels[key] end
for key, spell in pairs(addon.mageSpells) do labels[key] = spell.label end
for key, spell in pairs(addon.priestSpells) do labels[key] = spell.label end

local function Place(frame, parent, x, y, width, height)
    frame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    if width and height then frame:SetSize(width, height) elseif width then frame:SetWidth(width) end
    return frame
end

local function Text(parent, text, x, y, width, style, height)
    local label = parent:CreateFontString(nil, "OVERLAY", style or "GameFontHighlight")
    Place(label, parent, x, y, width, height)
    label:SetJustifyH("LEFT"); label:SetText(text)
    return label
end

local function Surface(frame, r, g, b)
    frame:SetBackdrop(backdrop)
    frame:SetBackdropColor(r or .055, g or .065, b or .09, 1)
    frame:SetBackdropBorderColor(.23, .25, .32, 1)
end

local function Paint(button)
    button:SetBackdropColor(button.selected and .20 or .09, button.selected and .15 or .10, button.selected and .31 or .14, 1)
    button:SetBackdropBorderColor(button.selected and .64 or .25, button.selected and .48 or .27, button.selected and .87 or .35, 1)
end

local function Button(parent, text, x, y, width, height, callback)
    local button = Place(CreateFrame("Button", nil, parent, "BackdropTemplate"), parent, x, y, width, height or 30)
    Surface(button)
    local label = button:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    label:SetPoint("CENTER"); label:SetWidth(width - 12)
    button:SetFontString(label); button:SetText(text)
    button:SetScript("OnClick", callback)
    button:SetScript("OnEnter", function(self) if self:IsEnabled() then self:SetBackdropColor(.19, .17, .27, 1) end end)
    button:SetScript("OnLeave", Paint)
    Paint(button)
    return button
end

local function Check(parent, key, label, x, y, width)
    local check = Place(CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate"), parent, x, y, 26, 26)
    check.label = Text(parent, label, x + 31, y + 4, width - 31, "GameFontHighlight", 20)
    check.option = key
    check:SetScript("OnClick", function(self) addon.SetOption(self.option, not not self:GetChecked()) end)
    ui.checks[key] = check
    return check
end

local function Enabled(button, enabled)
    if enabled then button:Enable() else button:Disable() end
    button:SetAlpha(enabled and 1 or .4)
end

local function Page(key, title, description, name)
    local page = Place(CreateFrame("Frame", name, ui.frame), ui.frame, 194, 82, CONTENT, 438)
    page.title = Text(page, title, 0, 0, CONTENT, "GameFontNormalLarge", 24)
    page.description = Text(page, description, 0, 30, CONTENT, "GameFontHighlight", 34)
    ui.pages[key] = page; page:Hide()
    return page
end

local function ClosePicker()
    if ui.picker then ui.picker:Hide(); ui.pickerMask:Hide() end
end

local function FitWindow()
    ui.frame:SetScale(math.max(.1, math.min(1, (UIParent:GetWidth() - 32) / WIDTH, (UIParent:GetHeight() - 32) / HEIGHT)))
end

local function SelectPage(key)
    if not ui.pages[key] then key = "general" end
    ClosePicker()
    if addon.StopPreview then addon.StopPreview() end
    ui.selected = key
    for id, page in pairs(ui.pages) do if id == key then page:Show() else page:Hide() end end
    for id, button in pairs(ui.nav) do button.selected = id == key; Paint(button) end
    addon.RefreshUI()
end

local function OpenPicker()
    if ui.picker and ui.picker:IsShown() then ClosePicker(); return end
    if not ui.picker then
        ui.pickerMask = Place(CreateFrame("Button", nil, ui.frame), ui.frame, 0, 0, WIDTH, HEIGHT)
        ui.pickerMask:SetFrameLevel(ui.frame:GetFrameLevel() + 20)
        ui.pickerMask:SetScript("OnClick", ClosePicker)
        ui.picker = Place(CreateFrame("Frame", nil, ui.pickerMask, "BackdropTemplate"), ui.pickerMask, 194, 184, CONTENT, #addon.packOrder * 23 + 12)
        ui.picker:SetFrameLevel(ui.pickerMask:GetFrameLevel() + 1)
        Surface(ui.picker, .045, .05, .075)
        ui.packChoices = {}
        for index, key in ipairs(addon.packOrder) do
            local pack = key
            ui.packChoices[key] = Button(ui.picker, addon.soundPacks[key].label, 6, 6 + (index - 1) * 23, CONTENT - 12, 23, function()
                ClosePicker(); addon.SetOption("soundPack", pack)
            end)
        end
    end
    for key, button in pairs(ui.packChoices) do button.selected = addon.db.soundPack == key; Paint(button) end
    ui.pickerMask:Show(); ui.picker:Show()
end

local function BuildGeneral()
    local page = Page("general", "Deine Sounds", "Wähle dein Paket und lege fest, wann du die Aufnahmen hören möchtest.")
    ui.packButton = Button(page, "", 0, 72, CONTENT, 30, OpenPicker)
    Check(page, "allSources", "Eigene und fremde Angriffe", 0, 120, 260)
    Check(page, "muteOriginal", "Originalgeräusche stummschalten", 0, 158, 260)
    local spoken = Check(page, "spokenOnly", "Nur gesprochene Sounds", 0, 196, 260)
    spoken:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Nur gesprochene Sounds")
        GameTooltip:AddLine("An: alle gesprochenen Pakete und Trefferarten; Originale stumm.", 1, 1, 1, true)
        GameTooltip:AddLine("Aus: Originale wieder hörbar, gesprochene Sounds bleiben ausgewählt.", 1, 1, 1, true)
        GameTooltip:Show()
    end)
    spoken:SetScript("OnLeave", function() GameTooltip:Hide() end)
    Check(page, "noggenfoggerPitch", "Noggenfogger: beim Schrumpfen höher", 0, 234, 260)
    ui.channel = Button(page, "", 0, 282, 256, 30, function() addon.SetOption("channel", addon.db.channel == "SFX" and "Master" or "SFX") end)
    ui.minimap = Check(page, "minimapHidden", "Minimap-Symbol anzeigen", 0, 324, 260)
    ui.minimap:SetScript("OnClick", function(self) addon.SetOption("minimapHidden", not self:GetChecked()) end)
    Text(page, "Abspielen bei", 284, 115, 246, "GameFontNormal")
    for index, category in ipairs(categories) do Check(page, category[1], category[2], 280, 138 + (index - 1) * 29, 258) end
    Check(page, "cast", "Magier: Sound beim Zauberbeginn", 280, 312, 258)
    ui.interval = Button(page, "", 280, 353, 258, 28, function()
        local values, selected = { 0, .25, .5, .75, 1 }, 1
        for index, value in ipairs(values) do if addon.db.meleeInterval == value then selected = index; break end end
        addon.SetOption("meleeInterval", values[selected % #values + 1])
    end)
    ui.originals = Text(page, "", 0, 395, CONTENT, "GameFontHighlight", 38)
end

local function BuildSounds(id, title, order, magic)
    local page = Page(id, title, "Links auswählen, rechts anhören. Hörproben verändern dein aktives Soundpaket nicht.")
    local view = { page = page, order = order, selected = order[1], offset = 0, rows = {}, buttons = {}, counts = {}, magic = magic }
    ui.previews[id] = view
    local list = Place(CreateFrame("Frame", nil, page, "BackdropTemplate"), page, 0, 74, 178, 320)
    Surface(list)
    for index = 1, 8 do
        local row = Button(list, "", 6, 6 + (index - 1) * 33, 166, 31, function(self)
            view.selected = self.key
            if addon.StopPreview then addon.StopPreview() end
            addon.RefreshUI()
        end)
        view.rows[index] = row
    end
    view.previous = Button(list, "< Zurück", 6, 280, 80, 26, function() view.offset = math.max(0, view.offset - 8); addon.RefreshUI() end)
    view.next = Button(list, "Weiter >", 92, 280, 80, 26, function() view.offset = view.offset + 8; addon.RefreshUI() end)
    list:EnableMouseWheel(true)
    list:SetScript("OnMouseWheel", function(_, delta)
        view.offset = math.max(0, math.min(math.max(0, #order - 8), view.offset - delta))
        addon.RefreshUI()
    end)
    view.range = Text(page, "", 6, 403, 172, "GameFontDisableSmall", 26)
    view.title = Text(page, "", 196, 76, 342, "GameFontNormalLarge", 30)
    view.note = Text(page, "", 196, 110, 342, "GameFontHighlight", 30)
    local kinds = {}
    for _, category in ipairs(categories) do kinds[#kinds + 1] = category end
    if id == "mage" then kinds[#kinds + 1] = { "cast", "Zauberbeginn / Aktivieren" } end
    for index, category in ipairs(kinds) do
        local key, y = category[1], 151 + (index - 1) * 35
        Text(page, category[2], 196, y + 7, 181, "GameFontHighlight", 26)
        view.counts[key] = Text(page, "", 380, y + 7, 60, "GameFontDisableSmall", 20)
        view.buttons[key] = Button(page, "Hören", 447, y, 91, 28, function()
            addon.PlayCategory(key, true, nil, magic and view.selected or "neutral", magic and "wand" or view.selected, nil, magic and "magic" or "spoken")
        end)
    end
    view.activate = Button(page, "", 196, 407, 342, 30, function()
        addon.SetOption("soundPack", magic and "magic" or "spoken_" .. view.selected)
    end)
end

local function RefreshSounds(view)
    for index, row in ipairs(view.rows) do
        local key = view.order[view.offset + index]
        row.key = key
        if key then
            row:SetText(view.magic and addon.schoolLabels[key] or labels[key])
            row.selected = key == view.selected; Paint(row); row:Show()
        else row:Hide() end
    end
    Enabled(view.previous, view.offset > 0); Enabled(view.next, view.offset + 8 < #view.order)
    view.range:SetText(#view.order .. " Einträge" .. (#view.order > 8 and " · Mausrad zum Blättern" or ""))
    local key = view.selected
    view.title:SetText(view.magic and addon.schoolLabels[key] or labels[key])
    local spell = addon.mageSpells[key] or addon.priestSpells[key]
    local note = view.magic and "Synthetische Zauberstab-Sounds je Schadensart." or "Eigene Aufnahmen · zufällige Varianten ohne direkte Wiederholung."
    if key == "shadowwordpain" then note = "Beim Auftragen / Auffrischen; keine DoT-Ticks und keine Crits."
    elseif key == "holynova" then note = "Eine Reaktion für alle Schadensziele; keine Heilungsreaktion."
    elseif spell and spell.damage == false then note = "Dieser Zauber verwendet nur einen Sound beim Aktivieren."
    elseif view.page == ui.pages.priest then note = "Eigene Treffer- und Crit-Laute; noch keine Cast-Aufnahmen." end
    view.note:SetText(note)
    local bank = addon.GetBank(view.magic and key or "neutral", view.magic and "wand" or key, view.magic and "magic" or "spoken")
    for category, button in pairs(view.buttons) do
        local count = #(bank[category] or {})
        view.counts[category]:SetText(count .. " Clips"); Enabled(button, count > 0)
    end
    local pack = view.magic and "magic" or "spoken_" .. key
    local active = addon.db.soundPack == pack
    view.activate:SetText(active and "Dieses Paket ist aktiv" or view.magic and "Magie-Paket aktivieren" or "Nur dieses Paket aktivieren")
    Enabled(view.activate, not active)
end

local function BuildBuffs()
    local page = Page("buffs", "Buffwarnungen", "Lokale Erinnerungen: bei höchstens zwei Minuten Restzeit und wenn ein Buff fehlt.", "GabbaSoundsBuffPanel")
    ui.buffProfiles, ui.buffTabs = {}, {}
    ui.buffProfile = addon.GetBuffAlertProfile().class == "PRIEST" and "priest" or "mage"
    for index, id in ipairs({ "mage", "priest" }) do
        local profileKey, profile = id, addon.buffAlertProfiles[id]
        ui.buffTabs[id] = Button(page, id == "priest" and "Priester" or "Magier", (index - 1) * 274, 72, 264, 28, function()
            ui.buffProfile = profileKey
            addon.RefreshUI()
        end)
        local body = Place(CreateFrame("Frame", nil, page), page, 0, 120, CONTENT, 244)
        local view = { frame = body, checks = {}, rows = {} }
        ui.buffProfiles[id] = view
        view.checks[profile.enabled] = Check(body, profile.enabled, "Buffwarnungen aktiv", 0, 0, 260)
        view.checks[profile.sound] = Check(body, profile.sound, "Gesprochene Warnungen abspielen", 270, 0, 268)
        for rowIndex, buff in ipairs(profile.buffs) do
            local key, y = buff.key, 44 + (rowIndex - 1) * 43
            view.checks[buff.option] = Check(body, buff.option, buff.label, 0, y, 260)
            local row = { key = key, buttons = {} }
            for column, phase in ipairs({ "expiring", "missing" }) do
                local state = phase
                row.buttons[phase] = Button(body, phase == "expiring" and "2 Minuten hören" or "Fehlt hören", 275 + (column - 1) * 134, y, 129, 29, function()
                    addon.PreviewMageBuff(key, state)
                end)
            end
            view.rows[#view.rows + 1] = row
        end
        body:Hide()
    end
    ui.buffNote = Text(page, "", 0, 353, CONTENT, "GameFontHighlight", 40)
    Text(page, "Gruppenwarnungen nur für passende Klassen in bestätigter Buff-Reichweite. Nachbuffen macht die Warnung wieder scharf. Keine Nachrichten an die Gruppe.", 0, 398, CONTENT, "GameFontHighlight", 38)
end

local function RefreshBuffs()
    local profile, count = addon.buffAlertProfiles[ui.buffProfile], 0
    for id, view in pairs(ui.buffProfiles) do
        if id == ui.buffProfile then view.frame:Show() else view.frame:Hide() end
        ui.buffTabs[id].selected = id == ui.buffProfile; Paint(ui.buffTabs[id])
    end
    local view = ui.buffProfiles[ui.buffProfile]
    ui.buffChecks, ui.buffRows = view.checks, view.rows
    local priest = ui.buffProfile == "priest"
    for _, row in ipairs(ui.buffRows) do
        for phase, button in pairs(row.buttons) do
            local exists = addon.GetBuffAlertSound(row.key, phase) ~= nil
            if exists then count = count + 1 end
            Enabled(button, exists)
        end
    end
    local audience
    if priest then
        audience = addon.GetBuffAlertProfile().class == "PRIEST"
            and "Automatische Priester-Buffwarnungen für diesen Charakter."
            or "Hier nur Hörproben. Automatische Priester-Warnungen nur auf Priestern."
    elseif addon.IsMageBuffCharacter() then audience = "Minibobsel erkannt: persönliche Magier-Buffwarnungen aktivierbar."
    else audience = "Hier nur Hörproben. Automatische Magier-Warnungen nur für Minibobsel." end
    ui.buffNote:SetText(audience .. "\n" .. count .. "/" .. (#profile.buffs * 2) .. " Aufnahmen bereit.")
end

local function BuildHerbs()
    local page = Page("herbs", "Kräuter-Alarm", "Deine Aufnahme, wenn du Gromsblut oder Schwarzen Lotus im Tooltip siehst.", "GabbaSoundsHerbPanel")
    Check(page, "herbAlerts", "Kräuter-Alarm beim Darüberfahren", 0, 74, CONTENT)
    ui.herbNote = Text(page, "", 0, 118, CONTENT, "GameFontHighlight", 32)
    ui.herbButtons = {}
    for index, key in ipairs({ "gromsblood", "blacklotus" }) do
        local herb, y = key, 174 + (index - 1) * 84
        local card = Place(CreateFrame("Frame", nil, page, "BackdropTemplate"), page, 0, y, CONTENT, 66)
        Surface(card)
        Text(card, addon.herbLabels[key], 16, 13, 330, "GameFontNormal", 22)
        Text(card, "Eigene Sprachaufnahme", 16, 37, 330, "GameFontHighlight", 18)
        ui.herbButtons[key] = Button(card, "Hören", 418, 18, 100, 30, function() addon.PlayHerb(herb, true) end)
    end
    Text(page, "Maus über einen echten Kräuterpunkt auf der Minimap oder das Kraut in der Welt bewegen. Kräuterkunde erforderlich. Pro Kraut 30 Sekunden Pause; derselbe Tooltip wiederholt nicht. Gespeicherte Addon-Pins zählen nicht.", 0, 363, CONTENT, "GameFontHighlight", 65)
end

function addon.RefreshUI()
    if not ui.frame or not ui.frame:IsShown() or not addon.db then return end
    for key, check in pairs(ui.checks) do
        local value = key == "spokenOnly" and addon.IsSpokenOnly() or addon.db[key]
        if key == "minimapHidden" then value = not addon.db.minimapHidden end
        check:SetChecked(not not value)
    end
    ui.packButton:SetText("Soundpaket: " .. addon.soundPacks[addon.db.soundPack].label .. "  v")
    ui.channel:SetText("Kanal: " .. (addon.db.channel == "SFX" and "Soundeffekte" or "Gesamtlautstärke"))
    ui.interval:SetText(string.format("Nahkampf-Mindestpause: %.2f s", addon.db.meleeInterval))
    local covered = {}
    for _, entry in ipairs({ { addon.originalsMuted, "Zauberstab" }, { addon.bowOriginalsMuted, "Bogen" }, { addon.gunOriginalsMuted, "Gewehr" }, { addon.meleeOriginalsMuted, "Nahkampf" } }) do
        if entry[1] then covered[#covered + 1] = entry[2] end
    end
    local mage, priest = 0, 0
    for _, key in ipairs(addon.mageOrder) do if addon.mageOriginalsMuted[key] then mage = mage + 1 end end
    for _, key in ipairs(addon.priestOrder) do if addon.priestOriginalsMuted[key] then priest = priest + 1 end end
    if mage > 0 then covered[#covered + 1] = mage .. " Magierzauber" end
    if priest > 0 then covered[#covered + 1] = priest .. " Priesterzauber" end
    ui.originals:SetText(#covered > 0 and "Originale stumm: " .. table.concat(covered, ", ") .. ".\nGeteilte Sounddateien können auch ähnliche Zauber betreffen." or "Originalsounds sind hörbar. Deine Aufnahmen bleiben separat einstellbar.")
    ui.footer:SetText((addon.db.enabled and "Aktiv" or "Ausgeschaltet") .. "  ·  Sitzung: " .. addon.stats.hit .. " Treffer, " .. addon.stats.crit .. " Crits")
    local view = ui.previews[ui.selected]
    if view then RefreshSounds(view)
    elseif ui.selected == "buffs" then RefreshBuffs()
    elseif ui.selected == "herbs" then
        ui.herbNote:SetText(addon.isHerbalist and "Kräuterkunde erkannt. Der Tooltip-Alarm ist für diesen Charakter verfügbar." or "Keine Kräuterkunde erkannt. Die Aufnahmen kannst du trotzdem anhören.")
        for key, button in pairs(ui.herbButtons) do Enabled(button, addon.herbSounds[key] ~= nil) end
    end
end

local function BuildPanel()
    ui.frame = CreateFrame("Frame", "GabbaSoundsPanel", UIParent, "BackdropTemplate")
    ui.frame:SetSize(WIDTH, HEIGHT); ui.frame:SetPoint("CENTER")
    -- Match Gabba and ordinary Blizzard windows: click order controls stacking.
    ui.frame:SetFrameStrata("MEDIUM"); ui.frame:SetToplevel(true)
    Surface(ui.frame, .035, .04, .065)
    ui.frame:SetMovable(true); ui.frame:EnableMouse(true); ui.frame:SetClampedToScreen(true)
    ui.frame:RegisterForDrag("LeftButton")
    ui.frame:SetScript("OnDragStart", function(self) ClosePicker(); self:StartMoving() end)
    ui.frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    local icon = ui.frame:CreateTexture(nil, "ARTWORK")
    Place(icon, ui.frame, 22, 18, 38, 38); icon:SetTexture("Interface\\AddOns\\" .. addonName .. "\\Assets\\minimap.tga")
    Text(ui.frame, "GabbaSounds", 72, 16, 460, "GameFontNormalLarge", 25)
    Text(ui.frame, "Sounds, Hörproben und Erinnerungen", 72, 44, 460, "GameFontHighlight", 18)
    Check(ui.frame, "enabled", "Addon aktiv", 575, 24, 130)
    local close = CreateFrame("Button", nil, ui.frame, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", -8, -8)
    local sidebar = Place(CreateFrame("Frame", nil, ui.frame, "BackdropTemplate"), ui.frame, 16, 80, 158, 436)
    Surface(sidebar)
    for index, entry in ipairs({ { "general", "Allgemein" }, { "weapons", "Waffen" }, { "mage", "Magier" }, { "priest", "Priester" }, { "magic", "Zauberstab-Sounds" }, { "buffs", "Buffwarnungen" }, { "herbs", "Kräuter-Alarm" } }) do
        local key = entry[1]
        ui.nav[key] = Button(sidebar, entry[2], 8, 10 + (index - 1) * 44, 142, 36, function() SelectPage(key) end)
    end
    Text(sidebar, "Deine Auswahl wird je\nCharakter gespeichert.", 13, 382, 134, "GameFontDisableSmall", 34)
    ui.footer = Text(ui.frame, "", 194, 532, CONTENT, "GameFontHighlight", 18)
    Text(ui.frame, "/gws · Optionen", 28, 532, 150, "GameFontDisableSmall", 18)
    BuildGeneral()
    BuildSounds("weapons", "Waffen-Sounds", weaponOrder)
    BuildSounds("mage", "Magier-Sounds", addon.mageOrder)
    BuildSounds("priest", "Priester-Sounds", addon.priestOrder)
    BuildSounds("magic", "Zauberstab-Sounds", addon.schoolOrder, true)
    BuildBuffs(); BuildHerbs()
    ui.frame:SetScript("OnShow", function() FitWindow(); SelectPage(ui.selected) end)
    ui.frame:SetScript("OnHide", function()
        ClosePicker()
        for _, page in pairs(ui.pages) do page:Hide() end
        if addon.StopPreview then addon.StopPreview() end
    end)
    ui.frame:RegisterEvent("DISPLAY_SIZE_CHANGED"); ui.frame:RegisterEvent("UI_SCALE_CHANGED")
    ui.frame:SetScript("OnEvent", function() if ui.frame:IsShown() then FitWindow() end end)
    tinsert(UISpecialFrames, "GabbaSoundsPanel")
    ui.frame:Hide()
end

function addon.OpenUI(page)
    if not addon.db then return end
    if not ui.frame then BuildPanel() end
    if page and ui.pages[page] then ui.selected = page end
    if ui.frame:IsShown() then FitWindow(); SelectPage(ui.selected) else ui.frame:Show() end
end

function addon.ToggleUI()
    if not addon.db then return end
    if ui.frame and ui.frame:IsShown() then ui.frame:Hide() else addon.OpenUI() end
end

function addon.OpenHerbUI() addon.RefreshHerbalism(); addon.OpenUI("herbs") end
function addon.OpenMageBuffUI() addon.OpenUI("buffs") end
function addon.RefreshHerbUI() if ui.selected == "herbs" then addon.RefreshUI() end end
function addon.RefreshMageBuffUI() if ui.selected == "buffs" then addon.RefreshUI() end end
