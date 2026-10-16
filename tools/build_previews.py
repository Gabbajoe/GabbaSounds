#!/usr/bin/env python3
"""Regenerate browser listening pages from checked-in OGGs, without source WAVs."""
import json

from import_spoken_library import ROOT, write_previews
from generate_sounds import make_player
from import_buff_alerts import write_preview
from import_herbalism import write_preview as write_herb_preview


def main():
    sounds = json.loads((ROOT / 'spoken/manifest.json').read_text())['sounds']
    write_previews(sounds)
    write_preview(json.loads((ROOT / 'spoken/mage/buffs/manifest.json').read_text())['sounds'])
    write_herb_preview(json.loads((ROOT / 'spoken/herbalism/manifest.json').read_text())['sounds'])
    magic = ROOT / 'previews/magic/index.html'
    magic.parent.mkdir(parents=True, exist_ok=True)
    magic.write_text(make_player(json.loads((ROOT / 'manifest.json').read_text()), linked=True), encoding='utf-8')
    print('Built spoken, melee, magic, buff warning and herbalism listening pages under previews/.')


if __name__ == '__main__':
    main()
