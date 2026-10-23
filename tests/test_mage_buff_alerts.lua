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
    C_Spell = nil
    function IsSpellInRange(_, unit)
        local u = s.units[unit]
        if u.rangeUnknown then return nil end
        return u.outOfRange and 0 or 1
    end
    function UnitInRange(unit)
        local u = s.units[unit]
        return u.fallbackRange, u.fallbackChecked
    end
    local labels = { [1459] = "Int", [23028] = "Brilliance", [168] = "Frost Armor", [7302] = "Ice Armor", [6117] = "Mage Armor",
        [1243] = "Fortitude", [21562] = "Prayer of Fortitude", [588] = "Inner Fire",
        [14752] = "Spirit", [27681] = "Prayer of Spirit", [6346] = "Fear Ward" }
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
    local addon = { db = { enabled = true, mageBuffAlerts = true, mageBuffIntellect = true, mageBuffArmor = true, mageBuffSound = true,
        priestBuffAlerts = true, priestBuffFortitude = true, priestBuffSpirit = true,
        priestBuffInnerFire = true, priestBuffFearWard = false, priestBuffSound = true, channel = "SFX" }, soundDurations = {} }
    addon.Print = function(msg) assert(msg ~= "", "No empty chat spam"); s.messages[#s.messages + 1] = msg end
    addon.NoggenfoggerSound = function(file) return s.pitch and "noggenfogger\\" .. file or file end
    assert(loadfile("BuffAlertSoundData.lua"))("GabbaSounds", addon)
    assert(loadfile("MageBuffAlerts.lua"))("GabbaSounds", addon)
    for _, key in ipairs({ "intellect", "armor", "fortitude", "spirit", "innerFire", "fearWard" }) do
        for _, phase in ipairs({ "expiring", "missing" }) do
            local file = key .. "_" .. phase .. ".ogg"
            addon.buffAlertSounds[key] = addon.buffAlertSounds[key] or {}
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
    for _, identity in ipairs({ { "Bobselinchen", "MAGE" }, { "OtherMage", "MAGE" } }) do
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
test("new visible members need known mana class and confirmed buff range", function()
    local s = setup(); s:healthy(); s.group = 1
    s.units.party1 = { name = "Joining", guid = "join", outOfRange = true }
    s:tick(5); eq(#s.messages, 0)
    s.units.party1.outOfRange = false; s:tick(); eq(#s.messages, 0, "Unknown class is not a mana class")
    s.units.party1.class = "WARRIOR"; s:tick(); eq(#s.messages, 0)
    s.units.party1.class = "MAGE"; s.units.party1.outOfRange = true; s:tick(); eq(#s.messages, 0)
    s.units.party1.outOfRange = false; s:tick(); eq(#s.messages, 1)
    s.units.party1.outOfRange = true; s:tick(); eq(s.banner.shown, false)
    s.units.party1.outOfRange = false; s:tick(); eq(#s.messages, 1, "Range changes do not repeat the same warning")
end)
test("invalid range is skipped; fallback must be checked and positive", function()
    local s = setup(); s:healthy(); s.group = 1
    s.units.party1 = { name = "Druid", class = "DRUID", guid = "d", rangeUnknown = true, fallbackRange = true }
    s:tick(5); eq(#s.messages, 0)
    s.units.party1.fallbackChecked = true; s.units.party1.fallbackRange = false
    s:tick(); eq(#s.messages, 0)
    s.units.party1.fallbackRange = true; s:tick(); eq(#s.messages, 1)
end)
test("modern boolean spell range rejects false and accepts true", function()
    local s = setup(); s:healthy(); s.group = 1
    s.units.party1 = { name = "Hunter", class = "HUNTER", guid = "h", outOfRange = true, fallbackRange = true, fallbackChecked = true }
    IsSpellInRange = nil
    C_Spell = { IsSpellInRange = function(_, unit) return not s.units[unit].outOfRange end }
    s:tick(5); eq(#s.messages, 0, "Generic range cannot override actual spell being out of range")
    s.units.party1.outOfRange = false; s:tick(); eq(#s.messages, 1)
end)
test("queued group voice is rechecked before playback even between scans", function()
    local s = setup(); s.group = 1
    s:buff("player", 1459, 120)
    s.units.party1 = { name = "Priest", class = "PRIEST", guid = "p" }
    s:tick(5); eq(#s.played, 1) -- Own missing armor first; party Int is queued.
    s.units.party1.outOfRange = true
    s.now = s.now + 2; s.frame.scripts.OnUpdate(s.frame, 0.1)
    eq(#s.played, 2); assert(s.played[2].path:find("intellect_expiring", 1, true), "Skip stale party missing Int")
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
local function priest(name)
    local s = setup(name or "Bobselinchen", "PRIEST")
    s.known = { [1243] = true, [14752] = true, [588] = true, [6346] = true }
    s:event("SPELLS_CHANGED")
    function s:priestHealthy(unit)
        unit = unit or "player"
        self.auras[unit] = {}
        self:buff(unit, 21562, 1800); self:buff(unit, 27681, 1800)
        if unit == "player" then self:buff(unit, 588, 600) end
    end
    return s
end

test("Bobselinchen priest profile is personal and owns legacy reminders", function()
    local s = priest(); assert(GabbaSoundsOwnsPriestBuffAlerts())
    s:tick(5); eq(#s.messages, 3)
    assert(not s.bannerText:find("Furcht", 1, true), "Fear Ward is optional, off by default")
    s.addon.db.priestBuffAlerts = false; s.addon.MageBuffOptionsChanged("priestBuffAlerts")
    s:tick(); eq(#s.messages, 3); eq(s.banner.shown, false)
    assert(GabbaSoundsOwnsPriestBuffAlerts(), "Disabling personal alerts must not reactivate the legacy copy")
    for _, identity in ipairs({ { "Bobselinchen", "WARRIOR" }, { "Bobselinchen", "MAGE" } }) do
        local other = setup(identity[1], identity[2]); other:tick(10)
        eq(#other.frames, 0); eq(GabbaSoundsOwnsPriestBuffAlerts(), false)
    end
end)
test("priest group rules keep Fortitude for all, Spirit for mana, Inner Fire for self", function()
    local s = priest(); s:priestHealthy(); s.group = 2
    s.units.party1 = { name = "Warrior", class = "WARRIOR", guid = "w" }
    s.units.party2 = { name = "Rogue", class = "ROGUE", guid = "r" }
    s:tick(5); eq(#s.messages, 2)
    for _, msg in ipairs(s.messages) do assert(msg:find("Ausdauer", 1, true)) end
    s:priestHealthy("party1"); s:priestHealthy("party2"); s:tick()
    s.units.party1.class = "DRUID"; s.auras.party1 = {}; s:tick()
    eq(#s.messages, 4); assert(s.bannerText:find("Willenskraft", 1, true))
    assert(not s.bannerText:find("Inneres Feuer", 1, true))
end)
test("priest joins outside range or with unknown class stay quiet until confirmed", function()
    local s = priest(); s:priestHealthy(); s.group = 1
    s.units.party1 = { name = "Joining", guid = "j", class = "MAGE", outOfRange = true }
    s:tick(5); eq(#s.messages, 0)
    s.units.party1.outOfRange = false; s.units.party1.class = nil
    s:tick(); eq(#s.messages, 0)
    s.units.party1.class = "PRIEST"; s:tick(); eq(#s.messages, 2)
end)
test("priest warnings distinguish two-minute expiry from missing for every learned buff", function()
    local s = priest(); s.addon.db.priestBuffFearWard = true
    s:priestHealthy(); s:buff("player", 6346, 1800)
    s:tick(5); eq(#s.messages, 0)
    for _, aura in ipairs(s.auras.player) do aura.expirationTime = s.now + 120 end
    s:tick(); eq(#s.messages, 4)
    for _, msg in ipairs(s.messages) do assert(msg:find("2 Min.", 1, true)) end
    s:tick(120); eq(#s.messages, 8)
    for index = 5, 8 do assert(s.messages[index]:find("fehlt", 1, true)) end
    s:tick(); eq(#s.messages, 8)
end)
test("Fear Ward requires both opt-in and a learned dwarf spell", function()
    local s = priest(); s:priestHealthy(); s.addon.db.priestBuffFearWard = true
    s.known[6346] = nil; s:event("SPELLS_CHANGED"); s:tick(5); eq(#s.messages, 0)
    s.known[6346] = true; s:event("SPELLS_CHANGED"); s:tick(); eq(#s.messages, 1)
    assert(s.bannerText:find("Furchtzauberschutz", 1, true))
    s.addon.db.priestBuffFearWard = false; s.addon.MageBuffOptionsChanged("priestBuffFearWard")
    eq(s.banner.shown, false)
end)
test("other priests automatically use neutral recordings without personal names", function()
    local s = priest("AnotherPriest")
    s.addon.priestBuffGenericSounds = { fortitude = { missing = "generic_fortitude_missing.ogg" } }
    s:tick(5); eq(#s.messages, 3); eq(#s.played, 1)
    assert(s.played[1].path:find("generic_fortitude_missing.ogg", 1, true))
    assert(GabbaSoundsOwnsPriestBuffAlerts(), "Other priests must not get duplicate legacy alarms")
    s.addon.PreviewMageBuff("fortitude", "missing")
    assert(s.played[2].path:find("generic_fortitude_missing.ogg", 1, true))
end)
test("generic priest never falls back to Bobselinchen recordings", function()
    local s = priest("AnotherPriest")
    s.addon.priestBuffGenericSounds = {}
    s:tick(5); eq(#s.messages, 3); eq(#s.played, 0)
    eq(s.addon.PreviewMageBuff("fortitude", "missing"), false)
end)
test("Bobselinchen prefers personal clips and may safely fall back to neutral ones", function()
    local s = priest()
    s.addon.priestBuffGenericSounds = { fortitude = { missing = "generic_fortitude_missing.ogg", expiring = "generic_fortitude_expiring.ogg" } }
    s.addon.PreviewMageBuff("fortitude", "missing")
    assert(s.played[1].path:find("\\fortitude_missing.ogg", 1, true))
    s.addon.buffAlertSounds.fortitude.expiring = nil
    s.addon.PreviewMageBuff("fortitude", "expiring")
    assert(s.played[2].path:find("generic_fortitude_expiring.ogg", 1, true))
end)
test("other priest profile keeps class and range filters and optional Fear Ward", function()
    local s = priest("AnotherPriest"); s:priestHealthy(); s.group = 2
    s.units.party1 = { name = "Distant", class = "PRIEST", guid = "far", outOfRange = true }
    s.units.party2 = { name = "Warrior", class = "WARRIOR", guid = "war" }
    s:buff("party2", 1243, 1800)
    s:tick(5); eq(#s.messages, 0)
    s.auras.party2 = {}; s:tick(); eq(#s.messages, 1)
    assert(s.messages[1]:find("Ausdauer", 1, true))
end)
test("unrecorded priest alerts remain text only", function()
    local s = priest(); s.addon.priestBuffGenericSounds = {}
    for _, key in ipairs({ "fortitude", "spirit", "innerFire", "fearWard" }) do s.addon.buffAlertSounds[key] = nil end
    s:tick(5); eq(#s.messages, 3); eq(#s.played, 0)
end)
test("priest identity alone chooses the same voice in previews and automatic warnings", function()
    for _, identity in ipairs({"Bobselinchen", "AnotherPriest"}) do
        local s = priest(identity)
        local bank = identity == "Bobselinchen" and s.addon.buffAlertSounds or s.addon.priestBuffGenericSounds
        assert(s.addon.PreviewMageBuff("fortitude", "missing"))
        assert(s.played[1].path:find(bank.fortitude.missing, 1, true))
        s:tick(5)
        assert(s.played[2].path:find(bank.fortitude.missing, 1, true))
        eq(s.addon.GetBuffAlertTitle(), "Priester-Buffwarnungen")
    end
end)
print("GabbaSounds mage buff alerts: " .. total .. " tests passed")
