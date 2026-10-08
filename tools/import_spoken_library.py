#!/usr/bin/env python3
"""Import categorized microphone recordings without altering their sources."""
import base64
import argparse
from collections import Counter
import hashlib
import html
import json
import os
from pathlib import Path
import subprocess
import tempfile

import numpy as np
from import_spoken import ROOT, RATE, split_ranges, write_wav

MAGE_SPELLS = {
    'frostbolt': 'Frostblitz', 'frostnova': 'Frostnova', 'blizzard': 'Blizzard',
    'coneofcold': 'Kältekegel', 'icebarrier': 'Eisbarriere', 'iceblock': 'Eisblock',
    'coldsnap': 'Kälteeinbruch', 'frostward': 'Frostzauberschutz',
    'fireball': 'Feuerball', 'fireblast': 'Feuerschlag', 'scorch': 'Versengen',
    'pyroblast': 'Pyroschlag', 'flamestrike': 'Flammenstoß', 'blastwave': 'Druckwelle',
    'combustion': 'Verbrennung',
}
CAST_ONLY = {'icebarrier', 'iceblock', 'coldsnap', 'frostward', 'combustion'}
MELEE_WEAPONS = {'blade': 'Schwerter / Äxte', 'blunt': 'Streitkolben / Stäbe', 'dagger': 'Dolche', 'fist': 'Faustwaffen / unbewaffnet'}
WEAPONS = {'wand': 'Zauberstab', 'bow': 'Pfeile / Armbrust', 'gun': 'Schusswaffen', **MAGE_SPELLS, **MELEE_WEAPONS}
RECORDING_DIRS = {weapon: ROOT / 'spoken' / weapon for weapon in ('wand', 'bow', 'gun')}
RECORDING_DIRS.update({spell: ROOT / 'spoken' / 'mage' / spell for spell in MAGE_SPELLS})
RECORDING_DIRS.update({weapon: ROOT / 'spoken' / 'melee' / weapon for weapon in MELEE_WEAPONS})


def reviewed_ranges(source_name, source_hash, samples, pause):
    cuts = json.loads((ROOT / 'spoken/melee/cuts.json').read_text())
    record = cuts.get(source_name)
    if not record:
        return split_ranges(samples, RATE, -35, pause)
    if record['sha256'] != source_hash:
        raise ValueError('Recording changed; review its cuts before importing: ' + source_name)
    ranges = [(round(a * RATE), round(b * RATE)) for a, b in record['ranges_seconds']]
    if not ranges or any(not 0 <= a < b <= len(samples) for a, b in ranges) or any(a[1] > b[0] for a, b in zip(ranges, ranges[1:])):
        raise ValueError('Invalid reviewed cuts: ' + source_name)
    return ranges


LABELS = {'hit': 'Treffer', 'crit': 'Crit', 'miss': 'Verfehlt', 'graze': 'Teiltreffer', 'resist': 'Widerstanden', 'absorb': 'Absorbiert', 'cast': 'Zauberbeginn'}


