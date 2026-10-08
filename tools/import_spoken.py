#!/usr/bin/env python3
"""Split repeated vocal effects into individual takes; build a selectable pack.

The source WAV is read only. Generated clips retain their original timing and
pitch, with a short safety margin, gentle fades and bounded loudness matching.
"""
import argparse
import base64
import hashlib
import html
import json
from pathlib import Path
import subprocess
import tempfile
import wave

import numpy as np

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100
CATEGORIES = ('hit', 'crit', 'resist', 'miss', 'absorb')


def split_ranges(samples, rate, threshold_db=-35, pause_seconds=0.08):
    hop = max(1, round(rate * 0.01))
    # Inspect channels separately so opposite phase cannot hide real sound.
    energy = np.max(samples ** 2, axis=1)
    padded = np.pad(energy, (0, (-len(energy)) % hop))
    active = np.sqrt(np.mean(padded.reshape(-1, hop), axis=1)) > 10 ** (threshold_db / 20)
    changes = np.flatnonzero(np.diff(np.r_[False, active, False]))
    runs = [(int(a * hop), min(len(samples), int(b * hop))) for a, b in zip(changes[::2], changes[1::2])]
    merged = []
    for start, end in runs:
        if merged and start - merged[-1][1] < rate * pause_seconds:
            merged[-1] = (merged[-1][0], end)
        else:
            merged.append((start, end))
    merged = [(start, end) for start, end in merged if end - start >= rate * 0.12]
    rms = np.sqrt(np.mean(padded.reshape(-1, hop), axis=1))
    boundaries = [0]
    for previous, following in zip(merged, merged[1:]):
        # Place the cut at the quietest part of the gap. Safety margins must
        # never overlap and accidentally carry the next "pew" into this clip.
        first, last = previous[1] // hop, following[0] // hop
        valley = rms[first:last]
        if len(valley):
            minima = np.flatnonzero(valley <= np.min(valley) + 1e-9)
            center = (len(valley) - 1) / 2
            best = int(minima[np.argmin(np.abs(minima - center))])
            boundaries.append(min(len(samples), (first + best) * hop + hop // 2))
        else:
            boundaries.append((previous[1] + following[0]) // 2)
    boundaries.append(len(samples))
    result = []
    for index, (start, end) in enumerate(merged):
        left, right = boundaries[index:index + 2]
        # A lower threshold preserves breathy consonants and quiet decays
        # that were not loud enough to identify the main repeated sound.
        first, last = (left + hop - 1) // hop, right // hop
        quiet_active = np.flatnonzero(rms[first:last] > 10 ** (min(threshold_db, -42) / 20))
        if len(quiet_active):
            start = min(start, (first + int(quiet_active[0])) * hop)
            end = max(end, (first + int(quiet_active[-1]) + 1) * hop)
        result.append((max(left, start - round(rate * 0.06)), min(right, end + round(rate * 0.08))))
    return result


def write_wav(path, samples):
    with wave.open(str(path), 'wb') as output:
        output.setnchannels(samples.shape[1])
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(np.round(np.clip(samples, -1, 1) * 32767).astype('<i2').tobytes())


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('recording', nargs='?', type=Path, default=ROOT / 'spoken' / 'gesammelt.wav')
    parser.add_argument('--threshold-db', type=float, default=-35)
    parser.add_argument('--pause-seconds', type=float, default=0.08)
    args = parser.parse_args()
    existing_manifest = ROOT / 'spoken' / 'manifest.json'
    if existing_manifest.is_file() and json.loads(existing_manifest.read_text()).get('version', 1) >= 2:
        raise SystemExit('Categorized recordings are active. Use tools/import_spoken_library.py; this legacy importer would overwrite their mappings.')
    source = args.recording.resolve()
    source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
    raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(source), '-ar', str(RATE), '-ac', '2', '-f', 'f32le', '-'])
    samples = np.frombuffer(raw, dtype='<f4').reshape(-1, 2).astype(np.float64)
    ranges = split_ranges(samples, RATE, args.threshold_db, args.pause_seconds)
    families = split_ranges(samples, RATE, -42, 0.40)
    if not ranges:
        raise SystemExit('No useful sounds detected. Source recording was not modified.')
    output_dir = ROOT / 'Sounds'
    output_dir.mkdir(exist_ok=True)
    editable_dir = ROOT / 'spoken' / 'clips'
    editable_dir.mkdir(parents=True, exist_ok=True)
    items = []
    family_takes = {}
    with tempfile.TemporaryDirectory(prefix='gabba-spoken-') as directory:
        for index, (start, end) in enumerate(ranges, 1):
            midpoint = (start + end) / 2
            family = next((i for i, (a, b) in enumerate(families, 1) if a <= midpoint <= b), index)
            family_takes[family] = family_takes.get(family, 0) + 1
            clip = samples[start:end].copy()
            rms = np.sqrt(np.mean(clip ** 2))
            peak = np.max(np.abs(clip))
            # Preserve dynamic transients. Do not aggressively compress or
            # amplify background hiss when this short recording is peak-heavy.
            gain = min(0.06 / max(rms, 1e-9), 0.72 / max(peak, 1e-9), 2.5)
            clip *= gain
            fade = min(round(RATE * 0.006), len(clip) // 4)
            clip[:fade] *= np.linspace(0, 1, fade)[:, None]
            clip[-fade:] *= np.linspace(1, 0, fade)[:, None]
            filename = f'spoken_{index:02d}.ogg'
            wav = Path(directory) / f'spoken_{index:02d}.wav'
            write_wav(wav, clip)
            write_wav(editable_dir / wav.name, clip)
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(wav), '-c:a', 'libvorbis', '-q:a', '5', str(output_dir / filename)], check=True)
            items.append({'name': f'Klang {family} · Variante {family_takes[family]}', 'file': 'Sounds/' + filename, 'school': 'all',
                          'repeat_group': family,
                          'editable_wav': 'spoken/clips/' + wav.name,
                          'kind': 'spoken', 'duration': round(len(clip) / RATE, 5),
                          'source_start': round(start / RATE, 5), 'source_end': round(end / RATE, 5),
                          'gain_db': round(20 * np.log10(gain), 2), 'sample_rate': RATE, 'channels': 2,
                          'peak_dbfs': round(20 * np.log10(np.max(np.abs(clip))), 2),
                          'rms_dbfs': round(20 * np.log10(np.sqrt(np.mean(clip ** 2))), 2)})
    data = {'pack_id': 'spoken', 'label': 'Eigene Aufnahme', 'source': str(source.relative_to(ROOT)) if source.is_relative_to(ROOT) else source.name,
            'source_sha256': source_hash, 'source_duration': round(len(samples) / RATE, 5),
            'split_threshold_db': args.threshold_db, 'split_pause_seconds': args.pause_seconds,
            'categories': {category: [Path(item['file']).name for item in items] for category in CATEGORIES}, 'sounds': items}
    (ROOT / 'spoken' / 'manifest.json').write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    lines = ['-- Generated by tools/import_spoken.py; the source recording is untouched.', 'local _, addon = ...',
             'addon.packOrder = { "magic", "spoken" }', 'addon.soundPacks = {',
             '    magic = { label = "Magie je Schadensart", schools = addon.schoolSounds },',
             '    spoken = { label = "Eigene Aufnahme", categories = {']
    for category, files in data['categories'].items():
        lines.append('        ' + category + ' = { ' + ', '.join('"' + file + '"' for file in files) + ' },')
    lines.append('    }, repeatGroups = {')
    for item in items:
        lines.append('        ["' + Path(item['file']).name + '"] = ' + str(item['repeat_group']) + ',')
    lines.extend(['    } },', '}'])
    for item in items:
        lines.append('addon.soundDurations["' + Path(item['file']).name + '"] = ' + str(item['duration']))
    (ROOT / 'CustomSoundData.lua').write_text('\n'.join(lines) + '\n')
    cards = []
    for item in items:
        encoded = base64.b64encode((ROOT / item['file']).read_bytes()).decode()
        cards.append(f'<article><h2>{html.escape(item["name"])}</h2><p>Original: {item["source_start"]:.2f}–{item["source_end"]:.2f} s · Dauer: {item["duration"]:.2f} s</p><audio data-group="{item["repeat_group"]}" controls preload="none" src="data:audio/ogg;base64,{encoded}"></audio></article>')
    page = '''<!doctype html><html lang="de"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Gabba – eigene Aufnahme</title><style>
body{font-family:system-ui;background:#111321;color:#eeeaf8;margin:30px auto;padding:0 24px;max-width:900px}p{color:#bcb4d5}section{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:16px}article{background:#1e2137;border-radius:12px;padding:20px}audio{width:100%}button{font:inherit;background:#b9a6ff;border:0;border-radius:8px;padding:12px;margin:12px 6px 20px 0;cursor:pointer}
</style><h1>Eigene Aufnahme – einzelne Laute</h1><p>Wiederholte Laute sind einzeln geschnitten, mit kurzen Ein-/Ausblendungen und angeglichener Lautstärke. Im Spiel: /gws → Soundpaket → Eigene Aufnahme. Alle Clips werden zufällig für alle Trefferarten und Schadensarten verwendet; dieselbe Klangfamilie wird innerhalb einer Trefferart nicht direkt wiederholt.</p><button id="random">Zufälligen Sound hören</button><button id="stop">Stoppen</button><section>''' + ''.join(cards) + '''</section><script>
const players = [...document.querySelectorAll('audio')]; let previous;
players.forEach(p => p.addEventListener('play', () => players.forEach(other => { if(other !== p) other.pause(); })));
document.querySelector('#stop').onclick = () => players.forEach(p => { p.pause(); p.currentTime = 0; });
document.querySelector('#random').onclick = () => { let choices = players.filter(p => !previous || p.dataset.group !== previous.dataset.group); if(!choices.length) choices = players.filter(p => p !== previous); if(!choices.length) choices = players; const selected = choices[Math.floor(Math.random() * choices.length)]; previous = selected; selected.currentTime = 0; selected.play().catch(() => {}); };
</script></html>'''
    (ROOT / 'spoken' / 'Anhoeren.html').write_text(page)
    assert hashlib.sha256(source.read_bytes()).hexdigest() == source_hash, 'Source WAV changed!'
    print(f'Split {source.name} ({len(samples) / RATE:.2f}s) into {len(items)} sounds; source SHA256 unchanged.')
    for item in items:
        print(item['file'], f'{item["source_start"]:.2f}–{item["source_end"]:.2f}s, duration {item["duration"]:.2f}s, gain {item["gain_db"]:.1f}dB')


if __name__ == '__main__':
    main()
