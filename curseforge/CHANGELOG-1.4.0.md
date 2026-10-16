# GabbaSounds 1.4.0 (in development)

- Added spoken alerts for **Gromsblood** and **Black Lotus** when a herbalist hovers a real herb tracking point on the minimap or the herb in the world. German and English names are supported.
- Included two original recordings and two matching Noggenfogger variants. Existing attack and mage buff recordings are preserved.
- Reject stored addon pins, bag items, item links, unit and spell tooltips. Identical herb alerts have a 30-second minimum interval and do not repeat while the same tooltip stays open.
- Added `/gws herbs`, a character-specific toggle and previews that also work without Herbalism. Alerts follow the existing sound channel and remain independent of combat sounds.
- Included the herb recordings and both runtime modules in the allowlisted package. The build contains 702 OGGs: 225 spoken recordings, 126 synthetic sounds and 351 pitched variants. Original WAVs remain private.

This is a local test build, not yet published. Real herb tooltips still need in-game validation. It does not automatically scan the minimap or check stored spawn proximity. Warrior ability sounds are still in preparation.

Fully exit and restart WoW after installation to load the new sound files.
