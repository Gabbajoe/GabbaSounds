-- Classic Era priest ranks and verified numeric sound IDs; see analysis/priest_spells.json.
local _, addon = ...
addon.priestOrder = { "mindblast", "shadowwordpain", "smite", "holynova" }
addon.priestSpells = {
    mindblast = { label = "Gedankenschlag", school = "shadow", canCrit = true, aoe = false, auraHit = false, ranks = { 8092, 8102, 8103, 8104, 8105, 8106, 10945, 10946, 10947 }, originalIDs = { 569220, 569424, 569766 } },
    shadowwordpain = { label = "Schattenwort: Schmerz", school = "shadow", canCrit = false, aoe = false, auraHit = true, ranks = { 589, 594, 970, 992, 2767, 10892, 10893, 10894 }, originalIDs = { 569138, 569424, 569766 } },
    smite = { label = "Göttliche Pein", school = "holy", canCrit = true, aoe = false, auraHit = false, ranks = { 585, 591, 598, 984, 1004, 6060, 10933, 10934 }, originalIDs = { 568915, 569402, 569763 } },
    holynova = { label = "Heilige Nova", school = "holy", canCrit = true, aoe = true, auraHit = false, ranks = { 15237, 15430, 15431, 27799, 27800, 27801 }, originalIDs = { 568440, 569763, 569771 } },
}
addon.priestSpellByID = {}
for key, spell in pairs(addon.priestSpells) do
    for _, id in ipairs(spell.ranks) do addon.priestSpellByID[id] = key end
end
