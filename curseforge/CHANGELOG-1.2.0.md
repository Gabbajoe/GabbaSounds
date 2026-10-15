# GabbaSounds 1.2.0

- Added automatic +4-semitone playback for your own attacks and spell casts while the Noggenfogger Elixir shrink effect is active. Other players retain their normal sound variants.
- Included 345 pitched variants covering all existing spoken and synthetic packs, with unchanged playback duration and original recordings preserved.
- Added a character-specific Noggenfogger option (enabled by default) and `/gws noggenfogger on|off`.
- Detect the shrink aura on login, reload, zone changes and buff changes. Skeleton and slow-fall effects do not trigger the feature.
- Fall back to normal recordings if a pitched file cannot be loaded.

Fully exit and restart WoW after updating so the client can load the new audio files.

Target client: WoW Classic Era / Hardcore 1.15.9, Interface 11509.
