# Sound mapping source

The nine Classic Frostbolt FileDataIDs and their use by all eleven ranks
were checked against the generated spell-to-sound mapping distributed in
[Resonance v1.13.1 by Skkold](https://www.curseforge.com/wow/addons/resonance/files/8899894).
That release publishes its license as MIT.

Only the numeric sound identifiers are used here. No Resonance runtime
code, complete databases or audio files are included. The local research
record, including source file names and archive checksum, is available in
`analysis/frostbolt_original_sounds.json` in the development workspace.

The fourteen Classic bow/crossbow and seven gun FileDataIDs were selected
by their native weapon paths in the installed Leatrix Sounds 1.15.157
Classic Era effects catalog. The three bow releases and three gun fire IDs
were also checked against Resonance's Classic weapon mapping. Only numeric
identifiers are included in runtime code; no Leatrix code, full catalogs
or Blizzard audio files are redistributed. Research details are recorded
in `analysis/hunter_original_sounds.json` in the development workspace.

The 27 sound FileDataIDs used by the fifteen supported Classic mage spells
were checked against the same Resonance Vanilla mapping. Spell rank numbers
were cross-checked with the WoWSims Classic mage definitions and Classic
spell database entries. Only identifiers and handwritten routing metadata
are included, not simulator implementation code or complete source datasets.
Provenance and checksums are recorded in `analysis/mage_spells.json`.

Rank reference: https://github.com/wowsims/classic/tree/master/sim/mage
Additional rank references: https://classicdb.ch/?spell=10230,
https://classicdb.ch/?spell=10161, https://classicdb.ch/?spell=28609,
https://classicdb.ch/?spell=10187.
