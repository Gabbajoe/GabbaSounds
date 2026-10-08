-- Classic Era player spell ranks; sound IDs checked against Resonance v1.13.1.
-- See analysis/mage_spells.json for provenance. No native audio is bundled.
local _, addon = ...
addon.mageOrder = { "frostbolt", "frostnova", "blizzard", "coneofcold", "icebarrier", "iceblock", "coldsnap", "frostward", "fireball", "fireblast", "scorch", "pyroblast", "flamestrike", "blastwave", "combustion" }
addon.mageSpells = {
    frostbolt = { label = "Frostblitz", school = "frost", castMode = "start", damage = true, aoe = false, canCrit = true, ranks = { 116, 205, 837, 7322, 8406, 8407, 8408, 10179, 10180, 10181, 25304 }, originalIDs = { 568119, 568128, 568493, 568542, 568843, 569145, 569304, 569765, 569781 } },
    frostnova = { label = "Frostnova", school = "frost", castMode = "success", damage = true, aoe = true, canCrit = true, ranks = { 122, 865, 6131, 10230 }, originalIDs = { 568119, 568741, 569378 } },
    blizzard = { label = "Blizzard", school = "frost", castMode = "channel", damage = true, aoe = true, canCrit = false, ranks = { 10, 6141, 8427, 10185, 10186, 10187 }, originalIDs = { 568119, 568128, 568493, 568542, 568805, 568843, 569145, 569304, 569765 } },
    coneofcold = { label = "Kältekegel", school = "frost", castMode = "success", damage = true, aoe = true, canCrit = true, ranks = { 120, 8492, 10159, 10160, 10161 }, originalIDs = { 568119, 568128, 568493, 568542, 568843, 568982, 569145, 569304 } },
    icebarrier = { label = "Eisbarriere", school = "frost", castMode = "success", damage = false, aoe = false, canCrit = false, ranks = { 11426, 13031, 13032, 13033 }, originalIDs = { 569018, 569765 } },
    iceblock = { label = "Eisblock", school = "frost", castMode = "success", damage = false, aoe = false, canCrit = false, ranks = { 11958 }, originalIDs = { 568119, 568316, 569765 } },
    coldsnap = { label = "Kälteeinbruch", school = "frost", castMode = "success", damage = false, aoe = false, canCrit = false, ranks = { 12472 }, originalIDs = { 568083, 569765 } },
    frostward = { label = "Frostzauberschutz", school = "frost", castMode = "success", damage = false, aoe = false, canCrit = false, ranks = { 6143, 8461, 8462, 10177, 28609 }, originalIDs = { 568083, 568119, 569765 } },
    fireball = { label = "Feuerball", school = "fire", castMode = "start", damage = true, aoe = false, canCrit = true, ranks = { 133, 143, 145, 3140, 8400, 8401, 8402, 10148, 10149, 10150, 10151, 25306 }, originalIDs = { 568429, 568461, 569045, 569449, 569559, 569764, 569777 } },
    fireblast = { label = "Feuerschlag", school = "fire", castMode = "success", damage = true, aoe = false, canCrit = true, ranks = { 2136, 2137, 2138, 8412, 8413, 10197, 10199 }, originalIDs = { 568429, 568461, 569449, 569559, 569764 } },
    scorch = { label = "Versengen", school = "fire", castMode = "start", damage = true, aoe = false, canCrit = true, ranks = { 2948, 8444, 8445, 8446, 10205, 10206, 10207 }, originalIDs = { 568429, 568461, 569045, 569449, 569559, 569764 } },
    pyroblast = { label = "Pyroschlag", school = "fire", castMode = "start", damage = true, aoe = false, canCrit = true, ranks = { 11366, 12505, 12522, 12523, 12524, 12525, 12526, 18809 }, originalIDs = { 568429, 568461, 569045, 569449, 569559, 569764, 569777 } },
    flamestrike = { label = "Flammenstoß", school = "fire", castMode = "start", damage = true, aoe = true, canCrit = true, ranks = { 2120, 2121, 8422, 8423, 10215, 10216 }, originalIDs = { 568641, 569045, 569366, 569764 } },
    blastwave = { label = "Druckwelle", school = "fire", castMode = "success", damage = true, aoe = true, canCrit = true, ranks = { 11113, 13018, 13019, 13020, 13021 }, originalIDs = { 569045, 569062 } },
    combustion = { label = "Verbrennung", school = "fire", castMode = "success", damage = false, aoe = false, canCrit = false, ranks = { 11129 }, originalIDs = { 569045, 569262, 569764 } },
}
addon.mageSpellByID = {}
for key, spell in pairs(addon.mageSpells) do
    for _, id in ipairs(spell.ranks) do addon.mageSpellByID[id] = key end
end
