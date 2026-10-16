#!/usr/bin/env python3
"""Shared voice encoding and herb previews; preserves the original source WAVs."""
import hashlib
import html
import json
from pathlib import Path
import subprocess

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
HERBS = {'gromsblood': 'Gromsblut', 'blacklotus': 'Schwarzer Lotus'}
RATE = 44100


def encode(source, destination):
    raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(source),
                                   '-ar', str(RATE), '-ac', '2', '-f', 'f32le', '-'])
    signal = np.frombuffer(raw, dtype='<f4').reshape(-1, 2).astype(float)
    if not len(signal) or not np.isfinite(signal).all():
        raise ValueError('Empty or invalid recording: ' + str(source))
    signal -= signal.mean(axis=0)
    # Keep the complete phrase, trimming silence only at the outer edges.
    block = 441
    energy = np.array([np.sqrt(np.mean(part ** 2)) for part in
                       np.array_split(signal, max(1, (len(signal) + block - 1) // block))])
    active = np.flatnonzero(energy > 10 ** (-40 / 20))
    if not len(active):
        raise ValueError('No audible phrase: ' + str(source))
    step = len(signal) / len(energy)
    start = max(0, int(active[0] * step) - round(.04 * RATE))
    end = min(len(signal), int((active[-1] + 1) * step) + round(.08 * RATE))
    signal = signal[start:end].copy()
    if not .15 <= len(signal) / RATE <= 8:
        raise ValueError('Record one short phrase (0.15–8 seconds): ' + str(source))
    gain = min(.07 / float(np.sqrt(np.mean(signal ** 2))), .72 / float(np.max(np.abs(signal))), 4)
    signal *= gain
    fade = min(round(.006 * RATE), len(signal) // 4)
    signal[:fade] *= np.linspace(0, 1, fade)[:, None]
    signal[-fade:] *= np.linspace(1, 0, fade)[:, None]
    destination.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(RATE),
                    '-ac', '2', '-i', '-', '-map_metadata', '-1', '-fflags', '+bitexact',
                    '-flags:a', '+bitexact', '-c:a', 'libvorbis', '-q:a', '5', str(destination)],
                   input=signal.astype('<f4').tobytes(), check=True)
    return start / RATE, end / RATE, len(signal) / RATE


def build_previews(root=ROOT):
    manifest = root / 'spoken/herbalism/manifest.json'
    if manifest.is_file():
        write_preview(json.loads(manifest.read_text())['sounds'], root)
        return root / 'previews/herbalism/index.html'
    sources = {key: root / 'spoken/herbalism' / (key + '.wav') for key in HERBS}
    missing = [str(path.relative_to(root)) for path in sources.values() if not path.is_file()]
    if missing:
        raise ValueError('Missing recordings: ' + ', '.join(missing))
    output = root / 'previews/herbalism'
    sounds = []
    for key, source in sources.items():
        digest = hashlib.sha256(source.read_bytes()).hexdigest()
        destination = output / (key + '.ogg')
        start, end, duration = encode(source, destination)
        item = {'file': destination.name, 'name': HERBS[key],
                'herb': key, 'duration': duration,
                'source': source.relative_to(root).as_posix(), 'source_start': start,
                'source_end': end, 'sample_rate': RATE, 'channels': 2}
        assert hashlib.sha256(source.read_bytes()).hexdigest() == digest, 'Source WAV changed'
        sounds.append({**item, 'source_sha256': digest})
    (output / 'manifest.json').write_text(json.dumps(sounds, ensure_ascii=False, indent=2) + '\n')
    cards = ''.join('<article><h2>' + html.escape(item['name']) + '</h2><audio controls preload="none" src="'
                    + item['file'] + '"></audio><p>' + f'{item["duration"]:.2f} s'
                    + '</p></article>' for item in sounds)
    (output / 'index.html').write_text('''<!doctype html><html lang="de"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>GabbaSounds – Kräuter</title>
<style>body{font-family:system-ui;background:#111321;color:#eeeaf8;max-width:800px;margin:auto;padding:25px}article{background:#1e2137;padding:18px;margin:18px 0;border-radius:12px}audio{width:100%}p{line-height:1.5;color:#bcb4d5}</style>
<h1>🌿 GabbaSounds – Kräuter-Aufnahmen</h1><p>Lokale Hörproben. Der automatische Alarm ist noch nicht eingebaut:
Classic Era bietet die benötigten Minimap-Scan-Funktionen nicht an. Deine WAV-Originale bleiben erhalten.</p>
''' + cards + '</html>', encoding='utf-8')
    return output / 'index.html'


def write_preview(sounds, root=ROOT):
    target = root / 'previews/herbalism/index.html'
    target.parent.mkdir(parents=True, exist_ok=True)
    cards = ''.join('<article><h2>' + html.escape(item['name'])
                    + '</h2><audio controls preload="none" src="../../' + item['file']
                    + '"></audio></article>' for item in sounds)
    target.write_text('''<!doctype html><html lang="de"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>GabbaSounds – Kräuter-Alarm</title>
<style>body{font-family:system-ui;background:#111321;color:#eeeaf8;max-width:800px;margin:auto;padding:25px}article{background:#1e2137;padding:18px;margin:18px 0;border-radius:12px}audio{width:100%}p{line-height:1.5;color:#bcb4d5}</style>
<h1>🌿 Gromsblut und Schwarzer Lotus</h1><p>Aufnahmen für den Kräuter-Alarm beim Darüberfahren über echte Kräuterpunkte oder das Kraut in der Spielwelt. Kein automatischer Minimap-Suchlauf.</p>
''' + cards + '</html>', encoding='utf-8')


def main():
    try:
        print(build_previews())
    except ValueError as error:
        raise SystemExit(str(error)) from error


if __name__ == '__main__':
    main()