def build_preview(items, target_dir=None, weapons=None):
    options = ''.join(f'<option value="{key}">{html.escape(label)}</option>' for key, label in (weapons or WEAPONS).items())
    cards = []
    for item in items:
        src = (os.path.relpath(ROOT / item['file'], target_dir).replace(os.sep, '/') if target_dir else
               'data:audio/ogg;base64,' + base64.b64encode((ROOT / item['file']).read_bytes()).decode())
        cards.append(f'<article data-weapon="{item["weapon"]}" data-kind="{item["kind"]}"><h2>{html.escape(item["name"])}</h2><p>{html.escape(item["source"])} · {item["source_start"]:.2f}–{item["source_end"]:.2f} s</p><audio controls preload="none" data-group="{html.escape(item["repeat_group"])}" src="{html.escape(src)}"></audio></article>')
    return ('''<!doctype html><html lang="de"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Gabba – gesprochene Soundpakete</title><style>
body{font-family:system-ui;background:#111321;color:#eeeaf8;max-width:1050px;padding:25px;margin:auto}p{color:#bcb4d5;line-height:1.5}section{display:grid;grid-template-columns:repeat(auto-fit,minmax(270px,1fr));gap:16px}article{background:#1e2137;border-radius:12px;padding:18px}article[hidden]{display:none}audio{width:100%}select,button{font:inherit;background:#b9a6ff;border:0;border-radius:8px;padding:10px;margin:10px 8px 20px 0;cursor:pointer}
</style><h1>Gesprochene Soundpakete</h1><p>Eigene Casts, Treffer und Crits für 15 Frost-/Feuerzauber sowie Treffer und Crits für Zauberstab, Pfeile, Schusswaffen und vier Nahkampf-Waffengruppen. Miss- und Teiltreffer-Sprüche sind gemeinsam. Die Sprüche werden als ganze Phrasen geschnitten. Teiltreffer bedeutet Streifschläge und teilweise widerstandenen/geblockten Schaden; Fernkampfangriffe haben in Classic keine regulären Glancing Blows.</p>
<label>Waffe / Zauber: <select id="weapon">PLACEHOLDER_OPTIONS</select></label>
<label>Trefferart: <select id="kind"><option value="hit">Normal</option><option value="crit">Crit</option><option value="cast">Zauberbeginn / Aktivieren</option><option value="miss">Miss (gemeinsam)</option><option value="graze">Teiltreffer (gemeinsam)</option></select></label>
<button id="random">Zufällig anhören</button><button id="stop">Stoppen</button><section>''' + ''.join(cards) + '''</section><script>
const cards=[...document.querySelectorAll('article')], players=[...document.querySelectorAll('audio')], weapon=document.querySelector('#weapon'), kind=document.querySelector('#kind'), previous={};
function stop(){players.forEach(p=>{p.pause();p.currentTime=0;});}
function filter(){stop(); cards.forEach(c=>c.hidden=c.dataset.kind!==kind.value||(c.dataset.weapon!=='shared'&&c.dataset.weapon!==weapon.value));}
weapon.onchange=filter;kind.onchange=filter;filter();
players.forEach(p=>p.onplay=()=>players.forEach(other=>{if(other!==p)other.pause();}));document.querySelector('#stop').onclick=stop;
document.querySelector('#random').onclick=()=>{const pool=cards.filter(c=>!c.hidden).map(c=>c.querySelector('audio')),key=weapon.value+kind.value,last=previous[key];let choices=pool.filter(p=>!last||p.dataset.group!==last.dataset.group);if(!choices.length)choices=pool.filter(p=>p!==last);if(!choices.length)choices=pool;if(!choices.length)return;const chosen=choices[Math.floor(Math.random()*choices.length)];previous[key]=chosen;chosen.currentTime=0;chosen.play().catch(()=>{});};
</script></html>''').replace('PLACEHOLDER_OPTIONS', options)


def build_banks(sounds):
    banks = {}
    for weapon in WEAPONS:
        bank = {}
        for kind in ('hit','crit','miss','graze'):
            selected_weapon = 'shared' if kind in ('miss','graze') else weapon
            bank[kind] = [Path(item['file']).name for item in sounds if item['kind']==kind and item['weapon']==selected_weapon]
            if not bank[kind] and not (weapon in MAGE_SPELLS and kind in ('hit', 'crit')):
                raise SystemExit(f'Missing sound pool: {weapon}/{kind}')
        bank['resist'], bank['absorb'] = bank['miss'], bank['miss']
        if weapon in MAGE_SPELLS:
            bank['cast'] = [Path(item['file']).name for item in sounds if item['kind'] == 'cast' and item['weapon'] == weapon]
        banks[weapon] = bank
    return banks


