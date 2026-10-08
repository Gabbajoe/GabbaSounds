# GabbaSounds

Give your wand, ranged weapon, melee attacks and mage spells a voice. GabbaSounds plays randomized German voice clips such as “pew pew”, whooshes, critical-hit reactions and missed-shot comments in **World of Warcraft Classic Era and Hardcore**.

It started with a wand priest and one very repetitive whoosh. It now includes separate spoken packs for wands, bows/crossbows and guns, four melee weapon groups, plus recordings for **15 frost and fire mage spells**.

**The spoken clips and current options interface are German.** The addon also includes a synthetic magic sound pack for wands, with variations for each damage school.

## Features

- **219 spoken clips** from original microphone recordings, plus **126 synthetic wand sounds**.
- Separate sound pools for normal hits and critical hits, with shared comments for misses, resisted or fully absorbed attacks, and partial hits.
- Mage sounds at cast start, channel start or successful activation, as appropriate for the spell, in addition to impact sounds for damaging spells.
- Melee auto attacks with separate main-hand/off-hand detection; six normal hits and four critical-hit reactions per weapon group.
- Shared glancing-hit reactions and protection against fast normal hits cutting off longer melee comments.
- Adjustable minimum interval for normal melee reactions.
- Random selection that avoids immediate repeats where alternatives exist.
- Automatic selection by weapon or supported mage spell, plus individual packs and a mage-only pack.
- One result reaction per supported area-effect application. Blizzard reacts to its first damage burst rather than every target and tick.
- Independent controls for casts and attack results, in-game sound previews, and settings saved per character.
- Optional muting of covered original sounds, including a “spoken sounds only” shortcut.
- Minimap button: **left-click to enable/disable**, **right-click for options**, drag to reposition.
- No required addon dependencies.

## Supported mage spells

**Frost:** Frostbolt, Frost Nova, Blizzard, Cone of Cold, Ice Barrier, Ice Block, Cold Snap and Frost Ward.

**Fire:** Fireball, Fire Blast, Scorch, Pyroblast, Flamestrike, Blast Wave and Combustion.

All 83 Classic ranks of these spells are recognized. Defensive abilities and cooldowns use activation clips only. Blizzard has normal-hit recordings but no critical-hit pool. Other damaging spells use separate hit and critical-hit recordings. Damage-over-time ticks from Fireball, Pyroblast and Flamestrike do not trigger repeated voice reactions.

Wand attacks, hunter auto shots and ordinary melee auto attacks are supported. Melee groups are swords/axes, maces/staves, daggers, and fist/unarmed. Hunter special attacks, class-specific melee abilities, polearms and druid-form packs do not have replacement clips. Visible foreign druids are excluded; unknown foreign weapons use a neutral reserve only when complete melee muting is active. Spoken spell reactions are for players, not NPCs or pets. You can choose whether to hear reactions for your character only or also for other players whose events appear in your combat log.

## Getting started

Install through CurseForge, or extract the ZIP into:

`World of Warcraft/_classic_era_/Interface/AddOns/`

The resulting path must include `GabbaSounds/GabbaSounds.toc`. **Fully exit and restart WoW after installing or updating**, so the client can load the new audio files.

Open the options with `/gws` or the minimap button. New characters start with the synthetic wand pack. To enable all spoken packs and mute their covered original sounds:

```text
/gws on
/gws spokenonly on
```

Useful commands:

```text
/gws pack mage
/gws pack spoken
/gws pack wand
/gws pack bow
/gws pack gun
/gws pack melee
/gws meleeinterval 0.5
/gws cast on
/gws test cast fireball
/gws test crit frostbolt
/gws mute off
/gws status
```

`/gws pack mage` selects only the supported mage spells. `/gws pack spoken` selects the automatic weapon-and-mage voice pack. You can also select an individual mage spell, such as `/gws pack frostbolt` or `/gws pack pyroblast`.

## Original-sound muting

Original sound files can be muted when the selected pack and enabled categories fully cover their replacements. The automatic spoken pack covers 357 original sound files across the supported weapons and mage spells. Melee muting requires the automatic overall or melee pack, all four complete weapon groups and enabled glancing-hit reactions; individual melee packs retain original sounds.

**WoW mutes a sound file globally.** Shared files used by other abilities, other players, NPCs or hunter special attacks can therefore also become silent, even if those events do not have replacement clips. Turn off original-sound muting if you prefer to keep those sounds. Disabling the addon releases its own mutes.

Custom clips are played locally on your client and do not broadcast your recordings to other players. They do not have the positional audio or distance-based volume of native world sounds.

## Source and feedback

Source code and development tools are available on [GitHub](https://github.com/Gabbajoe/GabbaSounds). Report bugs and feature requests through [GitHub Issues](https://github.com/Gabbajoe/GabbaSounds/issues).

## Compatibility

This release targets **WoW Classic Era / Hardcore 1.15.9**, Interface **11509**. Retail and other Classic client versions are not supported by this release.

## Credits

- **Tsukimo:** melee sound packs, by special request.
- **Palaberd:** hunter sound packs, by special request.
- **Bobselinchen, aka Minibobsel:** Frostbolt sounds, by special request.
- **Zeldazar:** fire spell sounds, by special request.
- **Gabbajoe:** addon and original voice recordings; inspired by a wand priest's endlessly repeating default whoosh.

Sound identifiers were checked using Resonance and Leatrix Sounds catalogs; Classic mage rank identifiers were cross-checked with WoWSims Classic and spell database entries. No Blizzard audio or those projects' runtime code is bundled. Reference details are included in `THIRD_PARTY_NOTICES.md`.
