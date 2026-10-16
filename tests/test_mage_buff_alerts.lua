local total = 0
local function eq(a, b, why) assert(a == b, (why or "Mismatch") .. ": " .. tostring(a) .. " ~= " .. tostring(b)) end
local function setup(name, class)
    local s = { now = 0, frames = {}, auras = {}, known = { [1459] = true, [168] = true },
        units = { player = { name = name or "Minibobsel", class = class or "MAGE", guid = "self" } },
        messages = {}, played = {}, stopped = {}, group = 0, raid = false }
    local methods = {}
    for _, method in ipairs({ "SetSize", "SetPoint", "SetFrameStrata", "SetFont", "SetWidth", "SetJustifyH", "SetTextColor" }) do methods[method] = function() end end
    function methods:SetScript(key, value) self.scripts[key] = value end
    function methods:RegisterEvent(event) self.events[event] = true end
    function methods:CreateFontString() return setmetatable({}, { __index = methods }) end
    function methods:SetText(value) s.bannerText = value end
    function methods:Show() self.shown = true end
    function methods:Hide() self.shown = false end
    function methods:IsShown() return self.shown end
    function methods:SetAlpha(value) self.alpha = value end
    function CreateFrame(_, name)
        local f = setmetatable({ scripts = {}, events = {}, shown = false, name = name }, { __index = methods })
        s.frames[#s.frames + 1] = f
        if name == "GabbaSoundsBuffWarning" then s.banner = f end
        return f
    end
    UIParent = {}
    function UnitName(unit) return s.units[unit] and s.units[unit].name end
    function UnitClass(unit) return "Class", s.units[unit] and s.units[unit].class end
    function UnitGUID(unit) return s.units[unit] and s.units[unit].guid end
    function GetUnitName(unit) return UnitName(unit) end
    function UnitIsUnit(a, b) return UnitGUID(a) == UnitGUID(b) end
    function UnitIsConnected(unit) return s.units[unit] and not s.units[unit].offline end
    function UnitIsVisible(unit) return s.units[unit] and not s.units[unit].invisible end
    function UnitIsDeadOrGhost(unit) return s.units[unit] and s.units[unit].dead end
    function UnitOnTaxi() return s.taxi end
    function GetTime() return s.now end
    function IsInRaid() return s.raid end
    function GetNumGroupMembers() return s.group end
    function GetNumSubgroupMembers() return s.group end
    function IsSpellKnown(id) return s.known[id] end
    IsPlayerSpell = nil
    local labels = { [1459] = "Int", [23028] = "Brilliance", [168] = "Frost Armor", [7302] = "Ice Armor", [6117] = "Mage Armor" }
    function GetSpellInfo(id) return labels[id] end
    function wipe(t) for k in pairs(t) do t[k] = nil end end
    C_UnitAuras = { GetAuraDataByIndex = function(unit, i, filter)
        eq(filter, "HELPFUL")
        return s.auras[unit] and s.auras[unit][i]
    end }
    function UnitBuff(unit, i)
        local aura = s.auras[unit] and s.auras[unit][i]
        if aura then return aura.name, nil, nil, nil, nil, aura.expirationTime, nil, nil, nil, aura.spellId end
    end
    function StopSound(handle) s.stopped[#s.stopped + 1] = handle end
    function PlaySoundFile(path, channel)
        s.played[#s.played + 1] = { path = path, channel = channel }
        if s.failSound then return false end
        return true, #s.played
    end
    local addon = { db = { enabled = true, mageBuffAlerts = true, mageBuffIntellect = true, mageBuffArmor = true, mageBuffSound = true, channel = "SFX" }, soundDurations = {} }
    addon.Print = function(msg) assert(msg ~= "", "No empty chat spam"); s.messages[#s.messages + 1] = msg end
    addon.NoggenfoggerSound = function(file) return s.pitch and "noggenfogger\\" .. file or file end
    assert(loadfile("BuffAlertSoundData.lua"))("GabbaSounds", addon)
    assert(loadfile("MageBuffAlerts.lua"))("GabbaSounds", addon)
    for _, key in ipairs({ "intellect", "armor" }) do
        for _, phase in ipairs({ "expiring", "missing" }) do
            local file = key .. "_" .. phase .. ".ogg"
            addon.buffAlertSounds[key][phase], addon.soundDurations[file] = file, 1
        end
    end
    s.addon = addon
    addon.InitializeMageBuffAlerts()
    s.frame = s.frames[1]
    function s:event(event)
        if self.frame and self.frame.events[event] then self.frame.scripts.OnEvent(self.frame, event) end
    end
    function s:tick(seconds)
        seconds = seconds or 1
        self.now = self.now + seconds
        if self.frame then self.frame.scripts.OnUpdate(self.frame, seconds) end
    end
    function s:buff(unit, id, remaining, nameOverride)
        self.auras[unit] = self.auras[unit] or {}
        table.insert(self.auras[unit], { name = nameOverride or labels[id], spellId = id, expirationTime = remaining == 0 and 0 or self.now + remaining })
    end
    function s:healthy()
        self.auras.player = {}
        self:buff("player", 23028, 3600)
        self:buff("player", 6117, 1800)
    end
    return s
end
local function test(name, fn) fn(); total = total + 1; print("ok - " .. name) end

test("character name and MAGE class are both mandatory", function()
    for _, identity in ipairs({ { "Minibobsel", "PRIEST" }, { "OtherMage", "MAGE" } }) do
        local s = setup(identity[1], identity[2]); s:tick(20)
        eq(#s.frames, 0); eq(#s.played, 0); eq(#s.messages, 0)
    end
end)
test("login and loading grace prevent transient missing warnings", function()
    local s = setup(); s:tick(4); eq(#s.messages, 0)
    s:healthy(); s:tick(); eq(#s.messages, 0)
    s:event("PLAYER_LEAVING_WORLD"); s.auras = {}; s:tick(30); eq(#s.messages, 0)
    s:event("PLAYER_ENTERING_WORLD"); s:tick(4); eq(#s.messages, 0)
    s:healthy(); s:tick(); eq(#s.messages, 0)
end)
test("120-second and missing warnings play distinct recordings only on transitions", function()
    local s = setup(); s:healthy(); s:tick(5)
    s.auras.player[1].expirationTime = s.now + 121
    s:tick(); eq(#s.messages, 1); eq(#s.played, 1)
    assert(s.played[1].path:find("intellect_expiring.ogg", 1, true))
    s:tick(); eq(#s.messages, 1)
    s:tick(119); eq(#s.messages, 2); eq(#s.played, 2)
    assert(s.played[2].path:find("intellect_missing.ogg", 1, true))
    s:tick(); eq(#s.messages, 2)
    s:healthy(); s:tick(); eq(s.banner.shown, false)
    s.auras.player[1].expirationTime = s.now + 120; s:tick()
    eq(#s.messages, 3); eq(#s.played, 3)
end)
test("both intellect buffs and every armor family count across ranks and sources", function()
    for _, id in ipairs({ 168, 7302, 6117, 10220, 22783 }) do
        local s = setup(); s:buff("player", 10157, 1800, "Foreign highest-rank Int")
        s:buff("player", id, 1800, "Localized Armor"); s:tick(5)
        eq(#s.messages, 0)
    end
end)
test("group excludes warriors rogues self duplicates offline dead and distant units", function()
    local s = setup(); s:healthy(); s.raid = true; s.group = 6
    s.units.raid1 = { name = "Minibobsel", class = "MAGE", guid = "self" }
    s.units.raid2 = { name = "Warrior", class = "WARRIOR", guid = "w" }
    s.units.raid3 = { name = "Rogue", class = "ROGUE", guid = "r" }
    s.units.raid4 = { name = "Priest", class = "PRIEST", guid = "p", offline = true }
    s.units.raid5 = { name = "Druid", class = "DRUID", guid = "d", invisible = true }
    s.units.raid6 = { name = "Mage", class = "MAGE", guid = "m", dead = true }
    s:tick(5); eq(#s.messages, 0)
    s.units.raid4.offline = false; s.units.raid5.invisible = false; s:tick()
    eq(#s.messages, 2); eq(#s.played, 1, "One sound for two missing party Int buffs")
    assert(not s.bannerText:find("Rüstungsbuff", 1, true))
    s:tick(5); eq(#s.messages, 2); eq(#s.played, 1)
    s.units.raid4.invisible = true; s:tick(); s.units.raid4.invisible = false; s:tick()
    eq(#s.messages, 2, "Visibility changes must not rearm missing warnings")
end)
test("queued sounds serialize and are discarded when a buff is restored", function()
    local s = setup(); s:tick(5)
    eq(#s.messages, 2); eq(#s.played, 1)
    assert(s.played[1].path:find("intellect_missing", 1, true))
    s:buff("player", 6117, 1800); s:tick()
    eq(#s.played, 1, "Do not play stale armor warning")
    assert(not s.bannerText:find("Rüstungsbuff", 1, true))
end)
test("unknown spells, absent aura APIs, death and taxi do not invent warnings", function()
    local s = setup(); s.known = {}; s:event("SPELLS_CHANGED"); s:tick(5); eq(#s.messages, 0)
    s.known[1459] = true; s:event("SPELLS_CHANGED")
    C_UnitAuras, UnitBuff = nil, nil; s:tick(); eq(#s.messages, 0)
    local s2 = setup(); s2.units.player.dead = true; s2:tick(5); eq(#s2.messages, 0)
    s2.units.player.dead = false; s2.taxi = true; s2:tick(); eq(#s2.messages, 0)
    s2.taxi = false; s2:tick(); eq(#s2.messages, 2)
end)
test("legacy aura names work and permanent buffs stay healthy", function()
    local s = setup(); C_UnitAuras = nil
    s:buff("player", 1459, 0); s:buff("player", 6117, 0)
    for _, aura in ipairs(s.auras.player) do aura.spellId = nil end
    s:tick(5); eq(#s.messages, 0)
end)
test("disable clears banners and queued audio; sound switch leaves visual warnings", function()
    local s = setup(); s:tick(5); assert(s.banner.shown)
    s.addon.db.enabled = false; s.addon.MageBuffOptionsChanged("enabled")
    eq(s.banner.shown, false); eq(#s.stopped, 1)
    s:tick(3); eq(#s.played, 1)
    s.addon.db.enabled = true; s.addon.db.mageBuffSound = false
    s.addon.MageBuffOptionsChanged("enabled"); s:tick()
    eq(#s.messages, 4); eq(#s.played, 1)
end)
test("missing recordings stay visual and playback failure leaves originals untouched", function()
    local s = setup(); s.addon.buffAlertSounds = { intellect = {}, armor = {} }
    s:tick(5); eq(#s.messages, 2); eq(#s.played, 0)
    eq(s.addon.PreviewMageBuff("intellect", "missing"), false)
    local s2 = setup(); s2.failSound = true; s2:tick(5)
    eq(#s2.played, 2); assert(s2.banner.shown)
    s2:tick(10); eq(#s2.played, 2, "No retry spam")
end)
test("Noggenfogger routes warning audio and previews work on other characters", function()
    local s = setup("SomeoneElse", "PRIEST"); s.pitch = true
    eq(s.addon.PreviewMageBuff("armor", "expiring"), true)
    assert(s.played[1].path:find("\\noggenfogger\\armor_expiring.ogg", 1, true))
    eq(s.addon.PreviewMageBuff("armor", "missing"), true); eq(#s.stopped, 1)
    eq(s.addon.PreviewMageBuff("invalid", "missing"), false)
end)
print("GabbaSounds mage buff alerts: " .. total .. " tests passed")
