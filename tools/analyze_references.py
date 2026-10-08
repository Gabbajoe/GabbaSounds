#!/usr/bin/env python3
"""Measure public WoW wand references and build a browser comparison report."""

import argparse
import base64
import html
import json
from pathlib import Path
import subprocess

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
RATE = 44100
INSPIRATION = [
    ('Sound Spark: Designing and Recording Magic Sound Effects', 'https://www.soundsparkllc.com/blogs/sound-design-blog/designing-and-recording-magic-sound-effects'),
    ('David Dumais: Magic Sound Design with Soundweaver', 'https://www.daviddumaisaudio.com/magic-sound-design-with-soundweaver-by-boom-library/'),
]


def measure(path):
    metadata = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_streams', '-show_format', '-of', 'json', str(path)]))
    raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(path), '-ac', '1', '-ar', str(RATE), '-f', 'f32le', '-'])
    x = np.frombuffer(raw, dtype='<f4').astype(float)
    frequencies = np.fft.rfftfreq(len(x), 1 / RATE)
    spectrum = np.fft.rfft(x)
    # Old recordings contain substantial infrasonic movement. Exclude it from
    # the audible-energy comparison so it does not dominate the shadow sample.
    spectrum[frequencies < 30] = 0
    x = np.fft.irfft(spectrum, n=len(x))
    power = np.abs(spectrum)**2
    power /= power.sum()
    cumulative = np.cumsum(x*x)
    cumulative /= cumulative[-1]
    frame = 441
    envelope = np.sqrt(np.mean(x[:len(x)//frame*frame].reshape(-1, frame)**2, axis=1))
    return {
        'duration_seconds': float(metadata['format']['duration']),
        'channels': metadata['streams'][0]['channels'],
        'sample_rate': int(metadata['streams'][0]['sample_rate']),
        'peak_envelope_ms': int(np.argmax(envelope)) * 10,
        'energy_10_90_ms': [round(float(np.searchsorted(cumulative, value) / RATE * 1000)) for value in (0.1, 0.9)],
        'power_centroid_hz': round(float(np.sum(frequencies * power))),
        'band_energy_pct': {
            f'{lo}-{hi}Hz': round(float(power[(frequencies >= lo) & (frequencies < hi)].sum() * 100), 2)
            for lo, hi in ((30, 250), (250, 1000), (1000, 3000), (3000, 6000), (6000, 22050))
        },
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('reference_dir', type=Path)
    args = parser.parse_args()
    output = ROOT / 'analysis'
    output.mkdir(exist_ok=True)
    sources = json.loads((args.reference_dir / 'sources.json').read_text())
    results = []
    for source in sources:
        if 'error' in source:
            continue
        results.append({'name': 'WoW ' + source['school'], 'source_url': source['url'], 'file_data_id': source['file_data_id'], **measure(Path(source['path']))})
    for filename, label in (('hit_01_arcane.ogg', 'Eigene v0.3: Arkanfunke'), ('hit_05_shadow.ogg', 'Eigene v0.3: Schattenimpuls'), ('crit_01_arcane_burst.ogg', 'Eigene v0.3: Arkaneruption')):
        path = ROOT / 'Sounds' / filename
        results.append({'name': label, 'local_file': 'Sounds/' + filename, **measure(path)})
    report = {'method': 'Mono analysis at 44.1 kHz; energy below 30 Hz excluded; peak from 10 ms RMS windows; 10–90% interval contains the middle 80% of audible signal energy.', 'provenance': 'Public Wowhead live-CDN files at the FileDataIDs listed in the installed Classic Era Leatrix Sounds database. Not extracted from local CASC archives.', 'sounds': results, 'inspiration': [{'title': title, 'url': url} for title, url in INSPIRATION]}
    (output / 'reference_analysis.json').write_text(json.dumps(report, indent=2, ensure_ascii=False) + '\n')
    cards = []
    for name in ('WoW Shadow', 'WoW Arcane', 'WoW Holy', 'Eigene v0.3: Schattenimpuls', 'Eigene v0.3: Arkanfunke'):
        item = next(item for item in results if item['name'] == name)
        original = 'source_url' in item
        if original:
            src = item['source_url']
        else:
            src = 'data:audio/ogg;base64,' + base64.b64encode((ROOT / item['local_file']).read_bytes()).decode()
        low, high = item['energy_10_90_ms']
        cards.append(f'<article><h2>{html.escape(name)}</h2><audio data-original="{str(original).lower()}" controls preload="none" src="{html.escape(src)}"></audio><p>Stärkste Stelle: <b>{item["peak_envelope_ms"]} ms</b><br>Mittlere 80 % der Klangenergie: <b>{low}–{high} ms</b><br>Dateidauer: {item["duration_seconds"]:.2f} s</p></article>')
    rows = ''.join(f'<tr><td>{html.escape(item["name"])}</td><td>{item["peak_envelope_ms"]} ms</td><td>{item["energy_10_90_ms"][0]}–{item["energy_10_90_ms"][1]} ms</td><td>{item["duration_seconds"]:.2f} s</td></tr>' for item in results)
    figures = []
    for name, label, source in (('shadow', 'WoW Schatten: langsamer Aufbau und langer Ausklang', args.reference_dir / 'shadow.ogg'), ('holy', 'WoW Heilig: bewegte Mitten und langer Ausklang', args.reference_dir / 'holy.ogg'), ('ours', 'Eigene v0.3: sehr früher Impuls und rascher Abfall', ROOT / 'Sounds/hit_05_shadow.ogg')):
        image_path = output / (name + '-spectrum.png')
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(source), '-lavfi', 'showspectrumpic=s=1000x420:legend=1:fscale=log:scale=log:color=viridis:stop=6000:drange=65', '-frames:v', '1', str(image_path)], check=True)
        data = base64.b64encode(image_path.read_bytes()).decode()
        figures.append(f'<figure><figcaption>{label}</figcaption><img src="data:image/png;base64,{data}" alt="Spektrogramm: {html.escape(label)}"></figure>')
    links = ''.join(f'<li><a href="{url}">{html.escape(title)}</a></li>' for title, url in INSPIRATION)
    page = '''<!doctype html><html lang="de"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>WoW-Zauberstab: Referenzvergleich</title>
<style>body{font:16px/1.6 system-ui,sans-serif;background:#111321;color:#eeeaf8;max-width:1100px;margin:auto;padding:28px}h1{line-height:1.2}h2{font-size:21px}p,li{color:#c4bdda}a{color:#baa7ff}.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(290px,1fr));gap:16px}article{padding:18px;background:#1e2137;border:1px solid #363b60;border-radius:12px}audio{width:100%}table{width:100%;border-collapse:collapse}th,td{padding:9px;border-bottom:1px solid #363b60;text-align:left}figure{margin:24px 0}img{width:100%;height:auto}figcaption{font-weight:600}small{color:#b0a9c4}.notice{padding:16px;background:#252141;border-radius:12px}</style>
<h1>WoW-Zauberstab: Referenzvergleich</h1>
<p class="notice">Die wichtigsten Unterschiede liegen im zeitlichen Aufbau und der bewegten Klangtextur. Die Originale wachsen über etwa 130–250 ms an. Unsere normalen Treffer haben ihr Maximum schon nach 20 ms und verlieren fast ihre ganze Energie in den ersten 90 ms.</p>
<p>Originaldateien: öffentliche Wowhead-CDN-Dateien mit den IDs aus der installierten Classic-Era-Soundliste. Sie wurden nicht direkt aus den lokalen Spieldateien extrahiert. Die Original-Player benötigen Internet; eigene Hörproben und Spektrogramme sind eingebettet. Die Originale werden für einen angenehmeren Vergleich leiser abgespielt.</p>
<div class="cards">''' + ''.join(cards) + '''</div>
<h2>Was die nächste Klangrichtung braucht</h2>
<ul><li>Einen erkennbaren Luft-/Energieaufbau und einen vorbeiziehenden, leicht gleitenden Ton.</li><li>Eine länger tragende Mitte statt eines sofort abfallenden Impulses.</li><li>Feine unregelmäßige Textur statt einer Kette metallischer Glockentöne.</li><li>Crits als größere Entladung derselben Klangfamilie; Widerstände als abbrechender Aufbau.</li></ul>
<p>Das sind Gestaltungsentscheidungen aus dem Messvergleich und den Quellen unten, keine Aussagen über Blizzards ursprünglichen Herstellungsprozess.</p>
<h2>Messwerte</h2><table><thead><tr><th>Sound</th><th>Stärkste Stelle</th><th>Mittlere 80 % Energie</th><th>Dateidauer</th></tr></thead><tbody>''' + rows + '''</tbody></table>
<p><small>Analyse in Mono mit 44,1 kHz. Frequenzen unter 30 Hz sind für Energie und Zeitverlauf ausgeblendet, da die alten Aufnahmen teils starke kaum hörbare tieffrequente Anteile haben. Das Maximum wird in 10-ms-RMS-Fenstern gemessen. Die Energiedauer ist nicht gleich der vollständigen hörbaren Länge. Die Launch-Dateien bilden außerdem nicht sämtliche möglichen Aufprall- und Umgebungsgeräusche im Spiel ab.</small></p>
<h2>Frequenzbilder</h2><p>Die Zeitachsen unterscheiden sich entsprechend der Dateidauer. Die Farben zeigen den Pegel; längere Klangbewegungen sind bei den Originalen gut sichtbar.</p>''' + ''.join(figures) + '''
<h2>Inspiration von Sounddesignern</h2><ul>''' + links + '''</ul>
<p>Sound Spark nennt WoW ausdrücklich als Inspiration und setzt auf Luftgeräusche, Dopplerbewegung und organische Texturen. David Dumais beschreibt die Schichtung von gleitenden Tönen, Whooshes und Impulsen sowie Variationen innerhalb derselben Klangfamilie.</p>
<script>const players=[...document.querySelectorAll('audio')];players.forEach(p=>{if(p.dataset.original==='true')p.volume=.4;p.addEventListener('play',()=>players.forEach(o=>{if(o!==p)o.pause()}))});</script></html>
'''
    (ROOT / 'Referenzvergleich.html').write_text(page, encoding='utf-8')
    print('Created reference_analysis.json, three spectrograms, and Referenzvergleich.html.')


if __name__ == '__main__':
    main()
