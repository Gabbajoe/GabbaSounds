#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
LUA="${LUA:-lua}"
LUAC="${LUAC:-luac}"
"$LUAC" -p MageSpells.lua
"$LUAC" -p MageEvents.lua
"$LUAC" -p Core.lua
"$LUAC" -p UI.lua
"$LUAC" -p SoundData.lua
"$LUAC" -p CustomSoundData.lua
"$LUAC" -p Schools.lua
"$LUAC" -p Melee.lua
"$LUAC" -p MeleeSoundIDs.lua
"$LUAC" -p Weapons.lua
"$LUAC" -p Minimap.lua
"$LUA" tests/test_addon.lua
python3 -m unittest discover -s tests -p 'test_*.py'
