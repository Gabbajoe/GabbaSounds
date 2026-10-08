#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
luac -p MageSpells.lua
luac -p MageEvents.lua
luac -p Core.lua
luac -p UI.lua
luac -p SoundData.lua
luac -p CustomSoundData.lua
luac -p Schools.lua
luac -p Weapons.lua
luac -p Minimap.lua
lua tests/test_addon.lua
python3 -m unittest discover -s tests -p 'test_*.py'
