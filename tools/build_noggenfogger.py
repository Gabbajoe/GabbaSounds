#!/usr/bin/env python3
"""Create +4-semitone OGG variants without changing playback duration or originals."""
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import subprocess

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SEMITONES = 4
RATE = 44100


def source_sounds(root=ROOT):
    return json.loads((root / 'manifest.json').read_text()) + json.loads(
        (root / 'spoken/manifest.json').read_text())['sounds']


def render(item):
    source = ROOT / item['file']
    destination = ROOT / 'Sounds/noggenfogger' / source.name
    destination.parent.mkdir(parents=True, exist_ok=True)
    info = json.loads(subprocess.check_output([
        'ffprobe', '-v', 'error', '-show_streams', '-of', 'json', str(source)]))['streams'][0]
    length = round(float(info['duration']) * RATE)
    decode = ['ffmpeg', '-v', 'error', '-i', str(source)]
    raw = subprocess.check_output(decode + ['-f', 'f32le', '-acodec', 'pcm_f32le', '-'])
    original = np.frombuffer(raw, dtype='<f4').reshape(-1, 2)[:length]
    filters = f'rubberband=pitch={2 ** (SEMITONES / 12):.12f}:pitchq=quality:channels=together,apad=whole_len={length},atrim=end_sample={length}'
    raw = subprocess.check_output(decode + ['-af', filters, '-f', 'f32le', '-acodec', 'pcm_f32le', '-'])
    signal = np.frombuffer(raw, dtype='<f4').reshape(-1, 2).copy()
    signal -= signal.mean(axis=0)
    # Keep the perceived gain close to the existing recording, with headroom.
    gain = min(float(np.sqrt(np.mean(original ** 2)) / np.sqrt(np.mean(signal ** 2))),
               0.80 / float(np.max(np.abs(signal))))
    signal *= gain
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(RATE),
                    '-ac', '2', '-i', '-', '-map_metadata', '-1', '-fflags', '+bitexact',
                    '-flags:a', '+bitexact', '-c:a', 'libvorbis', '-q:a', '5', str(destination)],
                   input=signal.astype('<f4').tobytes(), check=True)
    return {**item, 'source_file': item['file'], 'file': destination.relative_to(ROOT).as_posix(),
            'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
            'sha256': hashlib.sha256(destination.read_bytes()).hexdigest(),
            'duration': length / RATE}


def main():
    with ThreadPoolExecutor(max_workers=4) as workers:
        sounds = list(workers.map(render, source_sounds()))
    destination = ROOT / 'noggenfogger/manifest.json'
    destination.parent.mkdir(exist_ok=True)
    destination.write_text(json.dumps({'semitones': SEMITONES, 'sounds': sounds},
                                    indent=2, ensure_ascii=False) + '\n')
    print(f'Built {len(sounds)} Noggenfogger variants at +{SEMITONES} semitones; originals unchanged.')


if __name__ == '__main__':
    main()
