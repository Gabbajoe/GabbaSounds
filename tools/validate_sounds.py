#!/usr/bin/env python3
"""Validate the actual encoded OGGs and summarize their decoded signal."""
from collections import Counter
from import_spoken_library import MAGE_SPELLS, CAST_ONLY
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

import numpy as np

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--pack', choices=('magic', 'spoken', 'all'), default='all')
    parser.add_argument('--runtime-only', action='store_true',
                        help='Validate shipped OGGs and manifest data without private source WAV hashes.')
    args = parser.parse_args()
    manifest = []
    if args.pack in ('magic', 'all'):
        manifest.extend(json.loads((ROOT / 'manifest.json').read_text()))
    if args.pack in ('spoken', 'all'):
        custom = json.loads((ROOT / 'spoken' / 'manifest.json').read_text())
        if custom.get('version') == 2:
            for source in custom['sources']:
                if not args.runtime_only:
                    assert hashlib.sha256((ROOT / source['file']).read_bytes()).hexdigest() == source['sha256'], 'Source WAV was changed'
                clips = [item for item in custom['sounds'] if item['source'] == source['file']]
                assert len(clips) == source['clips'] > 0
                for first, following in zip(clips, clips[1:]):
                    assert first['source_end'] <= following['source_start'], 'Clips overlap'
        else:
            source = ROOT / custom['source']
            if not args.runtime_only:
                assert hashlib.sha256(source.read_bytes()).hexdigest() == custom['source_sha256'], 'Source WAV was changed'
            for first, following in zip(custom['sounds'], custom['sounds'][1:]):
                assert first['source_end'] <= following['source_start'], 'Clips overlap and contain repeated samples'
        manifest.extend(custom['sounds'])
    counts, hashes, measures = Counter(), set(), []
    for item in manifest:
        path = ROOT / item['file']
        digest = hashlib.sha256(path.read_bytes()).digest()
        assert digest not in hashes, f'Duplicate audio: {path.name}'
        hashes.add(digest)
        probe = json.loads(subprocess.check_output([
            'ffprobe', '-v', 'error', '-show_streams', '-of', 'json', str(path)]))['streams'][0]
        assert probe['codec_name'] == 'vorbis' and probe['channels'] == 2 and int(probe['sample_rate']) == 44100
        raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(path), '-f', 'f32le', '-acodec', 'pcm_f32le', '-'])
        signal = np.frombuffer(raw, dtype='<f4').reshape(-1, 2)
        duration = len(signal) / 44100
        assert abs(float(probe['duration']) - item['duration']) < 0.001, path.name
        # A raw decoder can emit a padded last Vorbis block beyond the OGG's
        # final granule. Check the encoded duration separately and allow at
        # most one long block in decoded PCM, then measure the actual signal.
        assert abs(duration - item['duration']) < 2048 / 44100 + 0.001, path.name
        signal = signal[:round(float(probe['duration']) * 44100)]
        assert np.isfinite(signal).all()
        peak = float(np.max(np.abs(signal)))
        rms = float(np.sqrt(np.mean(signal ** 2)))
        assert 0.01 < peak < 0.95 and 0.02 < rms < 0.12, f'Silence/clipping/gain: {path.name}'
        assert abs(float(np.mean(signal))) < 0.001, f'DC offset: {path.name}'
        mono = signal.mean(axis=1)
        window = 441
        block_energy = np.mean(mono[:len(mono) // window * window].reshape(-1, window) ** 2, axis=1)
        peak_ms = int(np.argmax(block_energy)) * 10
        frequencies = np.fft.rfftfreq(len(mono), 1 / 44100)
        power = np.abs(np.fft.rfft(mono)) ** 2
        centroid = float(np.sum(frequencies * power) / np.sum(power))
        measures.append({**item, 'decoded_peak_dbfs': round(20 * np.log10(peak), 2),
                         'decoded_rms_dbfs': round(20 * np.log10(rms), 2),
                         'energy_centroid_hz': round(centroid), 'peak_10ms_window_ms': peak_ms})
        counts[item['school'], item['kind']] += 1
    if args.pack in ('magic', 'all'):
        for school in ('shadow', 'fire', 'frost', 'arcane', 'nature', 'holy', 'neutral'):
            for kind, expected in {'hit': 6, 'crit': 4, 'resist': 4, 'miss': 2, 'absorb': 2}.items():
                assert counts[school, kind] == expected, f'Count: {school} {kind}'
    if args.pack in ('spoken', 'all'):
        if custom.get('version') == 2:
            voice_files = {Path(item['file']).name for item in custom['sounds']}
            for weapon, bank in custom['banks'].items():
                for category in ('hit', 'crit', 'miss', 'graze', 'resist', 'absorb'):
                    assert bank[category] or (weapon in CAST_ONLY and category in ('hit', 'crit')) or (weapon == 'blizzard' and category == 'crit') or (weapon == 'frostbolt' and category in ('hit', 'crit'))
                    assert all(file in voice_files for file in bank[category])
                if weapon in MAGE_SPELLS:
                    assert all(file in voice_files for file in bank.get('cast', []))
            assert len(voice_files) == len(custom['sounds']) > 0
        else:
            assert counts['all', 'spoken'] == len(custom['sounds']) > 0
    output = ROOT / 'analysis' / ('spoken_audio_validation.json' if args.pack == 'spoken' else 'school_audio_validation.json')
    output.parent.mkdir(exist_ok=True)
    output.write_text(json.dumps(measures, indent=2, ensure_ascii=False) + '\n')
    print(f'Validated {len(measures)} distinct stereo Vorbis files: duration, gain, headroom, no silence/NaNs/DC offset.')
    if args.runtime_only and args.pack in ('spoken', 'all'):
        print('Runtime-only validation: private source WAV hashes are checked locally, not in public CI.')
    for school in (() if args.pack == 'spoken' else ('shadow', 'fire', 'frost', 'arcane', 'nature', 'holy')):
        hits = [m for m in measures if m['school'] == school and m['kind'] == 'hit']
        print(school, 'normal spectral centroid:', round(np.mean([m['energy_centroid_hz'] for m in hits])),
              'Hz; peak windows:', [m['peak_10ms_window_ms'] for m in hits], 'ms')


if __name__ == '__main__':
    main()
