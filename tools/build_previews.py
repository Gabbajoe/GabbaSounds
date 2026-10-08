#!/usr/bin/env python3
"""Regenerate browser listening pages from checked-in OGGs, without source WAVs."""
import json

from import_spoken_library import ROOT, write_previews
from generate_sounds import make_player


def main():
    sounds = json.loads((ROOT / 'spoken/manifest.json').read_text())['sounds']
    write_previews(sounds)
    magic = ROOT / 'previews/magic/index.html'
    magic.parent.mkdir(parents=True, exist_ok=True)
    magic.write_text(make_player(json.loads((ROOT / 'manifest.json').read_text()), linked=True), encoding='utf-8')
    print('Built spoken, melee and magic listening pages under previews/.')


if __name__ == '__main__':
    main()