def write_registry(manifest):
    sounds, banks = manifest['sounds'], manifest['banks']
    lines = ['-- Generated by tools/import_spoken_library.py', 'local _, addon = ...', 'local banks = {']
    for weapon, bank in banks.items():
        lines.append('    '+weapon+' = {')
        for kind, files in bank.items(): lines.append('        '+kind+' = { '+', '.join(json.dumps(f) for f in files)+' },')
        lines.append('    },')
    lines.extend(['}', 'local groups = {'])
    for item in sounds: lines.append('    ['+json.dumps(Path(item['file']).name)+'] = '+json.dumps(item['repeat_group'])+',')
    lines.extend(['}', 'addon.packOrder = { "magic", "spoken", "spoken_wand", "spoken_bow", "spoken_gun", "spoken_frostbolt", "spoken_mage", "spoken_melee", "spoken_blade", "spoken_blunt", "spoken_dagger", "spoken_fist" }', 'addon.soundPacks = {',
                 '    magic = { label = "Magie je Schadensart", schools = addon.schoolSounds, weapon = "wand" },',
                 '    spoken = { label = "Eigene Aufnahmen (automatisch)", categories = banks.wand, weapons = banks, repeatGroups = groups },'])
    lines.append('    spoken_mage = { label = "Gesprochen: Magier (Frost und Feuer)", categories = banks.frostbolt, weapons = banks, mageOnly = true, repeatGroups = groups },')
    lines.append('    spoken_melee = { label = "Gesprochen: Nahkampf (automatisch)", categories = banks.blade, weapons = banks, meleeOnly = true, repeatGroups = groups },')
    for weapon,label in WEAPONS.items(): lines.append('    spoken_'+weapon+' = { label = "Gesprochen: '+label+'", weapon = "'+weapon+'", categories = banks.'+weapon+', repeatGroups = groups },')
    lines.append('}')
    lines.extend(['addon.voiceBanks = banks', 'addon.sharedGraze = banks.wand.graze',
                  'addon.voiceShared = { miss = banks.wand.miss, resist = banks.wand.resist, absorb = banks.wand.absorb, graze = banks.wand.graze }'])
    for item in sounds: lines.append('addon.soundDurations['+json.dumps(Path(item['file']).name)+'] = '+str(item['duration']))
    (ROOT/'CustomSoundData.lua').write_text('\n'.join(lines)+'\n')
    write_previews(sounds)


