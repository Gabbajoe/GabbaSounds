local unpackValues = table.unpack or unpack
local total = 0
local function equal(actual, expected, message)
    assert(actual == expected, (message or "Values differ") .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end

local function setup(saved, legacy, auras)
    local state = { frames = {}, played = {}, stopped = {}, muted = {}, unmuted = {}, warmed = {}, warmStops = {}, muteDepth = {}, muteCalls = {}, messages = {}, guid = "Player-Test-Gabbaophant", time = 0, units = {}, links = {}, meleeLinks = {}, classes = {}, tooltipLines = {}, itemSubclasses = {} }
    local methods = {}
    state.auras = auras or {}
    C_UnitAuras = { GetAuraDataByIndex = function(unit, index, filter)
        equal(unit, "player"); equal(filter, "HELPFUL")
        local id = state.auras[index]
        if id then return { name = "Noggenfogger", spellId = id } end
    end }
    function UnitBuff(unit, index)
        equal(unit, "player")
        local id = state.auras[index]
        if id then return "Noggenfogger", nil, nil, nil, nil, nil, nil, nil, nil, id end
    end
    for _, name in ipairs({ "SetFrameStrata", "SetBackdrop", "SetMovable", "EnableMouse", "RegisterForDrag", "StartMoving", "StopMovingOrSizing", "SetWidth", "SetJustifyH", "SetFrameLevel", "ClearAllPoints", "RegisterForClicks", "SetHighlightTexture", "SetBackdropColor", "SetBackdropBorderColor", "SetClampedToScreen", "EnableMouseWheel" }) do
        methods[name] = function() end
    end
    function methods:SetWidth(width) self.width = width end
    function methods:SetFrameStrata(strata) self.strata = strata end
    function methods:SetToplevel(value) self.toplevel = value end
    function methods:SetScale(scale) self.scale = scale end
    function methods:Enable() self.disabled = false end
    function methods:Disable() self.disabled = true end
    function methods:IsEnabled() return not self.disabled end
    function methods:SetFontString(label) self.fontString = label end
    function methods:SetSize(width, height) self.width, self.height = width, height end
    function methods:SetPoint(...) self.point = { ... } end
    function methods:GetWidth() return self.width or 140 end
    function methods:GetHeight() return self.height or 140 end
    function methods:GetCenter() return 100, 100 end
    function methods:GetEffectiveScale() return 2 end
    function methods:GetFrameLevel() return 3 end
    function methods:HookScript(name, callback)
        local before = self.scripts[name]
        self.scripts[name] = before and function(...) before(...); callback(...) end or callback
    end
    function methods:SetTexture(path) self.texture = path end
    function methods:SetDesaturated(value) self.desaturated = value end
    function methods:SetAlpha(value) self.alpha = value end
    function methods:SetScript(name, callback) self.scripts[name] = callback end
    function methods:RegisterEvent(event) self.events[event] = true end
    function methods:UnregisterEvent(event) self.events[event] = nil end
    function methods:SetText(text) self.text = text end
    function methods:SetChecked(value) self.checked = value end
    function methods:GetChecked() return self.checked end
    function methods:IsShown() return self.shown end
    function methods:Hide()
        if not self.shown then return end
        self.shown = false
        if self.scripts.OnHide then self.scripts.OnHide(self) end
    end
    function methods:Show()
        if self.shown then return end
        self.shown = true
        if self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    local function widget()
        return setmetatable({ scripts = {}, events = {}, shown = true }, { __index = methods })
    end
    function methods:CreateFontString() return widget() end
    function methods:CreateTexture()
        local texture = widget()
        self.textures = self.textures or {}
        table.insert(self.textures, texture)
        return texture
    end
    UIParent = widget(); UIParent:SetSize(1280, 800)
    WorldFrame = widget()
    Minimap = widget()
    GameTooltip = widget()
    function GameTooltip:SetOwner(owner) self.owner = owner end
    function GameTooltip:IsOwned(owner) return self.owner == owner and self.shown end
    function GameTooltip:AddLine(text) self.lines = self.lines or {}; table.insert(self.lines, text) end
    function GameTooltip:GetItem() return state.herbItemName, state.herbItemLink end
    function GameTooltip:GetSpell() return state.herbSpell end
    function GameTooltip:GetUnit() return state.herbUnit end
    function GameTooltip:NumLines() return #(state.herbLines or {}) end
    function GameTooltip:GetLeftLine(index)
        local text = (state.herbLines or {})[index]
        if text then return { GetText = function() return text end } end
    end
    function GetMouseFoci() return state.focus and { state.focus } or {} end
    GetMouseFocus = nil
    function IsSpellKnown(id) return id == 2383 and state.herbalist or false end
    IsPlayerSpell = nil
    GetMinimapShape = nil
    function GetCursorPosition() return state.cursorX or 360, state.cursorY or 200 end
    UISpecialFrames = {}
    function CreateFrame(kind, name, parent, template)
        local frame = widget()
        frame.kind, frame.name, frame.parent, frame.template = kind, name, parent, template
        if name then _G[name] = frame end
        if template == "UIPanelCloseButton" then
            frame.scripts.OnClick = function() parent:Hide() end
        end
        table.insert(state.frames, frame)
        return frame
    end
    function UnitGUID(unit) return unit == "player" and state.guid or state.units[unit] end
    function UnitTokenFromGUID(guid)
        for unit, source in pairs(state.units) do if source == guid then return unit end end
    end
    function GetInventoryItemLink(unit, slot)
        if slot == 18 then return state.links[unit] end
        assert(slot == 16 or slot == 17)
        return state.meleeLinks[unit] and state.meleeLinks[unit][slot]
    end
    function UnitClass(unit) return "Class", state.classes[unit] end
    function GetShapeshiftFormID() return state.form end
    C_TooltipInfo = { GetInventoryItem = function(unit, slot)
        equal(slot, 18)
        local lines = {}
        for _, text in ipairs(state.tooltipLines[unit] or {}) do lines[#lines + 1] = { leftText = text } end
        return { lines = lines }
    end }
    C_Item = { GetItemInfoInstant = function(link)
        return 123, "Weapon", "Mock", "INVTYPE_RANGED", 1, 2, state.itemSubclasses[link]
    end }
    GetItemInfoInstant = nil
    DAMAGE_TEMPLATE_WITH_SCHOOL = "%d - %d %s Damage"
    RESISTANCE1_NAME, RESISTANCE2_NAME, RESISTANCE3_NAME = "Holy", "Fire", "Nature"
    RESISTANCE4_NAME, RESISTANCE5_NAME, RESISTANCE6_NAME = "Frost", "Shadow", "Arcane"
    function GetTime() return state.time end
    state.timers = {}
    C_Timer = { After = function(delay, callback) state.timers[#state.timers + 1] = { at = state.time + delay, callback = callback } end }
    function state:advance(seconds)
        self.time = self.time + seconds
        local pending = self.timers
        self.timers = {}
        for _, timer in ipairs(pending) do
            if timer.at <= self.time then timer.callback() else self.timers[#self.timers + 1] = timer end
        end
    end
    function GetSpellInfo(id) if id == 10 then return "Blizzard" end end
    function CombatLogGetCurrentEventInfo() return unpackValues(state.currentEvent, 1, 23) end
    function PlaySoundFile(path, channel, forceNoDuplicates)
        if type(path) == "number" then
            assert(state.muted[path], "Native sound must be muted before warm-up")
            table.insert(state.warmed, { id = path, channel = channel })
            return true, -path
        end
        table.insert(state.played, { path = path, channel = channel, forceNoDuplicates = forceNoDuplicates })
        if state.failPitch and path:find("\\noggenfogger\\", 1, true) then return false end
        if state.failPlayback then return false end
        return true, #state.played
    end
    function StopSound(handle)
        if handle < 0 then table.insert(state.warmStops, handle) else table.insert(state.stopped, handle) end
    end
    function MuteSoundFile(id)
        state.muteDepth[id] = (state.muteDepth[id] or 0) + 1
        state.muteCalls[id] = (state.muteCalls[id] or 0) + 1
        state.muted[id] = true
    end
    function UnmuteSoundFile(id)
        state.muteDepth[id] = math.max(0, (state.muteDepth[id] or 0) - 1)
        state.muted[id] = state.muteDepth[id] > 0 and true or nil
        table.insert(state.unmuted, id)
    end
    function wipe(values) for key in pairs(values) do values[key] = nil end end
    tinsert = table.insert
    DEFAULT_CHAT_FRAME = { AddMessage = function(_, message) table.insert(state.messages, message) end }
    SlashCmdList = {}
    GabbaSoundsDB = saved
    GabbaWandSoundsDB = legacy
    local addon = {}
    for _, file in ipairs({ "SoundData.lua", "CustomSoundData.lua", "Schools.lua", "Weapons.lua", "MeleeSoundIDs.lua", "Melee.lua", "MageSpells.lua", "MageEvents.lua", "PriestSpells.lua", "PriestEvents.lua", "Noggenfogger.lua", "BuffAlertSoundData.lua", "MageBuffAlerts.lua", "HerbSoundData.lua", "Herbalism.lua", "Core.lua", "UI.lua", "Minimap.lua" }) do
        assert(loadfile(file))("GabbaSounds", addon)
    end
    state.addon = addon
    function state:fire(event, argument, castGUID, spellID)
        local frame = self.frames[1]
        if frame.events[event] then frame.scripts.OnEvent(frame, event, argument, castGUID, spellID) end
    end
    function state:combat(event, spellID, sourceGUID, critical, missType, amount, resisted, school, spellSchool, blocked, absorbed)
        self.currentEvent = {
            [1] = 12345, [2] = event, [3] = false, [4] = sourceGUID or self.guid,
            [5] = "Gabbaophant", [6] = 0x511, [7] = 0,
            [8] = "Creature-Test", [9] = "Testziel", [10] = 0x10a48, [11] = 0,
            [12] = spellID or 5019, [13] = "Shoot", [14] = spellSchool or 1,
            [15] = missType or amount or 50, [16] = -1, [17] = school or 32,
            [18] = resisted or 0, [19] = blocked or 0, [20] = absorbed or 0, [21] = critical,
        }
        self:fire("COMBAT_LOG_EVENT_UNFILTERED")
    end
    function state:swing(options)
        local o = options or {}
        self.currentEvent = { [1] = self.time, [2] = o.miss and "SWING_MISSED" or "SWING_DAMAGE",
            [3] = false, [4] = o.source or self.guid, [5] = "Player", [6] = 0x511, [7] = 0,
            [8] = "Creature-Test", [9] = "Target", [10] = 0x10a48, [11] = 0 }
        if o.miss then
            self.currentEvent[12], self.currentEvent[13], self.currentEvent[14] = o.miss, o.offHand, 0
        else
            self.currentEvent[12], self.currentEvent[13], self.currentEvent[14] = 50, -1, 1
            self.currentEvent[15], self.currentEvent[16], self.currentEvent[17] = o.resisted or 0, o.blocked or 0, o.absorbed or 0
            self.currentEvent[18], self.currentEvent[19], self.currentEvent[20], self.currentEvent[21] = o.crit, o.glancing, o.crushing, o.offHand
        end
        self:fire("COMBAT_LOG_EVENT_UNFILTERED")
    end
    state:fire("ADDON_LOADED", "OtherAddon")
    equal(addon.db, nil, "Ignore other addon loading")
    state:fire("ADDON_LOADED", "GabbaSounds")
    state:fire("PLAYER_LOGIN")
    return state
end

local function test(name, callback)
    callback()
    total = total + 1
    print("ok - " .. name)
end

test("default pools and startup muting", function()
    local state = setup()
    equal(#state.addon.sounds.hit, 6)
    equal(#state.addon.sounds.crit, 4)
    equal(#state.addon.sounds.resist, 4)
    equal(#state.addon.sounds.miss, 2)
    equal(#state.addon.sounds.absorb, 2)
    equal(state.addon.db.allSources, true)
    local count = 0
    for _ in pairs(state.muted) do count = count + 1 end
    equal(count, 8)
    equal(state.addon.db.channel, "SFX")
end)

test("own normal, crit and full resistance each play exactly one sound", function()
    local state = setup()
    state:combat("RANGE_DAMAGE", 5019, nil, false)
    state:combat("RANGE_DAMAGE", 5019, nil, true)
    state:combat("RANGE_MISSED", 5019, nil, nil, "RESIST")
    equal(#state.played, 3)
    assert(state.played[1].path:find("\\hit_", 1, true))
    assert(state.played[2].path:find("\\crit_", 1, true))
    assert(state.played[3].path:find("\\resist_", 1, true))
    equal(state.addon.stats.hit, 1)
    equal(state.addon.stats.crit, 1)
    equal(state.addon.stats.resist, 1)
end)

test("ignore unrelated spells and cast events", function()
    local state = setup()
    state:combat("SPELL_DAMAGE", 14914, nil, true)
    state:combat("SPELL_CAST_START")
    state:combat("SPELL_CAST_SUCCESS")
    state:combat("SWING_DAMAGE")
    equal(#state.played, 0)
end)

test("other shooters receive hit, crit, resist, miss and absorption sounds", function()
    local state = setup()
    state:combat("RANGE_DAMAGE", 5019, "OtherPlayer", false)
    state:combat("RANGE_DAMAGE", 5019, "OtherPlayer", true)
    state:combat("RANGE_MISSED", 5019, "OtherPlayer", nil, "RESIST")
    state:combat("RANGE_MISSED", 5019, "OtherPlayer", nil, "MISS")
    state:combat("RANGE_MISSED", 5019, "OtherPlayer", nil, "ABSORB")
    equal(#state.played, 5)
    for _, kind in ipairs({ "hit", "crit", "resist", "miss", "absorb" }) do
        equal(state.addon.stats[kind], 1)
    end
    assert(state.played[4].path:find("\\miss_", 1, true))
    assert(state.played[5].path:find("\\absorb_", 1, true))
end)

test("all other miss types use a pass-by / deflection sound", function()
    local state = setup()
    for _, reason in ipairs({ "DODGE", "PARRY", "BLOCK", "IMMUNE", "EVADE", "DEFLECT", "UnknownFutureMiss" }) do
        state:combat("RANGE_MISSED", 5019, nil, nil, reason)
    end
    equal(state.addon.stats.miss, 7)
    equal(state.addon.stats.resist, 0)
end)

test("single-player scope retains others' original sounds", function()
    local state = setup()
    SlashCmdList.GABBASOUNDS("all off")
    equal(state.addon.db.allSources, false)
    equal(state.addon.originalsMuted, false)
    equal(#state.unmuted, 8)
    state:combat("RANGE_DAMAGE", 5019, "OtherPlayer", true)
    equal(#state.played, 0)
    state:combat("RANGE_DAMAGE")
    equal(#state.played, 1)
    SlashCmdList.GABBASOUNDS("all on")
    equal(state.addon.originalsMuted, true)
end)

test("every category is required for global original muting", function()
    for _, kind in ipairs({ "hit", "crit", "resist", "miss", "absorb" }) do
        local state = setup()
        state.addon.SetOption(kind, false)
        equal(state.addon.originalsMuted, false, "Keep original for disabled " .. kind)
        equal(state.muted[568935], nil)
        state.addon.SetOption(kind, true)
        equal(state.addon.originalsMuted, true)
    end
end)

test("concurrent shooters do not cut off one another", function()
    local state = setup()
    state:combat("RANGE_DAMAGE", 5019, "ShooterA", false)
    state:combat("RANGE_DAMAGE", 5019, "ShooterB", true)
    equal(#state.stopped, 0)
    equal(state.played[1].forceNoDuplicates, false)
    state:combat("RANGE_DAMAGE", 5019, "ShooterA", false)
    equal(#state.stopped, 1)
    equal(state.stopped[1], 1)
    state.addon.PlayCategory("hit", true)
    equal(#state.stopped, 1, "Preview must not stop a shooter's sound")
    state:fire("PLAYER_LOGOUT")
    equal(#state.stopped, 4, "Stop all three remaining owned handles")
end)

test("expired sound handles are discarded without stopping unrelated audio", function()
    local state = setup()
    state:combat("RANGE_DAMAGE", 5019, "ShooterA")
    state.time = 2
    state:combat("RANGE_DAMAGE", 5019, "ShooterB")
    equal(#state.stopped, 0)
    state:fire("PLAYER_LOGOUT")
    equal(#state.stopped, 1)
    equal(state.stopped[1], 2)
end)

test("partial resistance stays a normal hit; zero damage is still a hit", function()
    local state = setup()
    state:combat("RANGE_DAMAGE", 5019, nil, false, nil, 30, 20)
    state:combat("RANGE_DAMAGE", 5019, nil, false, nil, 0)
    equal(state.addon.stats.hit, 2)
    equal(state.addon.stats.resist, 0)
end)

test("numeric crit flags and spell-equivalent events", function()
    local state = setup()
    state:combat("SPELL_DAMAGE", 5019, nil, 1)
    state:combat("SPELL_MISSED", 5019, nil, nil, "RESIST")
    equal(state.addon.stats.crit, 1)
    equal(state.addon.stats.resist, 1)
end)

test("all variants are reachable with no adjacent repeat in a category", function()
    local state = setup()
    math.randomseed(812)
    for _, kind in ipairs({ "hit", "crit", "resist", "miss", "absorb" }) do
        local previous, seen = nil, {}
        for _ = 1, 100 do
            assert(state.addon.PlayCategory(kind, true))
            local path = state.played[#state.played].path
            assert(path ~= previous, "Immediate repeat for " .. kind)
            seen[path] = true
            previous = path
        end
        local count = 0
        for _ in pairs(seen) do count = count + 1 end
        equal(count, #state.addon.sounds[kind])
    end
    equal(state.addon.stats.hit, 0, "Previews do not count as combat")
end)

test("disable and category switches stop playback and restore originals", function()
    local state = setup()
    state.muted[999999] = true -- Simulate an unrelated sound muted elsewhere.
    state.addon.SetOption("crit", false)
    state:combat("RANGE_DAMAGE", 5019, nil, true)
    equal(#state.played, 0, "Disabled crit must not fall back to a normal hit")
    state:combat("RANGE_DAMAGE")
    SlashCmdList.GABBASOUNDS("off")
    equal(#state.unmuted, 8)
    assert(state.muted[999999], "Unrelated mute must stay intact")
    equal(#state.stopped, 1)
    state:combat("RANGE_DAMAGE")
    equal(#state.played, 1)
    state.addon.SetOption("enabled", true)
    state.addon.SetOption("hit", false)
    state.addon.SetOption("resist", false)
    equal(state.muted[568935], nil, "All categories disabled restores originals")
end)

test("playback failure releases muting and recovers on successful preview", function()
    local state = setup()
    state.failPlayback = true
    state:combat("RANGE_DAMAGE")
    equal(#state.unmuted, 8)
    equal(state.addon.stats.hit, 0)
    local warnings = #state.messages
    state:combat("RANGE_DAMAGE")
    equal(#state.messages, warnings, "Only warn once")
    state.failPlayback = false
    state.addon.PlayCategory("hit", true)
    assert(state.muted[568935], "Successful playback resumes configured muting")
end)

test("saved options are validated, and slash commands choose the channel", function()
    local state = setup({ enabled = "wrong", channel = "Music", hit = false, crit = false, resist = true })
    equal(state.addon.db.enabled, true)
    equal(state.addon.db.channel, "SFX")
    equal(state.addon.db.hit, false)
    equal(state.addon.SetOption("channel", "Music"), false)
    equal(state.addon.SetOption("unknown", true), false)
    SlashCmdList.GABBASOUNDS("channel master")
    SlashCmdList.GABBASOUNDS("test resist")
    equal(state.played[1].channel, "Master")
    SlashCmdList.GABBASOUNDS("mute off")
    equal(state.muted[568935], nil)
    SlashCmdList.GABBASOUNDS("crit on")
    equal(state.addon.db.crit, true)
    local count = #state.played
    SlashCmdList.GABBASOUNDS("test nope")
    equal(#state.played, count)
end)

test("world changes refresh player GUID; logout releases owned sound and mutes", function()
    local state = setup()
    local oldGUID = state.guid
    state.addon.SetOption("allSources", false)
    state.guid = "Player-New"
    state:fire("PLAYER_ENTERING_WORLD")
    state:combat("RANGE_DAMAGE", 5019, oldGUID)
    equal(#state.played, 0)
    state:combat("RANGE_DAMAGE")
    equal(#state.played, 1)
    state:fire("PLAYER_LOGOUT")
    equal(#state.stopped, 1)
    equal(#state.unmuted, 8)
end)

test("settings panel opens, previews work, checkboxes save, close and Escape work", function()
    local state = setup()
    SlashCmdList.GABBASOUNDS("")
    local ui = state.addon.ui
    assert(ui.frame:IsShown())
    equal(#UISpecialFrames, 1); equal(UISpecialFrames[1], "GabbaSoundsPanel")
    for key, button in pairs(ui.nav) do
        button.scripts.OnClick(button)
        equal(ui.selected, key)
        for id, page in pairs(ui.pages) do equal(page:IsShown(), id == key) end
    end
    state.addon.OpenUI("weapons")
    local view = ui.previews.weapons
    for _, category in ipairs({"hit", "crit", "resist", "miss", "absorb", "graze"}) do
        assert(view.buttons[category]:IsEnabled())
        view.buttons[category].scripts.OnClick()
    end
    equal(#state.played, 6); equal(state.addon.stats.hit, 0)
    ui.checks.enabled:SetChecked(false); ui.checks.enabled.scripts.OnClick(ui.checks.enabled)
    equal(state.addon.db.enabled, false)
    SlashCmdList.GABBASOUNDS("")
    equal(ui.frame:IsShown(), false)
    for _, page in pairs(ui.pages) do equal(page:IsShown(), false) end
    SlashCmdList.GABBASOUNDS("")
    for _, frame in ipairs(state.frames) do
        if frame.template == "UIPanelCloseButton" then frame.scripts.OnClick(frame) end
    end
    equal(ui.frame:IsShown(), false)
    state.addon.OpenUI("priest")
    _G[UISpecialFrames[1]]:Hide()
    for _, page in pairs(ui.pages) do equal(page:IsShown(), false) end
end)

test("replay Gabbaophant's captured wand events", function()
    local fixture = assert(loadfile("tests/fixtures/gabbaophant_wand.lua"))()
    local state = setup()
    for _, event in ipairs(fixture.events) do
        state:combat(event.event, 5019, nil, event.critical, event.missType, event.amount, event.resisted, event.school)
        if event.school then
            local school = state.addon.schoolMasks[event.school]
            assert(school and state.played[#state.played].path:find("_" .. school .. "_", 1, true), "Captured actual damage school")
        end
    end
    for _, category in ipairs({ "hit", "crit", "resist", "miss", "absorb" }) do
        equal(state.addon.stats[category], fixture.expected[category], "Captured " .. category)
    end
    equal(#state.played, #fixture.events, "Exactly one sound per recorded result")
end)

local function lastSchool(state, school, category)
    local path = state.played[#state.played].path
    assert(path:find("\\" .. category .. "_" .. school .. "_", 1, true), "Wrong school/category: " .. path)
end

test("each magic school has six normal, four crit, four resist and extra outcome sounds", function()
    local state = setup()
    local schools, files, primary = 0, {}, 0
    for mask, school in pairs(state.addon.schoolMasks) do
        schools = schools + 1
        for category, count in pairs({ hit = 6, crit = 4, resist = 4, miss = 2, absorb = 2 }) do
            local pool = state.addon.schoolSounds[school][category]
            equal(#pool, count, school .. " " .. category)
            for _, filename in ipairs(pool) do
                assert(not files[filename], "Shared audio across banks")
                files[filename] = true
                assert(state.addon.soundDurations[filename] > 0)
                local file = assert(io.open("Sounds/" .. filename, "rb"))
                equal(file:read(4), "OggS", "Actual OGG file")
                file:close()
                if category == "hit" or category == "crit" or category == "resist" then primary = primary + 1 end
            end
        end
    end
    equal(schools, 6)
    equal(primary, 84)
end)

test("actual damage school overrides Shoot's physical spell school for all six schools", function()
    local state = setup()
    for mask, school in pairs(state.addon.schoolMasks) do
        state:combat("RANGE_DAMAGE", 5019, nil, false, nil, 50, 0, mask)
        lastSchool(state, school, "hit")
        state:combat("RANGE_DAMAGE", 5019, nil, true, nil, 80, 0, mask)
        lastSchool(state, school, "crit")
        state:combat("RANGE_MISSED", 5019, nil, nil, "RESIST")
        lastSchool(state, school, "resist")
        state:combat("RANGE_MISSED", 5019, nil, nil, "ABSORB")
        lastSchool(state, school, "absorb")
        state:combat("RANGE_MISSED", 5019, nil, nil, "MISS")
        lastSchool(state, school, "miss")
    end
end)

test("school cache belongs to the shooter, not the most recent global hit", function()
    local state = setup()
    state:combat("RANGE_DAMAGE", 5019, "ShadowPlayer", false, nil, 50, 0, 32)
    state:combat("RANGE_DAMAGE", 5019, "FirePlayer", false, nil, 50, 0, 4)
    state:combat("RANGE_MISSED", 5019, "ShadowPlayer", nil, "RESIST")
    lastSchool(state, "shadow", "resist")
    state:combat("RANGE_MISSED", 5019, "FirePlayer", nil, "RESIST")
    lastSchool(state, "fire", "resist")
end)

test("first own resisted shot is recognized from the equipped wand tooltip", function()
    local state = setup()
    state.tooltipLines.player = { "Wand", "Equip: Increases Shadow damage by 20.", "21 - 40 Frost Damage" }
    state.links.player = "item:wand-frost"
    state:combat("RANGE_MISSED", 5019, nil, nil, "RESIST")
    lastSchool(state, "frost", "resist")
end)

test("Classic legacy scan uses a hidden tooltip and excludes enchantments", function()
    local state = setup()
    C_TooltipInfo = nil
    local modernCreate = CreateFrame
    function CreateFrame(kind, name, parent, template)
        local frame = modernCreate(kind, name, parent, template)
        if kind == "GameTooltip" then
            frame.SetOwner = function() end
            frame.ClearLines = function() end
            frame.SetInventoryItem = function(_, unit, slot) equal(unit, "player"); equal(slot, 18) end
            frame.NumLines = function() return 2 end
            _G[name .. "TextLeft1"] = { GetText = function() return "Enchant: +10 Fire Damage" end }
            _G[name .. "TextLeft2"] = { GetText = function() return "12 - 30 Holy Damage" end }
        end
        return frame
    end
    state:combat("RANGE_MISSED", 5019, nil, nil, "RESIST")
    lastSchool(state, "holy", "resist")
    equal(GabbaSoundsSchoolScan:IsShown(), false)
end)

test("localized damage templates and color codes are parsed without confusing enchantments", function()
    local state = setup()
    DAMAGE_TEMPLATE_WITH_SCHOOL = "%d - %d %sschaden"
    RESISTANCE5_NAME = "Schatten"
    equal(state.addon.SchoolFromDamageLine("|cff00ff0010 - 20 Schattenschaden|r"), "shadow")
    equal(state.addon.SchoolFromDamageLine("Erhöht Schattenschaden um 10."), nil)
    equal(state.addon.SchoolFromDamageLine("+10 Schattenschaden"), nil)
    DAMAGE_TEMPLATE_WITH_SCHOOL = "%1$d - %2$d %3$s Damage"
    equal(state.addon.SchoolFromDamageLine("10 - 20 Fire Damage"), "fire")
    DAMAGE_TEMPLATE_WITH_SCHOOL = nil
    equal(state.addon.SchoolFromDamageLine("10 - 20 Frost Damage"), "frost")
end)

test("changing the own wand invalidates its old school before a resisted first shot", function()
    local state = setup()
    state.links.player = "item:wand-shadow"
    state:combat("RANGE_DAMAGE")
    state.links.player = "item:wand-fire"
    state.tooltipLines.player = { "10 - 20 Fire Damage" }
    state:fire("PLAYER_EQUIPMENT_CHANGED", 18)
    state:combat("RANGE_MISSED", 5019, nil, nil, "RESIST")
    lastSchool(state, "fire", "resist")
end)

test("visible remote equipment changes refresh its school using available tooltip data", function()
    local state = setup()
    state.units.target = "OtherPlayer"
    state.links.target = "item:shadow-wand"
    state:combat("RANGE_DAMAGE", 5019, "OtherPlayer", false, nil, 50, 0, 32)
    state.links.target = "item:nature-wand"
    state.tooltipLines.target = { "18 - 29 Nature Damage" }
    UnitTokenFromGUID = nil -- target/mouseover fallback works on older clients.
    state:combat("RANGE_MISSED", 5019, "OtherPlayer", nil, "RESIST")
    lastSchool(state, "nature", "resist")
    state.tooltipLines.target = { "18 - 29 Arcane Damage" }
    state:fire("UNIT_INVENTORY_CHANGED", "target")
    state:combat("RANGE_MISSED", 5019, "OtherPlayer", nil, "RESIST")
    lastSchool(state, "arcane", "resist")
end)

test("unknown remote resistance uses neutral reserve until an actual hit identifies it", function()
    local state = setup()
    state:combat("RANGE_MISSED", 5019, "UnknownPlayer", nil, "RESIST")
    local filename = state.played[1].path:match("([^\\]+)$")
    local found
    for _, sound in ipairs(state.addon.schoolSounds.neutral.resist) do if sound == filename then found = true end end
    assert(found, "First unknown shot must not invent a damage school")
    state:combat("RANGE_DAMAGE", 5019, "UnknownPlayer", false, nil, 50, 0, 64)
    state:combat("RANGE_MISSED", 5019, "UnknownPlayer", nil, "RESIST")
    lastSchool(state, "arcane", "resist")
end)

test("expired and world-reset school caches do not misclassify unseen weapons", function()
    local state = setup()
    state:combat("RANGE_DAMAGE", 5019, "OtherPlayer", false, nil, 50, 0, 4)
    state.time = 121
    equal(state.addon.ResolveSchool("OtherPlayer"), "neutral")
    state:combat("RANGE_DAMAGE", 5019, "OtherPlayer", false, nil, 50, 0, 32)
    state:fire("PLAYER_ENTERING_WORLD")
    equal(state.addon.ResolveSchool("OtherPlayer"), "neutral")
end)

test("explicit magic miss school is usable; unsupported damage masks invalidate cached school", function()
    local state = setup()
    state:combat("SPELL_MISSED", 5019, "OtherPlayer", nil, "RESIST", nil, nil, nil, 2)
    lastSchool(state, "holy", "resist")
    equal(state.addon.ResolveSchool("OtherPlayer", 1, 1), "neutral")
    equal(state.addon.ResolveSchool("OtherPlayer", nil, 1), "neutral")
    equal(state.addon.ResolveSchool("OtherPlayer", 127, 64), "neutral")
end)

test("each school has independent random selection without adjacent repeats", function()
    local state = setup()
    math.randomseed(3129)
    for _, school in ipairs(state.addon.schoolOrder) do
        for _, category in ipairs({ "hit", "crit", "resist", "miss", "absorb" }) do
            local previous, seen = nil, {}
            for _ = 1, 100 do
                state.addon.PlayCategory(category, true, nil, school)
                local path = state.played[#state.played].path
                assert(path ~= previous, school .. " " .. category .. " repeated")
                seen[path], previous = true, path
            end
            local count = 0
            for _ in pairs(seen) do count = count + 1 end
            equal(count, #state.addon.schoolSounds[school][category])
        end
    end
end)

test("slash previews and UI school choice preview the selected school without changing combat", function()
    local state = setup()
    SlashCmdList.GABBASOUNDS("test crit fire")
    lastSchool(state, "fire", "crit")
    SlashCmdList.GABBASOUNDS("test resist schatten")
    lastSchool(state, "shadow", "resist")
    local count = #state.played
    SlashCmdList.GABBASOUNDS("test hit nonsense")
    SlashCmdList.GABBASOUNDS("test")
    equal(#state.played, count)
    state.addon.OpenUI("magic")
    local view = state.addon.ui.previews.magic
    for index, school in ipairs(state.addon.schoolOrder) do
        local row = view.rows[index]
        row.scripts.OnClick(row)
        view.buttons.hit.scripts.OnClick()
        lastSchool(state, school, "hit")
    end
    state:combat("RANGE_DAMAGE", 5019, nil, false, nil, 50, 0, 32)
    lastSchool(state, "shadow", "hit")
end)

test("saved soundpack migration defaults to magic and preserves valid custom choice", function()
    equal(setup().addon.db.soundPack, "magic")
    equal(setup({ soundPack = "spoken", enabled = false }).addon.db.soundPack, "spoken")
    for _, invalid in ipairs({ "gone-pack", true, 42, {} }) do
        local state = setup({ soundPack = invalid })
        equal(state.addon.db.soundPack, "magic")
        equal(state.addon.SetOption("soundPack", invalid), false)
        equal(state.addon.db.soundPack, "magic")
    end
end)

test("categorized recordings have distinct hit and crit pools and common failure pools", function()
    local state = setup()
    equal(#state.addon.packOrder, 13)
    equal(state.addon.packOrder[2], "spoken")
    for _, category in ipairs({ "hit", "crit", "resist", "miss", "absorb" }) do
        local pool = state.addon.soundPacks.spoken.categories[category]
        equal(#pool, ({ hit = 16, crit = 3, resist = 8, miss = 8, absorb = 8 })[category])
        local groups = {}
        for _, filename in ipairs(pool) do
            local input = assert(io.open("Sounds/" .. filename, "rb"))
            equal(input:read(4), "OggS")
            input:close()
            assert(state.addon.soundDurations[filename] > 0)
            local group = state.addon.soundPacks.spoken.repeatGroups[filename]
            assert(type(group) == "string")
            groups[group] = (groups[group] or 0) + 1
        end
        assert(next(groups))
    end
end)

test("selected spoken pack covers every school, shooter and result including unknown resistance", function()
    local state = setup()
    SlashCmdList.GABBASOUNDS("pack spoken")
    for mask in pairs(state.addon.schoolMasks) do
        state:combat("RANGE_DAMAGE", 5019, "Player-Other", false, nil, 50, 0, mask)
        state:combat("RANGE_DAMAGE", 5019, "Player-Other", true, nil, 80, 0, mask)
        for _, reason in ipairs({ "RESIST", "MISS", "ABSORB" }) do
            state:combat("RANGE_MISSED", 5019, "Player-Other", nil, reason)
        end
    end
    state:combat("RANGE_MISSED", 5019, "UnseenPlayer", nil, "RESIST")
    equal(#state.played, 31)
    for _, playback in ipairs(state.played) do assert(playback.path:find("\\voice_", 1, true)) end
    equal(state.addon.originalsMuted, true)
    local count = #state.played
    state:combat("SPELL_DAMAGE", 14914, nil, true)
    equal(#state.played, count)
end)

test("custom random pools avoid repeating an entire family even when damage school changes", function()
    local state = setup({ soundPack = "spoken" })
    math.randomseed(37317)
    for _, category in ipairs({ "hit", "crit", "resist", "miss", "absorb" }) do
        local previous, previousGroup, seen = nil, nil, {}
        for index = 1, 120 do
            local school = state.addon.schoolOrder[index % 6 + 1]
            state.addon.PlayCategory(category, true, nil, school)
            local path = state.played[#state.played].path
            assert(path ~= previous, "Repeated custom sound after school change")
            local filename = path:match("([^\\]+)$")
            local group = state.addon.soundPacks.spoken.repeatGroups[filename]
            assert(group ~= previousGroup, "Other take of the same sound family repeated")
            previousGroup = group
            seen[path], previous = true, path
        end
        local count = 0
        for _ in pairs(seen) do count = count + 1 end
        equal(count, #state.addon.soundPacks.spoken.categories[category])
    end
end)

test("switching soundpack stops owned tails and resumes the correct family with cached school", function()
    local state = setup()
    state:combat("RANGE_DAMAGE", 5019, nil, false, nil, 50, 0, 4)
    SlashCmdList.GABBASOUNDS("pack custom")
    equal(state.addon.db.soundPack, "spoken")
    equal(#state.stopped, 1)
    state:combat("RANGE_MISSED", 5019, nil, nil, "RESIST")
    assert(state.played[2].path:find("\\voice_", 1, true))
    SlashCmdList.GABBASOUNDS("pack magic")
    equal(#state.stopped, 2)
    state:combat("RANGE_MISSED", 5019, nil, nil, "RESIST")
    lastSchool(state, "fire", "resist")
    equal(state.addon.originalsMuted, true)
end)

test("custom selection works in panel, updates variant labels and preserves preview semantics", function()
    local state = setup()
    state.addon.OpenUI()
    local ui = state.addon.ui
    ui.packButton.scripts.OnClick()
    equal(state.addon.db.soundPack, "magic", "Opening a picker must not change the package")
    assert(ui.picker:IsShown())
    ui.packChoices.spoken.scripts.OnClick()
    equal(state.addon.db.soundPack, "spoken")
    equal(ui.picker:IsShown(), false)
    assert(ui.packButton.text:find("Eigene Aufnahme", 1, true))
    state.addon.OpenUI("weapons")
    local view = ui.previews.weapons
    equal(view.counts.hit.text, "16 Clips")
    view.rows[2].scripts.OnClick(view.rows[2])
    view.buttons.hit.scripts.OnClick()
    assert(state.played[1].path:find("\\voice_", 1, true))
    equal(state.addon.stats.hit, 0)
    state.addon.OpenUI("general")
    ui.packButton.scripts.OnClick()
    ui.packChoices.spoken_wand.scripts.OnClick()
    equal(state.addon.db.soundPack, "spoken_wand")
end)

test("custom playback failure restores originals and changing back recovers", function()
    local state = setup({ soundPack = "spoken" })
    state.failPlayback = true
    state:combat("RANGE_DAMAGE")
    equal(state.addon.originalsMuted, false)
    equal(state.muted[568935], nil)
    state.failPlayback = false
    SlashCmdList.GABBASOUNDS("pack magic")
    state:combat("RANGE_DAMAGE")
    lastSchool(state, "shadow", "hit")
    equal(state.addon.originalsMuted, true)
    equal(state.addon.stats.hit, 1)
end)

test("a custom pack with only one family alternates its takes without failing", function()
    local state = setup({ soundPack = "spoken" })
    local pack = state.addon.soundPacks.spoken
    local first, second = pack.categories.hit[1], pack.categories.hit[2]
    pack.categories.hit = { first, second }
    pack.repeatGroups[first], pack.repeatGroups[second] = 1, 1
    local previous
    for _ = 1, 12 do
        assert(state.addon.PlayCategory("hit", true))
        local path = state.played[#state.played].path
        assert(path ~= previous)
        previous = path
    end
end)

local function voicePath(state, weapon, category)
    local path = state.played[#state.played].path
    assert(path:find("voice_" .. weapon .. "_" .. category .. "_", 1, true), "Unexpected clip " .. path)
end
local function equip(state, subtype, unit)
    unit = unit or "player"
    local link = "item:weapon-type-" .. subtype
    state.links[unit], state.itemSubclasses[link] = link, subtype
end

test("magic mode leaves hunter shots alone", function()
    local state = setup()
    equip(state, 2)
    for _, spell in ipairs({ 75, 2480, 7918, 7919 }) do state:combat("RANGE_DAMAGE", spell) end
    equal(#state.played, 0)
end)

test("automatic spoken mode chooses bow, crossbow or gun from inventory metadata", function()
    local state = setup({ soundPack = "spoken" })
    for _, pair in ipairs({ { 2, "bow" }, { 18, "bow" }, { 3, "gun" } }) do
        equip(state, pair[1])
        state:combat("RANGE_DAMAGE", 75, nil, false, nil, 50, 0, 1)
        voicePath(state, pair[2], "hit")
        state:combat("SPELL_DAMAGE", 75, nil, true, nil, 80, 0, 1)
        voicePath(state, pair[2], "crit")
        state:combat("RANGE_MISSED", 75, nil, nil, "MISS")
        voicePath(state, "shared", "miss")
    end
end)

test("explicit bow, crossbow and gun Shoot events identify unseen actors and cache subsequent Auto Shots", function()
    local state = setup({ soundPack = "spoken" })
    for _, pair in ipairs({ { 2480, "bow" }, { 7919, "bow" }, { 7918, "gun" } }) do
        local guid = "Shooter-" .. pair[1]
        state:combat("RANGE_DAMAGE", pair[1], guid, false, nil, 50, 0, 1)
        voicePath(state, pair[2], "hit")
        state:combat("RANGE_DAMAGE", 75, guid, true, nil, 80, 0, 1)
        voicePath(state, pair[2], "crit")
    end
end)

test("unknown foreign Auto Shot uses a spoken reserve while native weapons are muted", function()
    local state = setup({ soundPack = "spoken" })
    state:combat("RANGE_DAMAGE", 75, "UnknownHunter", false, nil, 50, 0, 1)
    voicePath(state, "wand", "hit")
    equal(state.muted[567674], true, "Native bow release is muted")
    state:combat("RANGE_MISSED", 75, "UnknownHunter", nil, "MISS")
    voicePath(state, "shared", "miss")
    equal(state.addon.ResolveWeapon("UnknownHunter", 75), "ranged")
end)

test("individual bow and gun packages filter other weapons and never globally mute wands", function()
    for _, pair in ipairs({ { "spoken_bow", 2480, 7918, "bow" }, { "spoken_gun", 7918, 2480, "gun" } }) do
        local state = setup({ soundPack = pair[1] })
        equal(state.addon.originalsMuted, false)
        equal(state.muted[568935], nil)
        state:combat("RANGE_DAMAGE", pair[3])
        state:combat("RANGE_DAMAGE", 5019)
        equal(#state.played, 0)
        state:combat("RANGE_DAMAGE", pair[2])
        voicePath(state, pair[4], "hit")
        state:combat("RANGE_DAMAGE", 75, "UninspectedActor")
        voicePath(state, pair[4], "hit")
    end
end)

test("weapon changes, unit inventory events and world transitions discard stale weapon classification", function()
    local state = setup({ soundPack = "spoken" })
    state.units.target = "OtherHunter"
    equip(state, 2, "target")
    state:combat("RANGE_DAMAGE", 75, "OtherHunter")
    voicePath(state, "bow", "hit")
    equip(state, 3, "target")
    state:combat("RANGE_MISSED", 75, "OtherHunter", nil, "MISS")
    equal(state.addon.ResolveWeapon("OtherHunter", 75), "gun")
    state.links.target = nil
    state:fire("UNIT_INVENTORY_CHANGED", "target")
    equal(state.addon.ResolveWeapon("OtherHunter", 75), "ranged")
    state:combat("RANGE_DAMAGE", 7918, "OtherHunter")
    state:fire("PLAYER_ENTERING_WORLD")
    equal(state.addon.ResolveWeapon("OtherHunter", 75), "ranged")
    state:combat("RANGE_DAMAGE", 7919, "OtherHunter")
    state.time = 121
    equal(state.addon.ResolveWeapon("OtherHunter", 75), "ranged")
end)

test("Classic global GetItemInfoInstant fallback and missing equipment data are handled", function()
    local state = setup({ soundPack = "spoken" })
    equip(state, 3)
    GetItemInfoInstant = C_Item.GetItemInfoInstant
    C_Item = nil
    state:combat("RANGE_DAMAGE", 75)
    voicePath(state, "gun", "hit")
    GetItemInfoInstant = nil
    state:fire("PLAYER_EQUIPMENT_CHANGED", 18)
    state:combat("RANGE_DAMAGE", 75)
    equal(#state.played, 2, "Use spoken reserve when item API cannot identify the weapon")
    voicePath(state, "wand", "hit")
end)

test("shared graze words are used for partial resistance and block, with crit taking priority", function()
    local state = setup({ soundPack = "spoken" })
    state:combat("RANGE_DAMAGE", 5019, nil, false, nil, 30, 20, 32)
    voicePath(state, "shared", "graze")
    equip(state, 2)
    state:combat("RANGE_DAMAGE", 75, nil, false, nil, 30, 0, 1, 1, 20)
    voicePath(state, "shared", "graze")
    state:combat("RANGE_DAMAGE", 75, nil, true, nil, 60, 20, 1, 1, 10)
    voicePath(state, "bow", "crit")
    equal(state.addon.stats.graze, 2)
    equal(state.addon.stats.crit, 1)
    SlashCmdList.GABBASOUNDS("graze off")
    state:combat("RANGE_DAMAGE", 75, nil, false, nil, 30, 0, 1, 1, 20)
    voicePath(state, "bow", "hit")
    state.addon.SetOption("graze", true)
    state:combat("RANGE_DAMAGE", 75, nil, false, nil, 0, 20, 1)
    voicePath(state, "bow", "hit")
    state:combat("RANGE_DAMAGE", 75, nil, false, nil, 50, -20, 1)
    voicePath(state, "bow", "hit")
end)

test("unknown hunter partial hit uses shared graze words rather than inventing a weapon type", function()
    local state = setup({ soundPack = "spoken" })
    state:combat("RANGE_DAMAGE", 75, "UnknownHunter", false, nil, 30, 20, 1)
    voicePath(state, "shared", "graze")
end)

test("shared miss and graze pools are exactly the same files for every weapon", function()
    local state = setup({ soundPack = "spoken" })
    for _, weapon in ipairs({ "wand", "bow", "gun" }) do
        local bank = state.addon.voiceBanks[weapon]
        equal(#bank.miss, 8)
        equal(#bank.graze, 8)
        for i = 1, 8 do
            equal(bank.miss[i], state.addon.voiceBanks.wand.miss[i])
            equal(bank.graze[i], state.addon.voiceBanks.wand.graze[i])
        end
    end
end)

test("switching weapon types does not immediately repeat a shared failure phrase", function()
    local state = setup({ soundPack = "spoken" })
    local previous
    for index = 1, 60 do
        local spell = ({ 5019, 2480, 7918 })[index % 3 + 1]
        state:combat("RANGE_MISSED", spell, nil, nil, "MISS")
        local path = state.played[#state.played].path
        assert(path ~= previous)
        previous = path
    end
end)

test("automatic UI previews select all three weapons and leave combat weapon routing automatic", function()
    local state = setup({ soundPack = "spoken" })
    equip(state, 3)
    state.addon.OpenUI("weapons")
    local view = state.addon.ui.previews.weapons
    for index, weapon in ipairs({ "wand", "bow", "gun" }) do
        local row = view.rows[index]
        row.scripts.OnClick(row)
        view.buttons.hit.scripts.OnClick()
        voicePath(state, weapon, "hit")
    end
    equal(state.addon.db.soundPack, "spoken")
    state.addon.OpenUI("mage")
    local mage = state.addon.ui.previews.mage
    mage.buttons.cast.scripts.OnClick()
    voicePath(state, "frostbolt", "cast")
    state:combat("RANGE_DAMAGE", 75)
    voicePath(state, "gun", "hit")
    equal(state.addon.stats.hit, 1)
end)

test("new pack aliases, shared graze previews and persistent graze option work", function()
    local state = setup({ soundPack = "spoken_gun", graze = false })
    equal(state.addon.db.graze, false)
    SlashCmdList.GABBASOUNDS("test graze")
    voicePath(state, "shared", "graze")
    SlashCmdList.GABBASOUNDS("pack bow")
    equal(state.addon.db.soundPack, "spoken_bow")
    SlashCmdList.GABBASOUNDS("pack gewehr")
    equal(state.addon.db.soundPack, "spoken_gun")
    SlashCmdList.GABBASOUNDS("pack wand")
    equal(state.addon.db.soundPack, "spoken_wand")
    equal(state.addon.db.graze, false)
end)

test("rename migrates supported legacy settings without changing the old table", function()
    local legacy = { soundPack = "spoken", channel = "Master", graze = false, allSources = false, hit = "invalid", extra = "ignored" }
    local state = setup(nil, legacy)
    equal(state.addon.db, GabbaSoundsDB)
    assert(state.addon.db ~= legacy)
    equal(state.addon.db.soundPack, "spoken")
    equal(state.addon.db.channel, "Master")
    equal(state.addon.db.graze, false)
    equal(state.addon.db.allSources, false)
    equal(state.addon.db.hit, true)
    equal(state.addon.db.extra, nil)
    equal(legacy.hit, "invalid")
    equal(SLASH_GABBASOUNDS1, "/gabbasounds")
    equal(SLASH_GABBASOUNDS2, "/gws")
    equal(SLASH_GABBASOUNDS3, "/zauberstab")
end)

test("existing GabbaSounds settings take precedence over legacy settings", function()
    local saved = { soundPack = "spoken_gun", graze = false }
    local state = setup(saved, { soundPack = "magic", graze = true })
    equal(state.addon.db, saved)
    equal(state.addon.db.soundPack, "spoken_gun")
    equal(state.addon.db.graze, false)
    local fresh = setup(nil, "broken legacy data")
    equal(fresh.addon.db.soundPack, "magic")
end)

test("all Classic Frostbolt ranks use their own hit and crit recordings in automatic spoken mode", function()
    local state = setup({ soundPack = "spoken" })
    for _, spellID in ipairs({ 116, 205, 837, 7322, 8406, 8407, 8408, 10179, 10180, 10181, 25304 }) do
        state:combat("SPELL_DAMAGE", spellID, nil, false, nil, 50, 0, 16, 16)
        voicePath(state, "frostbolt", "hit")
        state:combat("SPELL_DAMAGE", spellID, nil, true, nil, 80, 0, 16, 16)
        voicePath(state, "frostbolt", "crit")
    end
    equal(state.addon.stats.hit, 11)
    equal(state.addon.stats.crit, 11)
    equal(#state.played, 22)
    equal(#state.addon.voiceBanks.frostbolt.hit, 7)
    equal(#state.addon.voiceBanks.frostbolt.crit, 7)
end)

test("Frostbolt reuses shared miss and graze recordings with critical priority", function()
    local state = setup({ soundPack = "spoken_frostbolt" })
    for _, reason in ipairs({ "MISS", "RESIST", "ABSORB", "IMMUNE", "EVADE" }) do
        state:combat("SPELL_MISSED", 116, nil, nil, reason)
        voicePath(state, "shared", "miss")
    end
    state:combat("SPELL_DAMAGE", 25304, nil, false, nil, 50, 5, 16, 16)
    voicePath(state, "shared", "graze")
    state:combat("SPELL_DAMAGE", 25304, nil, true, nil, 50, 5, 16, 16)
    voicePath(state, "frostbolt", "crit")
    state.addon.SetOption("graze", false)
    state:combat("SPELL_DAMAGE", 116, nil, false, nil, 50, 5, 16, 16)
    voicePath(state, "frostbolt", "hit")
    equal(state.addon.originalsMuted, false)
end)

test("Frostbolt respects pack selection, shooter scope and enabled categories", function()
    for _, pack in ipairs({ "magic", "spoken_wand", "spoken_bow", "spoken_gun" }) do
        local state = setup({ soundPack = pack })
        state:combat("SPELL_DAMAGE", 116)
        state:combat("SPELL_MISSED", 116, nil, nil, "MISS")
        equal(#state.played, 0)
    end
    local state = setup({ soundPack = "spoken_frostbolt", allSources = false, crit = false })
    state:combat("SPELL_DAMAGE", 116, "Player-Other")
    state:combat("SPELL_DAMAGE", 116, nil, true)
    equal(#state.played, 0)
    state:combat("SPELL_DAMAGE", 116)
    voicePath(state, "frostbolt", "hit")
    state.addon.SetOption("enabled", false)
    state:combat("SPELL_MISSED", 116, nil, nil, "MISS")
    equal(#state.played, 1)
end)

test("replay real player Frostbolt damage and misses from the Classic client log", function()
    local fixture = assert(loadfile("tests/fixtures/classic_frostbolt.lua"))()
    local state = setup({ soundPack = "spoken" })
    for _, row in ipairs(fixture.events) do
        state:combat(row.event, row.spellID, nil, row.critical, row.missType,
            row.amount, row.resisted, row.school, 16, row.blocked, row.absorbed)
    end
    equal(#state.played, #fixture.events)
    for category, expected in pairs(fixture.expected) do
        equal(state.addon.stats[category], expected, category)
    end
end)

test("Frostbolt-only mode ignores wand, hunter, NPC, pet and non-impact spell events", function()
    local state = setup({ soundPack = "spoken_frostbolt" })
    for _, spellID in ipairs({ 5019, 75, 2480, 7918, 7919, 133, 143, 145, 3140, 59638 }) do
        state:combat("SPELL_DAMAGE", spellID, "Player-Other")
    end
    for _, event in ipairs({ "SPELL_CAST_START", "SPELL_CAST_SUCCESS", "SPELL_AURA_APPLIED", "SPELL_PERIODIC_DAMAGE", "RANGE_DAMAGE" }) do
        state:combat(event, 116)
    end
    state:combat("SPELL_DAMAGE", 116, "Creature-Other")
    state:combat("SPELL_DAMAGE", 116, "Pet-Other")
    equal(#state.played, 0)
    state:combat("SPELL_DAMAGE", 116, "Player-Other")
    voicePath(state, "frostbolt", "hit")
end)

test("Frostbolt aliases and previews do not replace wand classification", function()
    local state = setup({ soundPack = "spoken" })
    state:combat("RANGE_DAMAGE", 5019)
    state:combat("SPELL_DAMAGE", 116)
    state:combat("RANGE_DAMAGE", 5019)
    voicePath(state, "wand", "hit")
    SlashCmdList.GABBASOUNDS("pack frostblitz")
    equal(state.addon.db.soundPack, "spoken_frostbolt")
    SlashCmdList.GABBASOUNDS("test hit")
    voicePath(state, "frostbolt", "hit")
    SlashCmdList.GABBASOUNDS("test crit")
    voicePath(state, "frostbolt", "crit")
    SlashCmdList.GABBASOUNDS("test graze")
    voicePath(state, "shared", "graze")
    SlashCmdList.GABBASOUNDS("pack mage")
    equal(state.addon.db.soundPack, "spoken_mage")
end)

test("pending Frostbolt recordings keep originals audible and still allow shared failure words", function()
    local state = setup({ soundPack = "spoken_frostbolt" })
    state.addon.voiceBanks.frostbolt.hit = {}
    state.addon.voiceBanks.frostbolt.crit = {}
    state.addon.UpdateOriginalMuting()
    state:combat("SPELL_DAMAGE", 116)
    state:combat("SPELL_DAMAGE", 116, nil, true)
    equal(#state.played, 0)
    equal(state.addon.originalsMuted, false)
    equal(state.addon.frostboltOriginalsMuted, false)
    SlashCmdList.GABBASOUNDS("test hit")
    assert(state.messages[#state.messages]:find("noch keine", 1, true))
    state:combat("SPELL_MISSED", 116, nil, nil, "MISS")
    voicePath(state, "shared", "miss")
end)

test("minimap left click toggles, stops sounds and restores originals; right click opens options", function()
    local state = setup()
    local button = GabbaSoundsMinimapButton
    assert(button and button:IsShown())
    equal(button.textures[1].desaturated, false)
    equal(button.textures[1].texture, "Interface\\AddOns\\GabbaSounds\\Assets\\minimap.tga")
    state:combat("RANGE_DAMAGE", 5019)
    button.scripts.OnClick(button, "LeftButton")
    equal(state.addon.db.enabled, false)
    equal(state.addon.originalsMuted, false)
    equal(#state.stopped, 1)
    equal(button.textures[1].desaturated, true)
    button.scripts.OnClick(button, "RightButton")
    assert(GabbaSoundsPanel:IsShown())
    button.scripts.OnClick(button, "RightButton")
    assert(GabbaSoundsPanel:IsShown())
    equal(state.addon.db.enabled, false)
    button.scripts.OnClick(button, "LeftButton")
    equal(state.addon.db.enabled, true)
    equal(state.addon.originalsMuted, true)
end)

test("minimap restores saved angle and visibility and validates numeric settings", function()
    local state = setup({ minimapAngle = 450, minimapHidden = true })
    local button = GabbaSoundsMinimapButton
    equal(state.addon.db.minimapAngle, 90)
    equal(button:IsShown(), false)
    assert(math.abs(button.point[4]) < 0.001)
    SlashCmdList.GABBASOUNDS("minimap on")
    equal(button:IsShown(), true)
    equal(state.addon.SetOption("minimapAngle", -90), true)
    equal(state.addon.db.minimapAngle, 270)
    for _, invalid in ipairs({ "broken", false, math.huge, -math.huge, 0/0 }) do
        equal(state.addon.SetOption("minimapAngle", invalid), false)
        equal(state.addon.db.minimapAngle, 270)
    end
    local invalid = setup({ minimapAngle = "broken", minimapHidden = "broken" })
    equal(invalid.addon.db.minimapAngle, 145)
    equal(invalid.addon.db.minimapHidden, false)
end)

test("minimap dragging accounts for scale, suppresses clicks and stops updates when hidden", function()
    local state = setup()
    local button = GabbaSoundsMinimapButton
    state.cursorX, state.cursorY = 200, 400
    button.scripts.OnDragStart(button)
    button.scripts.OnUpdate(button)
    assert(math.abs(state.addon.db.minimapAngle - 90) < 0.001)
    button.scripts.OnDragStop(button)
    equal(button.scripts.OnUpdate, nil)
    button.scripts.OnClick(button, "LeftButton")
    equal(state.addon.db.enabled, true)
    button.scripts.OnMouseDown(button)
    button.scripts.OnClick(button, "LeftButton")
    equal(state.addon.db.enabled, false)
    button.scripts.OnDragStart(button)
    SlashCmdList.GABBASOUNDS("minimap off")
    equal(button.scripts.OnUpdate, nil)
    equal(button:IsShown(), false)
end)

test("minimap tooltip refreshes enabled state and square positioning follows resize", function()
    local state = setup({ minimapAngle = 45 })
    local button = GabbaSoundsMinimapButton
    button.scripts.OnEnter(button)
    equal(GameTooltip.text, "GabbaSounds")
    assert(GameTooltip:IsOwned(button))
    state.addon.SetOption("enabled", false)
    equal(GameTooltip.lines[#GameTooltip.lines - 3], "Ausgeschaltet")
    GetMinimapShape = function() return "SQUARE" end
    Minimap:SetSize(200, 160)
    Minimap.scripts.OnSizeChanged(Minimap)
    assert(math.abs(button.point[4] - 110) < 0.001)
    assert(math.abs(button.point[5] - 90) < 0.001)
    button.scripts.OnLeave(button)
    equal(GameTooltip:IsShown(), false)
end)

local frostOriginals = { 568119, 568128, 568493, 568542, 568843, 569145, 569304, 569765, 569781 }

test("Frostbolt mutes every original phase, warms files silently once and balances ownership", function()
    local state = setup({ soundPack = "spoken_frostbolt" })
    equal(state.addon.frostboltOriginalsMuted, true)
    equal(state.addon.originalsMuted, false)
    local count = 0
    for _ in pairs(state.muted) do count = count + 1 end
    equal(count, 9)
    equal(#state.warmed, 9)
    equal(#state.warmStops, 9)
    equal(#state.played, 0)
    equal(state.addon.stats.hit, 0)
    for _, id in ipairs(frostOriginals) do
        equal(state.muted[id], true)
        equal(state.muteDepth[id], 1)
        equal(state.muteCalls[id], 2, "Temporary plus persistent mute")
    end
    for _ = 1, 10 do state.addon.UpdateOriginalMuting() end
    for _, id in ipairs(frostOriginals) do equal(state.muteCalls[id], 2) end
    SlashCmdList.GABBASOUNDS("mute off")
    for _, id in ipairs(frostOriginals) do equal(state.muteDepth[id], 0) end
    equal(state.addon.frostboltOriginalsMuted, false)
    SlashCmdList.GABBASOUNDS("mute on")
    equal(state.addon.frostboltOriginalsMuted, true)
    equal(#state.warmed, 9, "No repeated warm-up")
end)

test("package changes independently release wand and Frostbolt original mutes", function()
    local state = setup({ soundPack = "spoken" })
    equal(state.addon.originalsMuted, true)
    equal(state.addon.frostboltOriginalsMuted, true)
    state.addon.SetOption("soundPack", "spoken_frostbolt")
    equal(state.muted[568935], nil)
    for _, id in ipairs(frostOriginals) do equal(state.muteDepth[id], 1) end
    state.addon.SetOption("soundPack", "magic")
    equal(state.muted[568935], true)
    for _, id in ipairs(frostOriginals) do equal(state.muteDepth[id], 0) end
    for _, pack in ipairs({ "spoken_bow", "spoken_gun", "spoken_wand" }) do
        state.addon.SetOption("soundPack", pack)
        equal(state.addon.frostboltOriginalsMuted, false)
        for _, id in ipairs(frostOriginals) do equal(state.muted[id], nil) end
    end
    state.addon.SetOption("soundPack", "spoken")
    for _, id in ipairs(frostOriginals) do equal(state.muteDepth[id], 1) end
    equal(#state.warmed, 358)
end)

test("incomplete Frostbolt coverage restores originals and graze-off falls back to hit", function()
    for _, category in ipairs({ "hit", "crit", "resist", "miss", "absorb" }) do
        local state = setup({ soundPack = "spoken_frostbolt" })
        state.addon.SetOption(category, false)
        equal(state.addon.frostboltOriginalsMuted, false)
        for _, id in ipairs(frostOriginals) do equal(state.muted[id], nil) end
        state.addon.SetOption(category, true)
        equal(state.addon.frostboltOriginalsMuted, true)
        local saved = state.addon.voiceBanks.frostbolt[category]
        state.addon.voiceBanks.frostbolt[category] = {}
        state.addon.UpdateOriginalMuting()
        equal(state.addon.frostboltOriginalsMuted, false)
        state.addon.voiceBanks.frostbolt[category] = saved
        state.addon.UpdateOriginalMuting()
        equal(state.addon.frostboltOriginalsMuted, true)
    end
    local state = setup({ soundPack = "spoken_frostbolt" })
    state.addon.SetOption("graze", false)
    equal(state.addon.frostboltOriginalsMuted, true)
    state.addon.SetOption("allSources", false)
    equal(state.addon.frostboltOriginalsMuted, false)
    state.addon.SetOption("allSources", true)
    equal(state.addon.frostboltOriginalsMuted, true)
end)

test("Frostbolt playback failure restores originals and leaves another addon's mute intact", function()
    local state = setup({ soundPack = "spoken" })
    MuteSoundFile(568119) -- Independent owner on the shared precast file.
    equal(state.muteDepth[568119], 2)
    state.failPlayback = true
    state:combat("SPELL_DAMAGE", 116)
    equal(state.addon.originalsMuted, false)
    equal(state.addon.frostboltOriginalsMuted, false)
    equal(state.muteDepth[568119], 1)
    for _, id in ipairs(frostOriginals) do
        if id ~= 568119 then equal(state.muted[id], nil) end
    end
    state.failPlayback = false
    state.addon.PlayCategory("hit", true, nil, "frost", "frostbolt")
    voicePath(state, "frostbolt", "hit")
    equal(state.addon.frostboltOriginalsMuted, true)
    equal(state.muteDepth[568119], 2)
    state.addon.SetOption("enabled", false)
    equal(state.muteDepth[568119], 1)
    equal(#state.warmed, 358)
end)

test("minimap disable and logout restore Frostbolt as well as wand originals", function()
    local state = setup({ soundPack = "spoken" })
    state:combat("SPELL_DAMAGE", 116)
    GabbaSoundsMinimapButton.scripts.OnClick(GabbaSoundsMinimapButton, "LeftButton")
    equal(state.addon.originalsMuted, false)
    equal(state.addon.frostboltOriginalsMuted, false)
    equal(#state.stopped, 1)
    equal(next(state.muted), nil)
    GabbaSoundsMinimapButton.scripts.OnClick(GabbaSoundsMinimapButton, "LeftButton")
    equal(state.addon.frostboltOriginalsMuted, true)
    state:fire("PLAYER_LOGOUT")
    equal(next(state.muted), nil)
    equal(state.addon.frostboltOriginalsMuted, false)
    for _, id in ipairs(frostOriginals) do equal(state.muteDepth[id], 0) end
end)

test("options and status report independent Frostbolt original muting", function()
    local state = setup({ soundPack = "spoken_frostbolt" })
    SlashCmdList.GABBASOUNDS("status")
    assert(state.messages[#state.messages]:find("Frostblitz-Originale: stumm", 1, true))
    state.addon.OpenUI()
    local checkbox
    for _, frame in ipairs(state.frames) do
        if frame.label and frame.label.text:find("Originalgeräusche stummschalten", 1, true) then checkbox = frame end
    end
    assert(checkbox)
    checkbox.checked = false
    checkbox.scripts.OnClick(checkbox)
    equal(state.addon.frostboltOriginalsMuted, false)
    SlashCmdList.GABBASOUNDS("status")
    assert(state.messages[#state.messages]:find("Frostblitz-Originale: hörbar", 1, true))
end)

local bowOriginals = { 567672, 567681, 567671, 567680, 567670, 567677, 567675,
    567676, 567678, 567683, 567679, 567674, 567673, 567682 }
local gunOriginals = { 567721, 567718, 567722, 567719, 567720, 567723, 567617 }

test("spoken-only mode enables complete replacement and off restores originals while keeping voices", function()
    local state = setup({ allSources = false, hit = false, graze = false })
    equal(state.addon.IsSpokenOnly(), false)
    equal(state.addon.SetOption("spokenOnly", "on"), false)
    SlashCmdList.GABBASOUNDS("spokenonly on")
    equal(state.addon.db.soundPack, "spoken")
    equal(state.addon.db.allSources, true)
    equal(state.addon.db.hit, true)
    equal(state.addon.db.graze, true)
    equal(state.addon.IsSpokenOnly(), true)
    equal(state.addon.originalsMuted, true)
    equal(state.addon.frostboltOriginalsMuted, true)
    equal(state.addon.bowOriginalsMuted, true)
    equal(state.addon.gunOriginalsMuted, true)
    local count = 0
    for _ in pairs(state.muted) do count = count + 1 end
    equal(count, 366)
    SlashCmdList.GABBASOUNDS("spokenonly off")
    equal(next(state.muted), nil)
    equal(state.addon.IsSpokenOnly(), false)
    equal(state.addon.db.soundPack, "spoken")
    state:combat("RANGE_DAMAGE", 2480)
    voicePath(state, "bow", "hit")
    state:combat("RANGE_DAMAGE", 7918, nil, true)
    voicePath(state, "gun", "crit")
    state:combat("SPELL_DAMAGE", 116)
    voicePath(state, "frostbolt", "hit")
end)

test("hunter originals warm once, release owned mutes only and recover after playback failure", function()
    local state = setup({ soundPack = "spoken" })
    equal(#state.warmed, 358)
    equal(#state.warmStops, 358)
    for _, group in ipairs({ bowOriginals, gunOriginals }) do
        for _, id in ipairs(group) do
            equal(state.muteDepth[id], 1)
            equal(state.muteCalls[id], 2)
        end
    end
    for _ = 1, 10 do state.addon.UpdateOriginalMuting() end
    MuteSoundFile(567721) -- Another addon's mute on the same gun asset.
    state.failPlayback = true
    state:combat("RANGE_DAMAGE", 7918)
    equal(state.addon.bowOriginalsMuted, false)
    equal(state.addon.gunOriginalsMuted, false)
    equal(state.muteDepth[567721], 1)
    for _, id in ipairs(bowOriginals) do equal(state.muteDepth[id], 0) end
    state.failPlayback = false
    state.addon.PlayCategory("hit", true, nil, "neutral", "gun")
    equal(state.addon.gunOriginalsMuted, true)
    equal(state.muteDepth[567721], 2)
    equal(#state.warmed, 358)
    state:fire("PLAYER_LOGOUT")
    equal(state.addon.bowOriginalsMuted, false)
    equal(state.addon.gunOriginalsMuted, false)
    equal(state.muteDepth[567721], 1)
    for _, id in ipairs(gunOriginals) do
        if id ~= 567721 then equal(state.muteDepth[id], 0) end
    end
end)

test("hunter single packs mute only their covered weapon and incomplete coverage restores it", function()
    for _, item in ipairs({ { "spoken_bow", "bow", bowOriginals, gunOriginals },
        { "spoken_gun", "gun", gunOriginals, bowOriginals } }) do
        local state = setup({ soundPack = item[1] })
        for _, id in ipairs(item[3]) do equal(state.muted[id], true) end
        for _, id in ipairs(item[4]) do equal(state.muted[id], nil) end
        equal(state.addon.IsSpokenOnly(), false)
        for _, key in ipairs({ "allSources", "hit", "crit", "resist", "miss", "absorb" }) do
            state.addon.SetOption(key, false)
            for _, id in ipairs(item[3]) do equal(state.muted[id], nil) end
            state.addon.SetOption(key, true)
        end
        local bank = state.addon.voiceBanks[item[2]]
        for _, key in ipairs({ "hit", "crit", "resist", "miss", "absorb", "graze" }) do
            local saved = bank[key]
            bank[key] = {}
            state.addon.UpdateOriginalMuting()
            for _, id in ipairs(item[3]) do equal(state.muted[id], nil) end
            bank[key] = saved
            state.addon.UpdateOriginalMuting()
        end
    end
end)

test("unknown hunter reserve follows mute state without inventing a weapon or hiding missing coverage", function()
    local state = setup({ soundPack = "spoken" })
    state:combat("RANGE_DAMAGE", 75, "UnseenHunter", true)
    voicePath(state, "wand", "crit")
    equal(state.addon.ResolveWeapon("UnseenHunter", 75), "ranged")
    state.addon.SetOption("muteOriginal", false)
    state:combat("RANGE_DAMAGE", 75, "UnseenHunter", false)
    equal(#state.played, 1, "Unknown native weapon remains audible with muting off")
    state.addon.SetOption("muteOriginal", true)
    state.addon.voiceBanks.wand.crit = {}
    state.addon.UpdateOriginalMuting()
    equal(state.addon.bowOriginalsMuted, false)
    equal(state.addon.gunOriginalsMuted, false)
end)

test("spoken-only UI follows setting changes and reports hunter mute states", function()
    local state = setup()
    state.addon.OpenUI()
    local check
    for _, frame in ipairs(state.frames) do
        if frame.label and frame.label.text:find("Nur gesprochene Sounds", 1, true) then check = frame end
    end
    assert(check)
    equal(check.checked, false)
    check.checked = true
    check.scripts.OnClick(check)
    equal(check.checked, true)
    check.scripts.OnEnter(check)
    assert(GameTooltip.lines[#GameTooltip.lines]:find("Originale wieder hörbar", 1, true))
    check.scripts.OnLeave(check)
    equal(GameTooltip:IsShown(), false)
    SlashCmdList.GABBASOUNDS("status")
    assert(state.messages[#state.messages]:find("Bogen/Armbrust-Originale: stumm", 1, true))
    assert(state.messages[#state.messages]:find("Gewehr-Originale: stumm", 1, true))
    state.addon.SetOption("soundPack", "magic")
    equal(check.checked, false)
    state.addon.SetOption("spokenOnly", true)
    state.addon.SetOption("allSources", false)
    equal(check.checked, false)
    check.checked = true
    check.scripts.OnClick(check)
    check.checked = false
    check.scripts.OnClick(check)
    equal(next(state.muted), nil)
    equal(state.addon.db.soundPack, "spoken")
    local reloaded = setup(state.addon.db)
    equal(reloaded.addon.IsSpokenOnly(), false)
    equal(next(reloaded.muted), nil)
end)

local function castPool(state)
    -- Use existing real files only in tests; production has no cast fallback.
    state.addon.voiceBanks.frostbolt.cast = state.addon.voiceBanks.frostbolt.hit
end

test("pending cast recordings never borrow hit audio and leave impact sounds working", function()
    local state = setup({ soundPack = "spoken" })
    state.addon.voiceBanks.frostbolt.cast = {}
    equal(#state.addon.voiceBanks.frostbolt.cast, 0)
    state:fire("UNIT_SPELLCAST_START", "player", "Cast-Pending", 116)
    state:combat("SPELL_CAST_START", 116)
    state:combat("SPELL_CAST_START", 116, "Player-OtherMage")
    equal(#state.played, 0)
    equal(state.addon.stats.cast, 0)
    state:combat("SPELL_DAMAGE", 116)
    voicePath(state, "frostbolt", "hit")
    SlashCmdList.GABBASOUNDS("test cast")
    equal(#state.played, 1)
    assert(state.messages[#state.messages]:find("Cast-Aufnahmen", 1, true))
end)

test("all Frostbolt cast ranks play once at start with separate impact statistics", function()
    local state = setup({ soundPack = "spoken_frostbolt" })
    castPool(state)
    for index, rank in ipairs({ 116, 205, 837, 7322, 8406, 8407, 8408, 10179, 10180, 10181, 25304 }) do
        local id = "Cast-" .. index
        state:fire("UNIT_SPELLCAST_START", "player", id, rank)
        voicePath(state, "frostbolt", "hit")
        state:fire("UNIT_SPELLCAST_START", "player", id, rank)
        state:combat("SPELL_CAST_START", rank) -- Duplicate combat-log start.
        state:combat("SPELL_CAST_SUCCESS", rank)
        equal(#state.played, index * 2 - 1)
        state:combat("SPELL_DAMAGE", rank, nil, true)
        voicePath(state, "frostbolt", "crit")
        equal(#state.played, index * 2)
    end
    equal(state.addon.stats.cast, 11)
    equal(state.addon.stats.hit, 0)
    equal(state.addon.stats.crit, 11)
end)

test("cast and impact audio can overlap and interruption stops only the matching player cast", function()
    local state = setup({ soundPack = "spoken" })
    castPool(state)
    state:fire("UNIT_SPELLCAST_START", "player", "Cast-One", 116)
    state:combat("SPELL_CAST_START", 116, "Player-OtherMage")
    state:combat("SPELL_DAMAGE", 116)
    equal(#state.stopped, 0, "Impact must not cut off the next cast or another caster")
    state:fire("UNIT_SPELLCAST_INTERRUPTED", "player", "Cast-Old", 116)
    equal(#state.stopped, 0)
    state:fire("UNIT_SPELLCAST_INTERRUPTED", "player", "Cast-One", 116)
    equal(#state.stopped, 1)
    equal(state.stopped[1], 1)
    state:fire("UNIT_SPELLCAST_START", "player", "Cast-Two", 116)
    state:fire("UNIT_SPELLCAST_FAILED", "player", "Cast-Two", 116)
    equal(state.stopped[#state.stopped], 4)
    equal(state.addon.stats.cast, 3)
    equal(state.addon.stats.hit, 1)
end)

test("cast routing respects spoken packages, player sources and source and cast toggles", function()
    local state = setup({ soundPack = "spoken" })
    castPool(state)
    state:fire("UNIT_SPELLCAST_START", "target", "Cast-Target", 116)
    equal(#state.played, 0)
    state:combat("SPELL_CAST_START", 116, "Player-OtherMage")
    equal(#state.played, 1)
    state:combat("SPELL_CAST_START", 116, "Creature-Mage")
    state:combat("SPELL_CAST_START", 1449, "Player-OtherMage") -- Arcane Explosion is not supported.
    state.addon.SetOption("allSources", false)
    state:combat("SPELL_CAST_START", 116, "Player-OtherMage")
    equal(#state.played, 1)
    state:fire("UNIT_SPELLCAST_START", "player", "Cast-Own", 116)
    equal(#state.played, 2)
    SlashCmdList.GABBASOUNDS("cast off")
    state:fire("UNIT_SPELLCAST_START", "player", "Cast-Off", 116)
    equal(#state.played, 2)
    SlashCmdList.GABBASOUNDS("cast on")
    for _, pack in ipairs({ "magic", "spoken_wand", "spoken_bow", "spoken_gun" }) do
        state.addon.SetOption("soundPack", pack)
        state:fire("UNIT_SPELLCAST_START", "player", "Cast-" .. pack, 116)
    end
    equal(#state.played, 2)
    state.addon.SetOption("soundPack", "spoken_frostbolt")
    state.addon.SetOption("enabled", false)
    state:fire("UNIT_SPELLCAST_START", "player", "Cast-Disabled", 116)
    equal(#state.played, 2)
end)

test("cast checkbox, preview and persisted option work independently of impact categories", function()
    local state = setup({ soundPack = "spoken", cast = false })
    state.addon.OpenUI("mage")
    local checkbox = state.addon.ui.checks.cast
    local view = state.addon.ui.previews.mage
    local preview = view.buttons.cast
    equal(view.counts.cast.text, "2 Clips")
    equal(checkbox.checked, false)
    castPool(state)
    state.addon.RefreshUI()
    equal(view.counts.cast.text, "7 Clips")
    preview.scripts.OnClick(preview)
    equal(#state.played, 1)
    equal(state.addon.stats.cast, 0)
    checkbox.checked = true
    checkbox.scripts.OnClick(checkbox)
    equal(state.addon.db.cast, true)
    state:fire("UNIT_SPELLCAST_START", "player", "Cast-UI", 116)
    equal(#state.played, 2)
    state.addon.SetOption("hit", false)
    state:fire("UNIT_SPELLCAST_START", "player", "Cast-HitOff", 116)
    equal(#state.played, 3)
    state:combat("SPELL_DAMAGE", 116)
    equal(#state.played, 3)
    state.addon.SetOption("cast", false)
    local reloaded = setup(state.addon.db)
    equal(reloaded.addon.db.cast, false)
end)

test("all fifteen mage spells and every Classic rank have their own cast recordings", function()
    local state = setup({ soundPack = "spoken_mage" })
    local casts = 0
    equal(#state.addon.mageOrder, 15)
    for _, key in ipairs(state.addon.mageOrder) do
        local spell = state.addon.mageSpells[key]
        for _, rank in ipairs(spell.ranks) do
            local id = "Cast-All-" .. rank
            local event = spell.castMode == "channel" and "UNIT_SPELLCAST_CHANNEL_START"
                or spell.castMode == "start" and "UNIT_SPELLCAST_START" or "UNIT_SPELLCAST_SUCCEEDED"
            state:fire(event, "player", id, rank)
            casts = casts + 1
            voicePath(state, key, "cast")
            state:fire(event, "player", id, rank)
            state:combat("SPELL_CAST_SUCCESS", rank)
            equal(#state.played, casts, "One own sound despite repeated unit/log messages")
        end
    end
    equal(state.addon.stats.cast, casts)
    equal(state.addon.stats.hit, 0)
    state:combat("RANGE_DAMAGE", 5019)
    state:combat("RANGE_DAMAGE", 2480)
    equal(#state.played, casts, "Mage-only package does not replace weapons")
end)

test("single-target fire spells distinguish hit, crit, partial hit and every miss outcome", function()
    local state = setup({ soundPack = "spoken" })
    for _, key in ipairs({ "fireball", "fireblast", "scorch", "pyroblast" }) do
        local spell = state.addon.mageSpells[key]
        for _, id in ipairs(spell.ranks) do
            state:combat("SPELL_DAMAGE", id, nil, false, nil, 80, 0, 4, 4)
            voicePath(state, key, "hit")
            state:combat("SPELL_DAMAGE", id, nil, true, nil, 100, 20, 4, 4)
            voicePath(state, key, "crit")
        end
        local id = spell.ranks[1]
        state:combat("SPELL_DAMAGE", id, nil, false, nil, 80, 20, 4, 4)
        voicePath(state, "shared", "graze")
        for _, reason in ipairs({ "MISS", "RESIST", "ABSORB", "IMMUNE" }) do
            state:combat("SPELL_MISSED", id, nil, nil, reason)
            voicePath(state, "shared", "miss")
        end
        local before = #state.played
        state:combat("SPELL_PERIODIC_DAMAGE", id)
        state:combat("SPELL_AURA_APPLIED", id)
        state:combat("SPELL_DAMAGE", id, "Pet-Mage")
        state:combat("SPELL_DAMAGE", id, "Creature-Mage")
        equal(#state.played, before, "No DOT/aura/pet/NPC duplication")
    end
end)

test("instant and defensive casts trigger on success, regular casts on start and instant Frostbolt on success", function()
    local state = setup({ soundPack = "spoken_mage" })
    for _, key in ipairs({ "icebarrier", "iceblock", "frostward", "coldsnap", "combustion", "fireblast" }) do
        local id = state.addon.mageSpells[key].ranks[1]
        local before = #state.played
        state:fire("UNIT_SPELLCAST_START", "player", "Cast-" .. key, id)
        state:combat("SPELL_AURA_APPLIED", id)
        state:fire("UNIT_SPELLCAST_FAILED", "player", "Cast-" .. key, id)
        equal(#state.played, before)
        state:fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-" .. key, id)
        voicePath(state, key, "cast")
        equal(#state.played, before + 1)
    end
    state:fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-Instant-Frost", 116)
    voicePath(state, "frostbolt", "cast")
    state:fire("UNIT_SPELLCAST_START", "player", "Cast-Regular-Fire", 133)
    voicePath(state, "fireball", "cast")
    local before = #state.played
    state:fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-Regular-Fire", 133)
    equal(#state.played, before)
end)

test("AoE collects the target burst, prefers crit and emits one result for each application", function()
    local state = setup({ soundPack = "spoken_mage" })
    for _, key in ipairs({ "frostnova", "coneofcold", "flamestrike", "blastwave" }) do
        local id = state.addon.mageSpells[key].ranks[1]
        state.addon.BeginMageResult(state.guid, key)
        local before = #state.played
        state:combat("SPELL_MISSED", id, nil, nil, "RESIST")
        state:combat("SPELL_DAMAGE", id, nil, false)
        state:combat("SPELL_DAMAGE", id, nil, true)
        state:combat("SPELL_DAMAGE", id, nil, false)
        equal(#state.played, before, "Wait briefly for the other targets")
        state:advance(0.1)
        equal(#state.played, before + 1)
        voicePath(state, key, "crit")
        for _ = 1, 20 do state:combat("SPELL_DAMAGE", id, nil, true) end
        state:advance(0.1)
        equal(#state.played, before + 1, "Do not speak once per enemy")
        state.addon.BeginMageResult(state.guid, key)
        state:combat("SPELL_DAMAGE", id, nil, false)
        state:advance(0.1)
        voicePath(state, key, "hit")
        equal(#state.played, before + 2)
    end
end)

test("Blizzard speaks at channel start and on its first damage burst rather than every tick", function()
    local state = setup({ soundPack = "spoken_mage" })
    state:fire("UNIT_SPELLCAST_CHANNEL_START", "player", "Cast-Blizzard-One", 6141)
    voicePath(state, "blizzard", "cast")
    for tick = 1, 8 do
        for _ = 1, 5 do state:combat("SPELL_PERIODIC_DAMAGE", 6141, nil, false) end
        state:advance(1)
    end
    equal(#state.played, 2)
    voicePath(state, "blizzard", "hit")
    equal(state.addon.stats.cast, 1)
    equal(state.addon.stats.hit, 1)
    equal(state.addon.stats.crit, 0)
    state:fire("UNIT_SPELLCAST_CHANNEL_START", "player", "Cast-Blizzard-Two", 6141)
    state:combat("SPELL_PERIODIC_DAMAGE", 6141, nil, false)
    state:advance(0.1)
    equal(#state.played, 4)
end)

test("localized triggered Blizzard IDs are recognized without accepting unrelated periodic spells", function()
    local state = setup({ soundPack = "spoken_mage" })
    GetSpellInfo = function(id) if id == 10 then return "Schneesturm" end end
    state:combat("SPELL_PERIODIC_DAMAGE", 999999, nil, false)
    equal(#state.played, 0)
    state.currentEvent[13] = "Schneesturm"
    state:fire("COMBAT_LOG_EVENT_UNFILTERED")
    state:advance(0.1)
    voicePath(state, "blizzard", "hit")
end)

test("foreign casts follow source scope and never double a started regular cast on success", function()
    local state = setup({ soundPack = "spoken_mage" })
    state:combat("SPELL_CAST_START", 133, "Player-OtherMage")
    voicePath(state, "fireball", "cast")
    state:combat("SPELL_CAST_SUCCESS", 133, "Player-OtherMage")
    equal(#state.played, 1)
    state:combat("SPELL_CAST_SUCCESS", 133, "Player-OtherMage") -- Instant cast with no start.
    voicePath(state, "fireball", "cast")
    state:combat("SPELL_CAST_SUCCESS", 11426, "Player-OtherMage")
    voicePath(state, "icebarrier", "cast")
    state.addon.SetOption("allSources", false)
    local before = #state.played
    state:combat("SPELL_CAST_SUCCESS", 11426, "Player-OtherMage")
    state:combat("SPELL_DAMAGE", 133, "Player-OtherMage")
    equal(#state.played, before)
    state:fire("UNIT_SPELLCAST_SUCCEEDED", "player", "Cast-Barrier", 11426)
    voicePath(state, "icebarrier", "cast")
end)

test("queued AoE results disappear on disable, package change, world transition and logout", function()
    for _, action in ipairs({ "disable", "pack", "world", "logout" }) do
        local state = setup({ soundPack = "spoken" })
        state:combat("SPELL_DAMAGE", 122, nil, true)
        if action == "disable" then state.addon.SetOption("enabled", false)
        elseif action == "pack" then state.addon.SetOption("soundPack", "magic")
        elseif action == "world" then state:fire("PLAYER_ENTERING_WORLD")
        else state:fire("PLAYER_LOGOUT") end
        state:advance(0.1)
        equal(#state.played, 0, action)
    end
end)

test("new mage packages, selectors and slash previews use the chosen spell without changing routing", function()
    local state = setup({ soundPack = "spoken_mage" })
    equal(state.addon.originalsMuted, false)
    equal(state.addon.bowOriginalsMuted, false)
    equal(state.addon.gunOriginalsMuted, false)
    SlashCmdList.GABBASOUNDS("test hit")
    voicePath(state, "frostbolt", "hit")
    SlashCmdList.GABBASOUNDS("test cast fireball")
    voicePath(state, "fireball", "cast")
    SlashCmdList.GABBASOUNDS("test crit pyroblast")
    voicePath(state, "pyroblast", "crit")
    state.addon.OpenUI("mage")
    local view = state.addon.ui.previews.mage
    for index, key in ipairs(state.addon.mageOrder) do
        if index == 9 then view.next.scripts.OnClick() end
        local row = view.rows[(index - 1) % 8 + 1]
        equal(row.key, key)
        row.scripts.OnClick(row)
        assert(view.buttons.cast:IsEnabled())
        view.buttons.cast.scripts.OnClick()
        voicePath(state, key, "cast")
    end
    SlashCmdList.GABBASOUNDS("pack fireball")
    equal(state.addon.db.soundPack, "spoken_fireball")
    state:combat("SPELL_DAMAGE", 116)
    local before = #state.played
    state:combat("SPELL_DAMAGE", 133)
    voicePath(state, "fireball", "hit")
    equal(#state.played, before + 1)
end)

test("all mage original banks release owned mutes and retain independent owners on shared files", function()
    local state = setup({ soundPack = "spoken_mage" })
    for _, key in ipairs(state.addon.mageOrder) do
        equal(state.addon.mageOriginalsMuted[key], true)
        for _, id in ipairs(state.addon.mageSpells[key].originalIDs) do equal(state.muteDepth[id], 1) end
    end
    equal(#state.warmed, 27)
    MuteSoundFile(569764) -- Another owner of shared fire cast sound.
    state.addon.SetOption("muteOriginal", false)
    equal(state.muteDepth[569764], 1)
    for key, muted in pairs(state.addon.mageOriginalsMuted) do equal(muted, false, key) end
    state.addon.SetOption("muteOriginal", true)
    equal(state.muteDepth[569764], 2)
    equal(#state.warmed, 27)
    state.failPlayback = true
    state:fire("UNIT_SPELLCAST_START", "player", "Cast-Failed-File", 133)
    equal(state.muteDepth[569764], 1)
    state.failPlayback = false
    state.addon.PlayCategory("cast", true, nil, "fire", "fireball")
    equal(state.muteDepth[569764], 2)
    state:fire("PLAYER_LOGOUT")
    equal(state.muteDepth[569764], 1)
end)

test("missing new mage pools and incomplete categories leave their native bank uncovered", function()
    local state = setup({ soundPack = "spoken_fireball" })
    equal(state.addon.mageOriginalsMuted.fireball, true)
    for _, category in ipairs({ "hit", "crit", "miss", "resist", "absorb", "graze", "cast" }) do
        local bank = state.addon.voiceBanks.fireball
        local saved = bank[category]
        bank[category] = {}
        state.addon.UpdateOriginalMuting()
        equal(state.addon.mageOriginalsMuted.fireball, false)
        bank[category] = saved
        state.addon.UpdateOriginalMuting()
        equal(state.addon.mageOriginalsMuted.fireball, true)
    end
    state.addon.SetOption("cast", false)
    equal(state.addon.mageOriginalsMuted.fireball, false)
end)

test("replay real Classic mage channel and AoE logs without speaking for every target or tick", function()
    local fixture = assert(loadfile("tests/fixtures/classic_mage_aoe.lua"))()
    local state = setup({ soundPack = "spoken_mage" })
    for _, event in ipairs(fixture.events) do
        state:advance(event.time - state.time)
        state:combat(event.event, event.spellID, event.source, event.critical, event.missType,
            event.amount, event.resisted, 16, 16, event.blocked)
    end
    state:advance(0.1)
    equal(state.addon.stats.cast, fixture.expected.cast)
    equal(state.addon.stats.hit, fixture.expected.hit)
    equal(state.addon.stats.crit, fixture.expected.crit)
    equal(#state.played, fixture.expected.cast + fixture.expected.hit + fixture.expected.crit)
end)

local function equipMelee(state, main, off, unit)
    unit = unit or "player"
    state.meleeLinks[unit] = {}
    for slot, subclass in pairs({ [16] = main, [17] = off }) do
        local link = unit .. ":" .. slot .. ":" .. subclass
        state.meleeLinks[unit][slot] = link
        state.itemSubclasses[link] = subclass
    end
    state:fire("UNIT_INVENTORY_CHANGED", unit)
end

test("melee identifies the four weapon groups and never treats offhand as critical", function()
    local state = setup({ soundPack = "spoken" })
    for _, pair in ipairs({ {0,"blade"}, {1,"blade"}, {7,"blade"}, {8,"blade"},
        {4,"blunt"}, {5,"blunt"}, {10,"blunt"}, {15,"dagger"}, {13,"fist"} }) do
        equipMelee(state, pair[1], 15)
        state:advance(3)
        state:swing()
        voicePath(state, pair[2], "hit")
        state:advance(3)
        state:swing({offHand = true})
        voicePath(state, "dagger", "hit")
        state:swing({crit = true, offHand = true})
        voicePath(state, "dagger", "crit")
    end
    equal(state.addon.stats.crit, 9)
    equal(state.addon.stats.hit, 18)
end)

test("unarmed mainhand is fist but empty offhand and unsupported weapons stay silent", function()
    local state = setup({ soundPack = "spoken" })
    state:swing()
    voicePath(state, "fist", "hit")
    state:advance(3)
    state:swing({offHand = true})
    equal(#state.played, 1)
    for _, subclass in ipairs({6,20,2,19}) do
        equipMelee(state, subclass)
        state:swing()
        equal(#state.played, 1)
    end
end)

test("melee crit glancing partial block and absorption use the SWING payload", function()
    local state = setup({ soundPack = "spoken" })
    equipMelee(state, 7, 15)
    for _, options in ipairs({ {glancing = true}, {blocked = 5}, {resisted = 5} }) do
        state:advance(3)
        state:swing(options)
        voicePath(state, "shared", "graze")
    end
    state:advance(3)
    state:swing({crit = 1, glancing = 1, offHand = 1})
    voicePath(state, "dagger", "crit")
    state:advance(3)
    state:swing({absorbed = 10, crushing = true})
    voicePath(state, "blade", "hit")
    state.addon.SetOption("graze", false)
    state:advance(3)
    state:swing({glancing = true})
    voicePath(state, "blade", "hit")
end)

test("melee failures reuse shared comments and offhand miss uses slot 17", function()
    local state = setup({ soundPack = "spoken" })
    equipMelee(state, 6, 15)
    for _, miss in ipairs({ "MISS", "DODGE", "PARRY", "BLOCK", "RESIST", "ABSORB", "IMMUNE" }) do
        state:advance(3)
        state:swing({miss = miss, offHand = true})
        voicePath(state, "shared", "miss")
    end
    equal(state.addon.stats.miss, 5)
    equal(state.addon.stats.resist, 1)
    equal(state.addon.stats.absorb, 1)
end)

test("fast dual wield limits normals and protects reactions while allowing crit priority", function()
    local state = setup({ soundPack = "spoken" })
    equipMelee(state, 7, 15)
    state:swing()
    state:advance(0.1)
    state:swing({offHand = true})
    equal(#state.played, 1)
    state:advance(0.2)
    state:swing({offHand = true})
    equal(#state.played, 2)
    state:swing({miss = "MISS"})
    equal(#state.played, 3)
    state:advance(0.3)
    state:swing()
    equal(#state.played, 3)
    state:swing({crit = true})
    equal(#state.played, 4)
    state:advance(0.3)
    state:swing({crit = true, offHand = true})
    state:swing({miss = "DODGE"})
    state:swing()
    equal(#state.played, 4)
    state:advance(3)
    state:swing()
    equal(#state.played, 5)
    equal(state.addon.stats.crit, 1)
end)

test("melee scope filters pets creatures specials and independent foreign players", function()
    local state = setup({ soundPack = "spoken" })
    equipMelee(state, 7)
    state:swing({crit = true})
    local stopped = #state.stopped
    state:swing({source = "Player-Other"})
    voicePath(state, "blade", "hit")
    equal(#state.stopped, stopped)
    for _, source in ipairs({"Creature-1", "Pet-1", "Vehicle-1"}) do state:swing({source = source}) end
    state:combat("SPELL_DAMAGE", 78) -- Heroic Strike is not an auto attack.
    equal(#state.played, 2)
    state.addon.SetOption("allSources", false)
    state:advance(3)
    state:swing({source = "Player-Other"})
    equal(#state.played, 2)
    state:swing()
    equal(#state.played, 3)
end)

test("melee packs isolate their events and native sound ownership from mage and ranged", function()
    for _, pack in ipairs({ "magic", "spoken_wand", "spoken_bow", "spoken_gun", "spoken_mage", "spoken_fireball" }) do
        local state = setup({soundPack = pack})
        equipMelee(state, 7)
        state:swing()
        equal(#state.played, 0)
        equal(state.addon.meleeOriginalsMuted, false)
    end
    local state = setup({soundPack = "spoken_melee"})
    equipMelee(state, 7)
    equal(state.addon.originalsMuted, false)
    equal(state.addon.frostboltOriginalsMuted, false)
    equal(state.addon.bowOriginalsMuted, false)
    equal(state.addon.meleeOriginalsMuted, true)
    equal(#state.warmed, 301)
    state:combat("SPELL_DAMAGE", 133)
    state:combat("SPELL_CAST_SUCCESS", 133)
    state:fire("UNIT_SPELLCAST_START", "player", "Cast-1", 133)
    state:combat("RANGE_DAMAGE", 5019)
    state:combat("RANGE_DAMAGE", 75)
    state:advance(1)
    equal(#state.played, 0)
    state:swing()
    voicePath(state, "blade", "hit")
    state.addon.SetOption("soundPack", "spoken_dagger")
    equal(state.addon.meleeOriginalsMuted, false, "Shared native assets require all four banks")
    state:swing()
    equal(#state.played, 1)
    equipMelee(state, 15)
    state:swing()
    voicePath(state, "dagger", "hit")
end)

test("melee equipment cache changes per hand and expires for invisible players", function()
    local state = setup({soundPack = "spoken"})
    local guid = "Player-Visible"
    state.units.target = guid
    equipMelee(state, 7, 15, "target")
    equal(state.addon.ResolveMeleeWeapon(guid, false), "blade")
    equal(state.addon.ResolveMeleeWeapon(guid, true), "dagger")
    state.units.target = nil
    equal(state.addon.ResolveMeleeWeapon(guid, true), "dagger")
    state:advance(121)
    equal(state.addon.ResolveMeleeWeapon(guid, true), "melee")
    state.units.target = guid
    equipMelee(state, 4, nil, "target")
    equal(state.addon.ResolveMeleeWeapon(guid, false), "blunt")
    equal(state.addon.ResolveMeleeWeapon(guid, true), nil)
    state:fire("PLAYER_ENTERING_WORLD")
    state.units.target = nil
    equal(state.addon.ResolveMeleeWeapon(guid, false), "melee")
end)

test("melee item API fallback works and druid forms are excluded", function()
    local state = setup({soundPack = "spoken"})
    equipMelee(state, 15)
    GetItemInfoInstant = C_Item.GetItemInfoInstant
    C_Item = nil
    equal(state.addon.ResolveMeleeWeapon(state.guid), "dagger")
    state.classes.player = "DRUID"
    state.form = 0
    equal(state.addon.ResolveMeleeWeapon(state.guid), "dagger")
    state.form = 1
    state:swing()
    equal(#state.played, 0)
    state.form = nil
    state:swing()
    voicePath(state, "dagger", "hit")
end)

test("melee native mutes fail open and preserve another owner's mute", function()
    local state = setup({soundPack = "spoken"})
    local id = state.addon.meleeOriginalIDs[1]
    equal(#state.addon.meleeOriginalIDs, 301)
    MuteSoundFile(id)
    state.failPlayback = true
    state:swing()
    equal(state.addon.meleeOriginalsMuted, false)
    equal(state.muteDepth[id], 1)
    state.failPlayback = false
    state.addon.PlayCategory("hit", true, nil, "neutral", "fist")
    equal(state.addon.meleeOriginalsMuted, true)
    equal(state.muteDepth[id], 2)
    state.addon.SetOption("graze", false)
    equal(state.addon.meleeOriginalsMuted, false)
    equal(state.muteDepth[id], 1)
    state.addon.SetOption("graze", true)
    state.addon.voiceBanks.blade.crit = {}
    state.addon.UpdateOriginalMuting()
    equal(state.addon.meleeOriginalsMuted, false)
    state:fire("PLAYER_LOGOUT")
    equal(state.muteDepth[id], 1)
end)

test("melee interval settings and UI previews cover every new bank", function()
    local state = setup({soundPack = "spoken_melee", meleeInterval = "bad"})
    equal(state.addon.db.meleeInterval, 0.25)
    for _, value in ipairs({-1,3,math.huge,"0.5",false}) do equal(state.addon.SetOption("meleeInterval", value), false) end
    equal(state.addon.SetOption("meleeInterval", 0/0), false)
    SlashCmdList.GABBASOUNDS("meleeinterval 0.5")
    equal(state.addon.db.meleeInterval, 0.5)
    equipMelee(state, 7)
    state.addon.SetOption("meleeInterval", 2)
    state:swing()
    state:advance(1.5)
    state:swing()
    equal(#state.played, 1, "Interval applies even after the previous clip has ended")
    state:advance(0.6)
    state:swing()
    equal(#state.played, 2)
    state.addon.SetOption("meleeInterval", 0.5)
    state.addon.OpenUI("weapons")
    local ui = state.addon.ui
    ui.interval.scripts.OnClick()
    equal(state.addon.db.meleeInterval, 0.75)
    local view = ui.previews.weapons
    for index, key in ipairs(state.addon.meleeOrder) do
        local row = view.rows[index + 3]
        equal(row.key, key)
        row.scripts.OnClick(row)
        view.buttons.hit.scripts.OnClick()
        voicePath(state, key, "hit")
        SlashCmdList.GABBASOUNDS("test crit " .. key)
        voicePath(state, key, "crit")
    end
    SlashCmdList.GABBASOUNDS("pack melee")
    equal(state.addon.db.soundPack, "spoken_melee")
    SlashCmdList.GABBASOUNDS("pack blade")
    equal(state.addon.db.soundPack, "spoken_blade")
end)

test("replay anonymized Classic melee results including real glances and failures", function()
    local state = setup({soundPack = "spoken"})
    local fixture = assert(loadfile("tests/fixtures/classic_melee.lua"))()
    local expected = { hit = 0, crit = 0, graze = 0, miss = 0, resist = 0, absorb = 0 }
    for _, event in ipairs(fixture) do
        state:advance(3)
        state:swing(event)
        expected[event.expected] = expected[event.expected] + 1
    end
    equal(#state.played, #fixture)
    for category, count in pairs(expected) do equal(state.addon.stats[category], count, category) end
end)

test("Noggenfogger only pitches own sounds while the shrink aura is active", function()
    local state = setup()
    local function pitched()
        return state.played[#state.played].path:find("\\noggenfogger\\", 1, true) ~= nil
    end
    equal(state.addon.db.noggenfoggerPitch, true)
    state.auras = { 16593, 16591 }
    state:fire("UNIT_AURA", "player")
    state:combat("RANGE_DAMAGE")
    equal(pitched(), false, "Other elixir effects must not trigger pitch")
    state.auras = { 16593, 16595 }
    state:fire("UNIT_AURA", "target")
    state:combat("RANGE_DAMAGE")
    equal(pitched(), false, "Foreign aura updates are ignored")
    state:fire("UNIT_AURA", "player")
    state:combat("RANGE_DAMAGE")
    equal(pitched(), true)
    state:combat("RANGE_DAMAGE", 5019, "Player-Other")
    equal(pitched(), false, "Foreign attacks keep their normal voice")
    state.addon.PlayCategory("crit", true)
    equal(pitched(), true, "Preview follows the player's effect")
    state.auras = {}
    state:fire("UNIT_AURA", "player")
    state:combat("RANGE_DAMAGE")
    equal(pitched(), false)
end)

test("Noggenfogger survives reload and world changes with Classic aura fallback", function()
    local state = setup(nil, nil, { 16595 })
    equal(state.addon.noggenfoggerShrunk, true, "Detected during addon load")
    C_UnitAuras = nil
    state.auras = { 16591 }
    state:fire("PLAYER_ENTERING_WORLD")
    equal(state.addon.noggenfoggerShrunk, false)
    state.auras = { 16591, 16595 }
    state:fire("PLAYER_LOGIN")
    equal(state.addon.noggenfoggerShrunk, true)
    UnitBuff = nil
    state:fire("UNIT_AURA", "player")
    equal(state.addon.noggenfoggerShrunk, false, "Missing APIs safely keep normal pitch")
end)

test("Noggenfogger setting applies to spoken casts melee failures and all magic schools", function()
    local state = setup(nil, nil, { 16595 })
    for _, school in ipairs(state.addon.schoolOrder) do
        state.addon.PlayCategory("hit", true, nil, school)
        assert(state.played[#state.played].path:find("\\noggenfogger\\", 1, true))
    end
    state.addon.SetOption("soundPack", "spoken")
    for _, item in ipairs({ { "cast", "fireball" }, { "hit", "wand" }, { "crit", "bow" },
        { "hit", "gun" }, { "crit", "blade" }, { "miss", "dagger" }, { "graze", "fist" } }) do
        state.addon.PlayCategory(item[1], false, state.guid, "neutral", item[2])
        assert(state.played[#state.played].path:find("\\noggenfogger\\", 1, true))
    end
    SlashCmdList.GABBASOUNDS("noggenfogger off")
    equal(state.addon.db.noggenfoggerPitch, false)
    state.addon.PlayCategory("hit", true)
    assert(not state.played[#state.played].path:find("\\noggenfogger\\", 1, true))
    SlashCmdList.GABBASOUNDS("noggenfogger on")
    equal(state.addon.db.noggenfoggerPitch, true)
    state.addon.OpenUI()
    local check
    for _, frame in ipairs(state.frames) do
        if frame.label and frame.label.text == "Noggenfogger: beim Schrumpfen höher" then check = frame end
    end
    assert(check and check.checked)
    check:SetChecked(false); check.scripts.OnClick(check)
    equal(state.addon.db.noggenfoggerPitch, false)
end)

test("Missing Noggenfogger audio falls back without losing original mute ownership", function()
    local state = setup(nil, nil, { 16595 })
    state.failPitch = true
    state:combat("RANGE_DAMAGE")
    equal(#state.played, 2)
    equal(state.addon.stats.hit, 1)
    equal(state.addon.originalsMuted, true)
    assert(not state.played[2].path:find("\\noggenfogger\\", 1, true))
    local messages = #state.messages
    state:combat("RANGE_DAMAGE")
    equal(#state.messages, messages, "Warn only once")
    state.failPlayback = true
    state:combat("RANGE_DAMAGE")
    equal(state.addon.originalsMuted, false, "Failure of both variants still fails open")
end)

test("mage buff options validate persist and expose separate warning previews", function()
    local state = setup({ mageBuffAlerts = "invalid", mageBuffIntellect = false, mageBuffSound = "invalid" })
    equal(state.addon.db.mageBuffAlerts, true)
    equal(state.addon.db.mageBuffIntellect, false)
    equal(state.addon.db.mageBuffArmor, true)
    equal(state.addon.db.mageBuffSound, true)
    equal(state.addon.db.priestBuffAlerts, true)
    equal(state.addon.db.priestBuffFearWard, false)
    SlashCmdList.GABBASOUNDS("buffs off")
    equal(state.addon.db.mageBuffAlerts, false)
    SlashCmdList.GABBASOUNDS("buffs on")
    equal(state.addon.db.mageBuffAlerts, true)
    SlashCmdList.GABBASOUNDS("buffs")
    assert(GabbaSoundsBuffPanel:IsShown())
    local check = state.addon.ui.buffChecks.mageBuffSound
    assert(check and check.checked)
    check:SetChecked(false); check.scripts.OnClick(check)
    equal(state.addon.db.mageBuffSound, false)
    state.addon.buffAlertSounds.intellect.expiring = "test_buff_expiring.ogg"
    SlashCmdList.GABBASOUNDS("buffs intellect expiring")
    equal(#state.played, 1)
    assert(state.played[1].path:find("test_buff_expiring.ogg", 1, true))
    state.addon.OpenUI()
    local button
    for _, frame in ipairs(state.frames) do if frame.text == "Buffwarnungen" then button = frame end end
    assert(button)
    GabbaSoundsBuffPanel:Hide(); button.scripts.OnClick()
    assert(GabbaSoundsBuffPanel:IsShown())
end)

test("priest buff UI uses its own saved options and preview keys", function()
    local state = setup({ priestBuffFortitude = false, priestBuffFearWard = "invalid" })
    state.classes.player = "PRIEST"
    equal(state.addon.db.priestBuffFortitude, false)
    equal(state.addon.db.priestBuffFearWard, false)
    SlashCmdList.GABBASOUNDS("buffs off")
    equal(state.addon.db.priestBuffAlerts, false)
    equal(state.addon.db.mageBuffAlerts, true)
    SlashCmdList.GABBASOUNDS("buffs on")
    equal(state.addon.db.priestBuffAlerts, true)
    SlashCmdList.GABBASOUNDS("buffs")
    assert(GabbaSoundsBuffPanel:IsShown())
    local fearCheck
    for _, frame in ipairs(state.frames) do
        if frame.label and frame.label.text == "Furchtzauberschutz (Zwerg, optional)" then fearCheck = frame end
    end
    assert(fearCheck and not fearCheck.checked)
    fearCheck:SetChecked(true); fearCheck.scripts.OnClick(fearCheck)
    equal(state.addon.db.priestBuffFearWard, true)
    state.addon.priestBuffGenericSounds.innerFire.missing = "test_innerfire_missing.ogg"
    SlashCmdList.GABBASOUNDS("buffs innerfire missing")
    equal(#state.played, 1)
    assert(state.played[1].path:find("test_innerfire_missing.ogg", 1, true))
end)

local function herbalist(saved, auras)
    local state = setup(saved, nil, auras)
    state.herbalist = true
    state:fire("SKILL_LINES_CHANGED")
    function state:hover(lines, focus, owner)
        self.herbLines = type(lines) == "table" and lines or { lines }
        self.focus = focus or Minimap
        GameTooltip:SetOwner(owner or UIParent)
        GameTooltip:Show()
    end
    function state:tooltipTick(seconds)
        seconds = seconds or .2
        self:advance(seconds)
        if GameTooltip:IsShown() then GameTooltip.scripts.OnUpdate(GameTooltip, seconds) end
    end
    return state
end

test("herbs recognize native Classic UIParent and Minimap tooltips in German and English", function()
    for _, name in ipairs({ "Gromsblut", "Gromsblood", "Schwarzer Lotus", "Black Lotus" }) do
        local state = herbalist()
        state:hover("|cffffff00" .. name .. "|r")
        state:tooltipTick()
        equal(#state.played, 1)
        assert(state.played[1].path:find(name:find("Lotus") and "voice_herb_blacklotus.ogg" or "voice_herb_gromsblood.ogg", 1, true))
    end
    local state = herbalist()
    state:hover("Gromsblood", Minimap, Minimap); state:tooltipTick()
    equal(#state.played, 1)
end)

test("herb alert requires Herbalism while previews work without profession or enabled addon", function()
    local state = herbalist()
    state.herbalist = false; state:fire("SPELLS_CHANGED")
    state:hover("Black Lotus"); state:tooltipTick(); equal(#state.played, 0)
    SlashCmdList.GABBASOUNDS("off")
    SlashCmdList.GABBASOUNDS("herbs blacklotus"); equal(#state.played, 1)
    state.herbalist = true; state:fire("PLAYER_LOGIN")
    state:tooltipTick(); equal(#state.played, 1)
    SlashCmdList.GABBASOUNDS("on"); state:tooltipTick(); equal(#state.played, 2)
end)

test("herb alerts ignore bag and linked items spells units and stored minimap pins", function()
    local state = herbalist()
    state:hover("Black Lotus", WorldFrame)
    state.herbItemLink = "item:13468"; state:tooltipTick(); equal(#state.played, 0)
    state.herbItemLink = nil; state.herbSpell = "Black Lotus"; state:tooltipTick(); equal(#state.played, 0)
    state.herbSpell = nil; state.herbUnit = "Black Lotus"; state:tooltipTick(); equal(#state.played, 0)
    state.herbUnit = nil
    local pin = CreateFrame("Frame")
    state:hover("Black Lotus", pin, pin); state:tooltipTick(); equal(#state.played, 0)
    state:hover("Black Lotus", pin, UIParent); state:tooltipTick(); equal(#state.played, 0)
    state:hover("Black Lotus", Minimap, pin); state:tooltipTick(); equal(#state.played, 0)
    state:hover("Black Lotus", WorldFrame); state:tooltipTick(); equal(#state.played, 1)
end)

test("herb cooldown survives hiding and unchanged hover never repeats after 30 seconds", function()
    local state = herbalist()
    state:hover("Gromsblood"); state:tooltipTick(); equal(#state.played, 1)
    state:tooltipTick(35); equal(#state.played, 1)
    GameTooltip:Hide(); state:hover("Gromsblood"); state:tooltipTick(); equal(#state.played, 2)
    GameTooltip:Hide(); state:hover("Gromsblood"); state:tooltipTick(); equal(#state.played, 2)
    state:hover("Black Lotus"); state:tooltipTick(); equal(#state.played, 3, "Separate cooldowns for each herb")
end)

test("herb tooltip updates multi-line names and Classic legacy focus/font strings work", function()
    local state = herbalist()
    state:hover({ "Something else", "Gromsblood", "Black Lotus" }); state:tooltipTick()
    assert(state.played[1].path:find("blacklotus.ogg", 1, true))
    GetMouseFoci = nil
    function GetMouseFocus() return state.focus end
    GameTooltip.GetLeftLine = false
    GameTooltipTextLeft1 = { GetText = function() return "Gromsblut" end }
    state.herbLines = { "Gromsblut" }; state:tooltipTick()
    equal(#state.played, 2)
    GameTooltipTextLeft1 = nil
end)

test("herb switches stop only herb audio preserve mutes and reset on world changes", function()
    local state = herbalist()
    state:combat("RANGE_DAMAGE")
    state:hover("Gromsblood"); state:tooltipTick(); equal(#state.played, 2)
    SlashCmdList.GABBASOUNDS("herbs off")
    equal(#state.stopped, 1); equal(state.stopped[1], 2)
    equal(state.addon.originalsMuted, true)
    state:tooltipTick(31); equal(#state.played, 2)
    SlashCmdList.GABBASOUNDS("herbs on"); state:tooltipTick(); equal(#state.played, 3)
    state:fire("PLAYER_ENTERING_WORLD"); state:tooltipTick(); equal(#state.played, 4)
    state:fire("PLAYER_LOGOUT"); assert(#state.stopped >= 3)
end)

test("herb playback failure stays isolated and pitch falls back without warning spam", function()
    local state = herbalist(nil, {16595})
    state.failPitch = true
    state:hover("Black Lotus"); state:tooltipTick()
    equal(#state.played, 2)
    assert(state.played[1].path:find("\\noggenfogger\\", 1, true))
    assert(not state.played[2].path:find("\\noggenfogger\\", 1, true))
    state.failPlayback = true
    state:hover("Gromsblood"); state:tooltipTick()
    equal(state.addon.originalsMuted, true)
    local messages = #state.messages
    GameTooltip:Hide(); state:hover("Gromsblood"); state:tooltipTick()
    equal(#state.messages, messages)
end)

test("herb settings validate and options expose both independent previews", function()
    local state = herbalist({ herbAlerts = "invalid" })
    equal(state.addon.db.herbAlerts, true)
    SlashCmdList.GABBASOUNDS("herbs"); assert(GabbaSoundsHerbPanel:IsShown())
    local check
    for _, frame in ipairs(state.frames) do
        if frame.label and frame.label.text == "Kräuter-Alarm beim Darüberfahren" then check = frame end
    end
    assert(check and check.checked)
    check:SetChecked(false); check.scripts.OnClick(check); equal(state.addon.db.herbAlerts, false)
    SlashCmdList.GABBASOUNDS("herbs gromsblood")
    SlashCmdList.GABBASOUNDS("herbs blacklotus"); equal(#state.played, 2)
end)

test("retired herb test settings cannot trigger alerts for low-level herbs", function()
    local s = herbalist({herbTest = true})
    equal(s.addon.db.herbTest, nil)
    for _, name in ipairs({"Silverleaf", "Silberblatt", "Peacebloom", "Friedensblume", "Earthroot", "Erdwurzel"}) do
        s:hover(name); s:tooltipTick(); equal(#s.played, 0)
    end
    s:hover("Black Lotus"); s:tooltipTick(); equal(#s.played, 1)
    s:hover("Gromsblut"); s:tooltipTick(); equal(#s.played, 2)
end)

test("priest direct spells use all Classic ranks and separate hit/crit banks", function()
    for key, ranks in pairs({ mindblast = {8092,8102,8103,8104,8105,8106,10945,10946,10947}, smite = {585,591,598,984,1004,6060,10933,10934} }) do
        local s = setup({ soundPack = "spoken_priest" })
        for _, id in ipairs(ranks) do s:combat("SPELL_DAMAGE", id); s:combat("SPELL_DAMAGE", id, nil, true) end
        equal(s.addon.stats.hit, #ranks); equal(s.addon.stats.crit, #ranks)
        equal(#s.addon.voiceBanks[key].hit, 4); equal(#s.addon.voiceBanks[key].crit, 4)
        assert(s.played[1].path:find("voice_" .. key .. "_hit_", 1, true))
        assert(s.played[2].path:find("voice_" .. key .. "_crit_", 1, true))
    end
end)
test("Shadow Word Pain reacts on application and refresh, never ticks or removal", function()
    local s = setup({ soundPack = "spoken_priest" })
    s:combat("SPELL_CAST_SUCCESS", 589); equal(#s.played, 0)
    s:combat("SPELL_AURA_APPLIED", 589, nil, nil, "DEBUFF"); equal(#s.played, 1)
    for _, event in ipairs({"SPELL_PERIODIC_DAMAGE", "SPELL_PERIODIC_MISSED", "SPELL_AURA_REMOVED", "SPELL_HEAL"}) do s:combat(event, 589) end
    equal(#s.played, 1)
    s:combat("SPELL_AURA_REFRESH", 10894, nil, nil, "DEBUFF"); equal(#s.played, 2)
    equal(s.addon.stats.crit, 0)
    s:combat("SPELL_MISSED", 589, nil, nil, "RESIST"); equal(s.addon.stats.resist, 1)
end)
test("Holy Nova combines damage targets, favors crits and ignores its healing", function()
    local s = setup({ soundPack = "spoken_priest" })
    s:combat("SPELL_CAST_SUCCESS", 27801); s:combat("SPELL_HEAL", 27805)
    s:combat("SPELL_DAMAGE", 27801); s:combat("SPELL_MISSED", 27801, nil, nil, "RESIST")
    s:combat("SPELL_DAMAGE", 27801, nil, true); equal(#s.played, 0)
    s:advance(.08); equal(#s.played, 1); equal(s.addon.stats.crit, 1)
    s:combat("SPELL_DAMAGE", 27801); s:advance(.1); equal(#s.played, 1)
    s:combat("SPELL_CAST_SUCCESS", 15237); s:combat("SPELL_DAMAGE", 15237)
    s:advance(.08); equal(#s.played, 2); equal(s.addon.stats.hit, 1)
end)
test("priest packs isolate weapons/mages and retain source filters and shared failures", function()
    for _, pack in ipairs({"magic", "spoken_mage", "spoken_melee", "spoken_wand"}) do
        local s = setup({ soundPack = pack }); s:combat("SPELL_DAMAGE", 8092); equal(#s.played, 0)
    end
    local s = setup({ soundPack = "spoken_priest", allSources = false })
    s:combat("SPELL_DAMAGE", 8092, "Player-Other"); s:combat("SPELL_DAMAGE", 8092, "Creature-Other")
    s:combat("SPELL_DAMAGE", 116); s:combat("RANGE_DAMAGE"); s:swing(); equal(#s.played, 0)
    s:combat("SPELL_MISSED", 8092, nil, nil, "ABSORB"); equal(s.addon.stats.absorb, 1)
    s:combat("SPELL_DAMAGE", 8092, nil, nil, nil, 50, 5); equal(s.addon.stats.graze, 1)
    s.addon.SetOption("graze", false)
    s:combat("SPELL_DAMAGE", 585, nil, nil, nil, 50, 5); equal(s.addon.stats.hit, 1)
    s.addon.SetOption("soundPack", "spoken"); s.addon.SetOption("allSources", true)
    s:combat("SPELL_DAMAGE", 585, "Player-Other"); equal(s.addon.stats.hit, 2)
end)
test("priest previews and Noggenfogger use their own banks", function()
    local s = setup({ soundPack = "spoken_priest" }, nil, {16595})
    s:combat("SPELL_DAMAGE", 8092)
    assert(s.played[1].path:find("\\noggenfogger\\voice_mindblast_hit_", 1, true))
    SlashCmdList.GABBASOUNDS("pack priest"); equal(s.addon.db.soundPack, "spoken_priest")
    SlashCmdList.GABBASOUNDS("test crit holynova"); equal(#s.played, 2)
    SlashCmdList.GABBASOUNDS("test crit shadowwordpain"); equal(#s.played, 2)
    SlashCmdList.GABBASOUNDS("pack smite"); equal(s.addon.db.soundPack, "spoken_smite")
end)
test("priest muting requires complete replacements and restores on playback failure", function()
    local s = setup({ soundPack = "spoken_priest" })
    for _, key in ipairs(s.addon.priestOrder) do equal(s.addon.priestOriginalsMuted[key], true) end
    equal(s.addon.originalsMuted, false); equal(s.addon.frostboltOriginalsMuted, false)
    equal(s.addon.meleeOriginalsMuted, false)
    s.addon.voiceBanks.shadowwordpain.hit = {}; s.addon.UpdateOriginalMuting()
    equal(s.addon.priestOriginalsMuted.shadowwordpain, false)
    s.failPlayback = true; s:combat("SPELL_DAMAGE", 8092)
    for _, key in ipairs(s.addon.priestOrder) do equal(s.addon.priestOriginalsMuted[key], false) end
end)

test("unified shortcuts reuse one parent and fit small screens without losing preferences", function()
    local s = setup({soundPack = "spoken_priest", minimapHidden = true})
    UIParent:SetSize(640, 480)
    s.addon.OpenUI("priest")
    local ui = s.addon.ui
    equal(ui.frame.strata, "MEDIUM", "Options must share the normal Blizzard window layer")
    equal(ui.frame.toplevel, true, "Click order must control window stacking, like Gabba")
    assert(ui.frame.scale < 1)
    assert(ui.frame.width * ui.frame.scale <= 608)
    assert(ui.frame.height * ui.frame.scale <= 448)
    local count = #s.frames
    SlashCmdList.GABBASOUNDS("herbs")
    equal(ui.selected, "herbs"); assert(ui.pages.herbs:IsShown())
    equal(ui.pages.priest:IsShown(), false)
    SlashCmdList.GABBASOUNDS("buffs")
    equal(ui.selected, "buffs"); equal(ui.pages.herbs:IsShown(), false)
    equal(ui.pages.buffs.parent, ui.frame); equal(ui.pages.herbs.parent, ui.frame)
    equal(#s.frames, count); equal(#UISpecialFrames, 1)
    ui.frame:Hide(); s.addon.OpenUI()
    equal(ui.selected, "buffs"); assert(ui.pages.buffs:IsShown())
    equal(s.addon.db.soundPack, "spoken_priest")
    equal(ui.checks.minimapHidden.checked, false)
    ui.checks.minimapHidden:SetChecked(true)
    ui.checks.minimapHidden.scripts.OnClick(ui.checks.minimapHidden)
    equal(s.addon.db.minimapHidden, false)
    UIParent:SetSize(1280, 800)
    ui.frame.scripts.OnEvent(ui.frame, "DISPLAY_SIZE_CHANGED")
    equal(ui.frame.scale, 1)
end)

test("previews expose only valid priest results and never alter package or native mutes", function()
    local s = setup({soundPack = "magic"})
    s.addon.OpenUI("priest")
    local ui, muted = s.addon.ui, {}
    for key, value in pairs(s.muteDepth) do muted[key] = value end
    local view = ui.previews.priest
    equal(view.buttons.cast, nil, "Priest previews must not borrow Frostbolt casts")
    view.buttons.hit.scripts.OnClick()
    voicePath(s, "mindblast", "hit")
    view.rows[2].scripts.OnClick(view.rows[2])
    equal(view.selected, "shadowwordpain")
    equal(view.buttons.crit:IsEnabled(), false)
    equal(view.counts.crit.text, "0 Clips")
    view.buttons.hit.scripts.OnClick()
    voicePath(s, "shadowwordpain", "hit")
    equal(s.addon.db.soundPack, "magic"); equal(s.addon.stats.hit, 0)
    for key, value in pairs(s.muteDepth) do equal(value, muted[key]) end
    local stopped = #s.stopped
    ui.nav.general.scripts.OnClick()
    equal(#s.stopped, stopped + 1, "Changing pages stops the preview tail")
    ui.packButton.scripts.OnClick()
    ui.pickerMask.scripts.OnClick()
    equal(ui.picker:IsShown(), false); equal(s.addon.db.soundPack, "magic")
    s.addon.OpenUI("priest")
    view.activate.scripts.OnClick()
    equal(s.addon.db.soundPack, "spoken_shadowwordpain")
end)

test("priest buff previews stay accessible without exposing a personal voice selector", function()
    local previousName = UnitName
    for _, identity in ipairs({{ "Other", "WARRIOR" }, { "AnotherPriest", "PRIEST" }, { "Bobselinchen", "PRIEST" }, { "Bobselinchen", "MAGE" }}) do
        local s = setup()
        s.classes.player = identity[2]
        UnitName = function() return identity[1] end
        s.addon.OpenUI("buffs")
        local ui = s.addon.ui
        equal(ui.buffProfile, identity[2] == "PRIEST" and "priest" or "mage")
        ui.buffTabs.priest.scripts.OnClick()
        equal(#ui.buffRows, 4)
        equal(ui.buffVoiceButton, nil)
        equal(ui.buffProfiles.mage.frame:IsShown(), false)
        equal(ui.buffProfiles.priest.frame:IsShown(), true)
        assert(not ui.buffNote.text:find("Bobselinchen", 1, true))
        for _, frame in ipairs(s.frames) do
            assert(not (frame.text and frame.text:find("Bobselinchen", 1, true)))
        end
        local special = identity[1] == "Bobselinchen" and identity[2] == "PRIEST"
        local bank = special and s.addon.buffAlertSounds or s.addon.priestBuffGenericSounds
        for _, row in ipairs(ui.buffRows) do
            for _, phase in ipairs({"expiring", "missing"}) do
                local button = row.buttons[phase]
                assert(button:IsEnabled())
                button.scripts.OnClick()
                assert(s.played[#s.played].path:find(bank[row.key][phase], 1, true))
            end
        end
        equal(#s.played, 8)
        equal(s.addon.GetBuffAlertProfile().class, identity[2] == "PRIEST" and "PRIEST" or "MAGE")
        local fort = ui.buffChecks.priestBuffFortitude
        fort:SetChecked(false); fort.scripts.OnClick(fort)
        equal(s.addon.db.priestBuffFortitude, false)
        equal(s.addon.db.mageBuffIntellect, true)
        ui.buffTabs.mage.scripts.OnClick()
        equal(#ui.buffRows, 2)
        ui.buffRows[1].buttons.expiring.scripts.OnClick()
        assert(s.played[#s.played].path:find("voice_buff_intellect_expiring.ogg", 1, true))
        equal(s.addon.db.soundPack, "magic")
        equal(ui.nav.magic.text, "Zauberstab-Sounds")
    end
    UnitName = previousName
end)

print(string.format("GabbaSounds: %d tests passed", total))