def write_previews(sounds):
    pages = [('spoken/index.html', WEAPONS), ('melee/index.html', MELEE_WEAPONS)]
    pages.extend(('melee/' + key + '.html', {key: label}) for key, label in MELEE_WEAPONS.items())
    for name, weapons in pages:
        destination = ROOT / 'previews' / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        items = [item for item in sounds if item['weapon'] in weapons or item['weapon'] == 'shared']
        destination.write_text(build_preview(items, destination.parent, weapons), encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--registry-only', action='store_true', help='Update banks and UI data without re-encoding existing clips.')
    parser.add_argument('--melee-only', action='store_true', help='Import melee recordings while preserving all existing ranged and mage clips.')
    args = parser.parse_args()
    if args.registry_only:
        manifest = json.loads((ROOT/'spoken'/'manifest.json').read_text())
        manifest['banks'] = build_banks(manifest['sounds'])
        (ROOT/'spoken'/'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n')
        write_registry(manifest)
        return
    recordings = []
    for weapon in WEAPONS:
        if args.melee_only and weapon not in MELEE_WEAPONS: continue
        for source in sorted(RECORDING_DIRS[weapon].glob('*.wav')):
            stem = source.stem.lower()
            kind = ('cast' if weapon in MAGE_SPELLS and stem.startswith('cast') else
                    'hit' if stem.startswith(('hit', 'ht')) else 'crit' if stem.startswith('crit') else None)
            if kind is None:
                raise SystemExit(f'Unknown recording category: {source}. Use hit*.wav, crit*.wav or mage spell cast*.wav.')
            # The existing wand recording contains closely paired single noises.
            pause = (0.08 if weapon == 'wand' and stem == 'hit' else
                     0.40 if weapon in MAGE_SPELLS and kind == 'hit' else
                     0.20 if kind == 'hit' else 0.60)
            recordings.append((weapon, kind, source, pause))
    for kind in (() if args.melee_only else ('miss', 'graze')):
        source = ROOT / 'spoken' / 'shared' / (kind + '.wav')
        if not source.is_file(): raise SystemExit('Missing shared recording: ' + str(source))
        recordings.append(('shared', kind, source, 0.60))
    cuts = json.loads((ROOT / 'spoken/melee/cuts.json').read_text())
    # Reject stale reviewed cuts before writing any audio or manifest output.
    for _, _, source, _ in recordings:
        source_name = source.relative_to(ROOT).as_posix()
        if source_name in cuts and hashlib.sha256(source.read_bytes()).hexdigest() != cuts[source_name]['sha256']:
            raise SystemExit('Recording changed; review its cuts before importing: ' + source_name)
    sounds, sources, counts = [], [], Counter()
    if args.melee_only:
        existing = json.loads((ROOT/'spoken/manifest.json').read_text())
        sounds = [item for item in existing['sounds'] if item['weapon'] not in MELEE_WEAPONS]
        sources = [item for item in existing['sources'] if not item['file'].startswith('spoken/melee/')]
    with tempfile.TemporaryDirectory(prefix='gabba-voice-') as directory:
        for weapon, kind, source, pause in recordings:
            source_name = source.relative_to(ROOT).as_posix()
            source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
            raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(source), '-ar', str(RATE), '-ac', '2', '-f', 'f32le', '-'])
            samples = np.frombuffer(raw, dtype='<f4').reshape(-1, 2).astype(float)
            ranges = reviewed_ranges(source_name, source_hash, samples, pause)
            if not ranges: raise SystemExit('No sounds found: ' + source_name)
            families = split_ranges(samples, RATE, -42, 0.40) if kind == 'hit' and weapon not in MELEE_WEAPONS else ranges
            sources.append({'file': source_name, 'sha256': source_hash, 'duration': round(len(samples) / RATE, 5), 'pause_seconds': pause, 'threshold_db': -35, 'clips': len(ranges), 'cut_method': 'reviewed' if source_name in cuts else 'pause_detection'})
            for start, end in ranges:
                counts[weapon, kind] += 1
                index = counts[weapon, kind]
                midpoint = (start + end) / 2
                family = next((i for i,(a,b) in enumerate(families,1) if a <= midpoint <= b), index)
                group = source_name + ':' + str(family)
                clip = samples[start:end].copy()
                rms, peak = np.sqrt(np.mean(clip**2)), np.max(np.abs(clip))
                target = 0.078 if kind == 'crit' else 0.06
                gain = min(target / max(rms, 1e-9), 0.72 / max(peak, 1e-9), 2.5)
                clip *= gain
                fade = min(round(RATE * 0.006), len(clip) // 4)
                clip[:fade] *= np.linspace(0, 1, fade)[:, None]
                clip[-fade:] *= np.linspace(1, 0, fade)[:, None]
                name = f'voice_{weapon}_{kind}_{index:02d}'
                wav = Path(directory) / (name + '.wav')
                write_wav(wav, clip)
                editable = ROOT / 'spoken' / 'clips' / weapon / (name + '.wav')
                editable.parent.mkdir(parents=True, exist_ok=True)
                write_wav(editable, clip)
                destination = ROOT / 'Sounds' / (name + '.ogg')
                subprocess.run(['ffmpeg','-v','error','-y','-i',str(wav),'-c:a','libvorbis','-q:a','5',str(destination)],check=True)
                sounds.append({'name': f'{WEAPONS.get(weapon,"Gemeinsam")} · {LABELS[kind]} {index:02d}', 'file': destination.relative_to(ROOT).as_posix(), 'kind': kind, 'weapon': weapon, 'school': 'all',
                               'repeat_group': group, 'source': source_name, 'source_start': round(start/RATE,5), 'source_end': round(end/RATE,5), 'duration': round(len(clip)/RATE,5),
                               'editable_wav': editable.relative_to(ROOT).as_posix(), 'sample_rate': RATE, 'channels': 2,
                               'gain_db': round(20*np.log10(gain),2), 'peak_dbfs': round(20*np.log10(np.max(np.abs(clip))),2), 'rms_dbfs': round(20*np.log10(np.sqrt(np.mean(clip**2))),2)})
            assert hashlib.sha256(source.read_bytes()).hexdigest() == source_hash, 'Original recording changed'
            print(source_name, '->', len(ranges), 'clips')
    banks = build_banks(sounds)
    manifest = {'version': 2, 'sources': sources, 'sounds': sounds, 'banks': banks}
    (ROOT/'spoken'/'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n')
    write_registry(manifest)
    print('Total:',len(sounds),'distinct sounds;', {weapon:{k:len(v) for k,v in bank.items()} for weapon,bank in banks.items()})


if __name__ == '__main__': main()
