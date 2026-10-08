#!/usr/bin/env python3
"""Create original, deterministic wand effects with NumPy and ffmpeg."""

import base64
import html
import json
from pathlib import Path
import shutil
import subprocess
import tempfile
import wave

import numpy as np


ROOT = Path(__file__).resolve().parents[1]
RATE = 44100
VARIANTS = [
    ("hit_01_arcane", "Arkanfunke", "hit", 0.76, 440, 1.00, 0.70, 11),
    ("hit_02_crystal", "Ätherfunke", "hit", 0.80, 540, 1.35, 0.45, 23),
    ("hit_03_ember", "Glutfunke", "hit", 0.72, 330, 0.65, 1.15, 37),
    ("hit_04_frost", "Frosthauch", "hit", 0.82, 620, 1.15, 0.95, 41),
    ("hit_05_shadow", "Schattenimpuls", "hit", 0.78, 280, 0.60, 0.70, 59),
    ("hit_06_star", "Sternenstaub", "hit", 0.84, 490, 1.50, 0.55, 67),
    ("crit_01_arcane_burst", "Arkaneruption", "crit", 0.94, 390, 1.10, 0.95, 79),
    ("crit_02_crystal_shatter", "Magiewelle", "crit", 1.00, 520, 1.55, 0.75, 83),
    ("crit_03_storm", "Sturmschlag", "crit", 0.90, 310, 0.85, 1.45, 97),
    ("crit_04_starburst", "Sternenexplosion", "crit", 1.04, 460, 1.65, 0.85, 101),
    ("resist_01_fizzle", "Funkenverpuffen", "resist", 0.50, 370, 0.55, 1.00, 113),
    ("resist_02_barrier", "Magisches Abprallen", "resist", 0.54, 480, 0.80, 0.65, 127),
    ("resist_03_dissolve", "Aufgelöster Zauber", "resist", 0.58, 300, 0.45, 1.10, 131),
    ("resist_04_sputter", "Versiegender Funke", "resist", 0.52, 420, 0.70, 0.90, 149),
    ("miss_01_passby", "Vorbeiziehender Zauber", "miss", 0.62, 390, 0.70, 1.05, 157),
    ("miss_02_deflect", "Abgelenkter Funke", "miss", 0.58, 470, 0.80, 0.90, 163),
    ("absorb_01_dampen", "Magisch aufgefangen", "absorb", 0.66, 350, 0.70, 0.90, 173),
    ("absorb_02_shield", "Im Schild versickert", "absorb", 0.70, 430, 0.90, 0.80, 181),
]


# Each school has its own texture layers, not merely transposed copies.
SCHOOLS = [
    ('shadow', 'Schatten', 32, 330, 0.85),
    ('fire', 'Feuer', 4, 380, 1.05),
    ('frost', 'Frost', 16, 570, 1.20),
    ('arcane', 'Arkan', 64, 490, 1.00),
    ('nature', 'Natur', 8, 410, 1.00),
    ('holy', 'Heilig', 2, 530, 1.15),
]
KINDS = ('hit', 'crit', 'resist', 'miss', 'absorb')
COUNTS = {'hit': 6, 'crit': 4, 'resist': 4, 'miss': 2, 'absorb': 2}
KIND_LABELS = {'hit': 'Treffer', 'crit': 'Crit', 'resist': 'Widerstand', 'miss': 'Fehlschlag', 'absorb': 'Absorption'}
GESTURES = ('Funke', 'Welle', 'Wirbel', 'Impuls', 'Schweif', 'Stoß')


def envelope(t, start, attack, decay):
    elapsed = np.maximum(t - start, 0)
    return (t >= start) * (1 - np.exp(-elapsed / attack)) * np.exp(-elapsed / decay)


def chirp(t, start_hz, end_hz, glide):
    frequency = end_hz + (start_hz - end_hz) * np.exp(-t / glide)
    return 2 * np.pi * np.cumsum(frequency) / RATE


def noise(rng, samples, center, width):
    frequencies = np.fft.rfftfreq(samples, 1 / RATE)
    spectrum = np.fft.rfft(rng.normal(size=samples))
    spectrum *= np.exp(-0.5 * ((frequencies - center) / width) ** 2)
    spectrum *= 1 - np.exp(-(frequencies / 180) ** 2)
    result = np.fft.irfft(spectrum, n=samples)
    return result / max(np.std(result), 1e-9)


def harmonic_pulse(t, start_hz, end_hz, glide):
    """Warm, almost sinusoidal core; no inharmonic bells or FM sidebands."""
    phase = chirp(t, start_hz, end_hz, glide)
    return np.sin(phase) + 0.10 * np.sin(2 * phase) + 0.018 * np.sin(3 * phase)


def finish_sound(x, kind):
    # Keep airy high frequencies while gently removing rumble and sharp hiss.
    frequencies = np.fft.rfftfreq(len(x), 1 / RATE)
    cutoff = 3700 if kind in ('resist', 'absorb') else 4800
    spectrum = np.fft.rfft(x)
    spectrum *= 1 / np.sqrt(1 + (frequencies / cutoff) ** 8)
    spectrum *= 1 - np.exp(-(frequencies / 120) ** 4)
    x = np.fft.irfft(spectrum, n=len(x))
    stereo = np.column_stack((x, x))
    for delay, gain in ((0.037, 0.09), (0.071, 0.06), (0.117, 0.035)):
        for channel in range(2):
            offset = round((delay + channel * 0.006) * RATE)
            stereo[offset:, channel] += gain * x[:-offset]
    # Gentle soft limiting before gain matching, with ample final headroom.
    stereo = 0.22 * np.tanh(stereo / 0.22)
    target = {'hit': 0.065, 'crit': 0.092, 'resist': 0.050, 'miss': 0.052, 'absorb': 0.054}[kind]
    stereo *= target / max(np.sqrt(np.mean(stereo**2)), 1e-9)
    peak = np.max(np.abs(stereo))
    if peak > 0.65:
        stereo *= 0.65 / peak
    fade_in = round(0.003 * RATE)
    fade_out = round(0.060 * RATE)
    stereo[:fade_in] *= np.linspace(0, 1, fade_in)[:, None]
    stereo[-fade_out:] *= np.linspace(1, 0, fade_out)[:, None] ** 2
    return stereo


def swelling_envelope(t, start, attack, decay):
    elapsed = np.maximum(t - start, 0)
    return (t >= start) * (1 - np.exp(-elapsed / attack))**2 * np.exp(-elapsed / decay)


def synthesize(variant):
    name, label, kind, duration, pitch, glow, air, seed = variant
    rng = np.random.default_rng(seed)
    t = np.arange(round(duration * RATE)) / RATE
    if kind == 'resist':
        return synthesize_resist(t, pitch, glow, air, rng, seed)
    if kind in ('miss', 'absorb'):
        return synthesize_other_miss(t, pitch, glow, air, rng, kind)
    critical = kind == 'crit'
    # Measured WoW launch sounds swell for 130–250 ms instead of peaking at
    # 20 ms. Layer a longer moving whoosh and glide, rather than extending silence.
    attack = 0.068 if critical else 0.055
    decay = 0.29 if critical else 0.22
    swell = swelling_envelope(t, 0.003, attack, decay)
    low_air = noise(rng, len(t), 620 + pitch * 0.45, 400)
    moving_air = noise(rng, len(t), 1200 + pitch * 0.65, 660)
    detail = noise(rng, len(t), 2450, 700)
    motion = 1 / (1 + np.exp(-(t - 0.125) / 0.042))
    flutter = 0.86 + 0.09 * np.sin(2 * np.pi * (7 + seed % 5) * t) + 0.05 * np.sin(2 * np.pi * 23 * t)
    x = 0.18 * air * ((1 - motion) * low_air + motion * moving_air) * swell * flutter
    x += 0.030 * glow * detail * swelling_envelope(t, 0.040, 0.050, decay * 0.80)
    # A quiet early breath gives immediate response; the main energy arrives later.
    x += 0.018 * moving_air * envelope(t, 0, 0.004, 0.026)
    core = harmonic_pulse(t, pitch * 1.30, pitch * 0.73, 0.19)
    x += 0.10 * core * swelling_envelope(t, 0.007, 0.055, decay)
    # A soft traveling tonal double adds depth without inharmonic bell ringing.
    phase = chirp(t, pitch * 1.9, pitch * 0.98, 0.16)
    phase += 0.075 * np.sin(2 * np.pi * 5.7 * t)
    x += 0.027 * glow * np.sin(phase) * swelling_envelope(t, 0.038, 0.048, decay * 0.90)
    body = harmonic_pulse(t, 170 + pitch * 0.12, 125 + pitch * 0.055, 0.13)
    x += (0.090 if critical else 0.035) * body * swelling_envelope(t, 0.014, 0.040, 0.16)
    afterglow = noise(rng, len(t), 860 + pitch * 0.5, 430)
    x += 0.040 * glow * afterglow * swelling_envelope(t, 0.100, 0.047, 0.22 if critical else 0.16)
    if critical:
        bloom = noise(rng, len(t), 1300 + pitch * 0.5, 720)
        x += 0.085 * bloom * swelling_envelope(t, 0.085, 0.055, 0.26)
        local = np.maximum(t - 0.080, 0)
        rounded = harmonic_pulse(local, pitch * 0.85, pitch * 0.59, 0.13)
        x += 0.048 * rounded * swelling_envelope(t, 0.080, 0.045, 0.20)
    return finish_sound(x, kind)


def synthesize_resist(t, pitch, glow, air, rng, seed):
    """A short energy swell that breaks into airy, irregular little puffs."""
    fizz = noise(rng, len(t), 1000 + pitch * 0.4, 570)
    flutter = 0.76 + 0.16 * np.sin(2 * np.pi * (15 + seed % 8) * t)
    # The collapsing gate distinguishes resistance from a completed discharge.
    collapse = 1 / (1 + np.exp((t - 0.21) / 0.027))
    swell = swelling_envelope(t, 0, 0.037, 0.17)
    x = 0.17 * air * fizz * swell * flutter * collapse
    core = harmonic_pulse(t, pitch * 1.0, pitch * 0.38, 0.085)
    x += 0.055 * core * swell * collapse
    x += 0.030 * glow * noise(rng, len(t), 2200, 700) * swelling_envelope(t, 0.017, 0.034, 0.10)
    for i in range(2 + seed % 2):
        start = 0.165 + 0.031 * i
        puff = noise(rng, len(t), 690 + i * 170, 360)
        x += 0.037 * puff * envelope(t, start, 0.006, 0.034)
    return finish_sound(x, 'resist')


def synthesize_other_miss(t, pitch, glow, air, rng, kind):
    """A pass-by for missed shots, a collapsing low-mid swirl for absorption."""
    breath = noise(rng, len(t), 1350 + pitch * 0.4, 680)
    swell = swelling_envelope(t, 0, 0.047, 0.14 if kind == 'miss' else 0.17)
    x = 0.15 * air * breath * swell
    if kind == 'miss':
        passing = harmonic_pulse(t, pitch * 1.7, pitch * 0.45, 0.11)
        x += 0.043 * passing * swell
        x += 0.025 * glow * noise(rng, len(t), 2400, 600) * swell
    else:
        collapse = 1 / (1 + np.exp((t - 0.24) / 0.035))
        body = harmonic_pulse(t, pitch * 0.95, pitch * 0.40, 0.14)
        x = x * collapse + 0.11 * body * swell * collapse
        x += 0.050 * noise(rng, len(t), 720, 380) * swelling_envelope(t, 0.14, 0.036, 0.12)
    return finish_sound(x, kind)


def write_wav(path, samples):
    pcm = np.round(np.clip(samples, -1, 1) * 32767).astype('<i2')
    with wave.open(str(path), 'wb') as output:
        output.setnchannels(2)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm.tobytes())


def encode_ogg(wav_path, destination):
    subprocess.run(['ffmpeg', '-hide_banner', '-loglevel', 'error', '-y', '-i', str(wav_path), '-c:a', 'libvorbis', '-q:a', '5', str(destination)], check=True)


def synthesize_school(variant, school, index):
    name, label, kind, duration, pitch, glow, air, seed = variant
    rng = np.random.default_rng(seed)
    t = np.arange(round(duration * RATE)) / RATE
    critical = kind == 'crit'
    attack = (0.063 if critical else 0.045) + (index % 3) * 0.008
    decay = (0.29 if critical else 0.22) + (index % 2) * 0.022
    if kind in ('resist', 'absorb', 'miss'):
        attack, decay = 0.032 + index * 0.006, 0.17
    swell = swelling_envelope(t, 0.004, attack, decay)
    motion = 1 / (1 + np.exp(-(t - 0.10 - 0.012 * index) / 0.045))
    low = noise(rng, len(t), 700 + pitch * 0.35, 420)
    high = noise(rng, len(t), 1400 + pitch * 0.5, 730)
    x = 0.105 * ((1 - motion) * low + motion * high) * swell
    x += 0.013 * high * envelope(t, 0, 0.004, 0.024)
    # Distinct time gestures inside each bank: one swell, paired puffs, swirl,
    # rounded pulse, delayed trailing breath, and a stronger short discharge.
    gesture = index % 6
    rhythm = np.ones(len(t))
    if gesture == 1:
        rhythm = 0.55 + 0.45 * np.sin(2 * np.pi * 4.8 * t + 0.2)**2
    elif gesture == 2:
        rhythm = 0.72 + 0.28 * np.sin(2 * np.pi * 10.5 * t)
    elif gesture == 3:
        x += 0.08 * low * swelling_envelope(t, 0.05, 0.027, 0.11)
    elif gesture == 4:
        x += 0.07 * high * swelling_envelope(t, 0.20, 0.025, 0.17)
    elif gesture == 5:
        x += 0.085 * high * swelling_envelope(t, 0.015, 0.030, 0.12)
    x *= rhythm
    core = harmonic_pulse(t, pitch * 1.22, pitch * 0.75, 0.16 + index * 0.012)
    detail = noise(rng, len(t), 2700, 780)
    if school == 'shadow':
        whisper = noise(rng, len(t), 1450, 500)
        undertow = noise(rng, len(t), 530, 220)
        flutter = 0.75 + 0.18 * np.sin(2 * np.pi * (9 + index) * t)
        x += 0.13 * whisper * swell * flutter + 0.075 * undertow * swell
        x += 0.070 * core * swell + 0.026 * detail * swell
        x += 0.044 * whisper * swelling_envelope(t, 0.14, 0.06, 0.23)
    elif school == 'fire':
        flame = noise(rng, len(t), 1950, 960)
        x += 0.11 * flame * swell * (0.80 + 0.20 * np.sin(2 * np.pi * 13 * t))
        x += 0.036 * core * swell
        # Random soft microbursts produce a fire texture without metal clicks.
        for _ in range(9 + 2 * index):
            start = rng.uniform(0.05, min(duration - 0.12, 0.52))
            spark = noise(rng, len(t), rng.uniform(1800, 3300), 650)
            x += rng.uniform(0.010, 0.027) * spark * envelope(t, start, 0.004, rng.uniform(0.015, 0.034))
        x += 0.050 * low * swelling_envelope(t, 0.04, 0.045, 0.18)
    elif school == 'frost':
        ice_air = noise(rng, len(t), 2550, 750)
        x += 0.087 * ice_air * swell + 0.040 * core * swell
        phase = chirp(t, pitch * 1.65, pitch * 1.20, 0.19)
        x += 0.035 * np.sin(phase) * swelling_envelope(t, 0.022, 0.045, 0.21)
        # Airy ice grains, rounded instead of ringing crystalline percussion.
        for i in range(4 + index % 3):
            x += 0.032 * detail * envelope(t, 0.09 + i * 0.058, 0.013, 0.028)
    elif school == 'arcane':
        elastic = np.sin(chirp(t, pitch * 1.7, pitch * 0.67, 0.18)
                         + 0.20 * np.sin(2 * np.pi * 6.2 * t))
        x += 0.10 * core * swell + 0.050 * elastic * swell
        x += 0.050 * detail * swelling_envelope(t, 0.06, 0.052, 0.20)
        x += 0.055 * high * swell * (0.75 + 0.25 * np.sin(2 * np.pi * 8 * t))
    elif school == 'nature':
        gust = noise(rng, len(t), 900, 450)
        charge = noise(rng, len(t), 2150, 900)
        x += 0.10 * gust * swell + 0.038 * core * swell
        x += 0.067 * charge * swell * (0.45 + 0.55 * np.sin(2 * np.pi * (17 + index) * t)**4)
        for i in range(3 + index % 3):
            x += 0.025 * charge * envelope(t, 0.11 + i * 0.045, 0.008, 0.025)
    elif school == 'holy':
        # Consonant soft glow with an open breath, not a struck bell.
        phase = chirp(t, pitch * 1.10, pitch * 0.91, 0.24)
        glow_tone = np.sin(phase) + 0.22 * np.sin(1.5 * phase) + 0.12 * np.sin(2 * phase)
        x += 0.10 * glow_tone * swelling_envelope(t, 0.013, 0.068, 0.26)
        x += 0.063 * detail * swell + 0.030 * high * swelling_envelope(t, 0.12, 0.055, 0.24)
    if critical:
        x += 0.082 * low * swelling_envelope(t, 0.018, 0.043, 0.20)
        x += 0.072 * high * swelling_envelope(t, 0.10, 0.053, 0.26)
        x += 0.035 * detail * swelling_envelope(t, 0.18, 0.040, 0.20)
    elif kind == 'resist':
        x *= 1 / (1 + np.exp((t - 0.21 - index * 0.012) / 0.023))
        x += 0.045 * high * envelope(t, 0.20 + index * 0.008, 0.008, 0.045)
        x += 0.026 * low * envelope(t, 0.26, 0.010, 0.030)
    elif kind == 'absorb':
        x *= 1 / (1 + np.exp((t - 0.24) / 0.035))
        x += 0.065 * low * swelling_envelope(t, 0.14, 0.035, 0.12)
    elif kind == 'miss':
        x *= 0.75
        x += 0.060 * high * swelling_envelope(t, 0.07, 0.032, 0.13)
    return finish_sound(x, kind)


def make_player(manifest, demo_bytes):
    cards = []
    for item in manifest:
        data = base64.b64encode((ROOT / item['file']).read_bytes()).decode('ascii')
        cards.append(f'<article data-school="{item["school"]}"><span>{KIND_LABELS[item["kind"]]} · {item["duration"]:.2f} s</span><h2>{html.escape(item["name"])}</h2><audio data-kind="{item["kind"]}" data-school="{item["school"]}" controls preload="none" src="data:audio/ogg;base64,{data}"></audio></article>')
    options = ''.join(f'<option value="{key}">{label}</option>' for key, label, *_ in SCHOOLS)
    options += '<option value="neutral">Unbekannte Schadensart</option>'
    demo = base64.b64encode(demo_bytes).decode('ascii')
    return f'''<!doctype html><html lang="de"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Gabba Zauberstab-Sounds v0.6</title><style>
body{{font-family:system-ui;background:#111321;color:#eeeaf8;margin:32px auto;padding:0 24px;max-width:1080px}}p{{color:#bcb4d5;line-height:1.6}}section{{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:16px}}article{{background:#1e2137;border:1px solid #363b60;border-radius:14px;padding:20px}}article[hidden]{{display:none}}audio{{width:100%}}span{{color:#ae9bff;font-size:13px}}button,select{{background:#b9a6ff;color:#171329;border:0;border-radius:8px;padding:10px;font:inherit;margin:8px 4px 18px 0;cursor:pointer}}.demo{{max-width:650px;margin-bottom:16px}}
</style><h1>Zauberstab-Sounds · v0.6</h1>
<p>Je Schadensart 6 normale Treffer, 4 Crits und 4 Widerstände, dazu 2 Fehlschläge und 2 Absorptionen. Eigene Klangfamilien für Schatten, Feuer, Frost, Arkan, Natur und Heilig. Die neutrale Reserve wird verwendet, wenn die Schadensart noch unbekannt ist. Alle Sounds eigens synthetisiert.</p>
<label>Schadensart: <select id="school">{options}</select></label><br>
<button data-random="hit">Zufälliger Treffer</button><button data-random="crit">Zufälliger Crit</button><button data-random="resist">Zufälliger Widerstand</button><button data-random="miss">Zufälliger Fehlschlag</button><button data-random="absorb">Zufällige Absorption</button><button id="stop">Stoppen</button>
<details><summary>Gesamte Hörprobe: alle sechs Schadensarten in der Reihenfolge der Auswahl</summary><audio class="demo" controls preload="none" src="data:audio/ogg;base64,{demo}"></audio></details>
<section>{''.join(cards)}</section><script>
const players = [...document.querySelectorAll('audio')];
const school = document.querySelector('#school');
players.forEach(p => p.addEventListener('play', () => players.forEach(other => {{ if (other !== p) other.pause(); }})));
function stop() {{ players.forEach(p => {{ p.pause(); p.currentTime = 0; }}); }}
function filter() {{ stop(); document.querySelectorAll('article').forEach(a => a.hidden = a.dataset.school !== school.value); }}
school.addEventListener('change', filter); filter();
document.querySelector('#stop').addEventListener('click', stop);
const previous = {{}};
document.querySelectorAll('[data-random]').forEach(b => b.addEventListener('click', () => {{
 const kind = b.dataset.random, key = school.value + kind;
 const choices = players.filter(p => p.dataset.kind === kind && p.dataset.school === school.value && p !== previous[key]);
 const selected = choices[Math.floor(Math.random() * choices.length)]; previous[key] = selected;
 selected.currentTime = 0; selected.play().catch(() => {{}});
}}));
</script></html>'''


def main():
    if not shutil.which('ffmpeg'):
        raise SystemExit('ffmpeg is required to encode OGG Vorbis.')
    sounds_dir = ROOT / 'Sounds'
    sounds_dir.mkdir(parents=True, exist_ok=True)
    manifest = []
    demo = [np.zeros((round(RATE * 0.3), 2))]
    work = []
    for school_index, (school, label, mask, pitch, brightness) in enumerate(SCHOOLS):
        for kind in KINDS:
            for index in range(COUNTS[kind]):
                duration = {'hit': 0.79, 'crit': 1.02, 'resist': 0.56, 'miss': 0.62, 'absorb': 0.70}[kind] + (index % 3 - 1) * 0.025
                name = f'{kind}_{school}_{index + 1:02d}'
                variant = (name, f'{label} · {KIND_LABELS[kind]} {index + 1} · {GESTURES[index]}', kind,
                           duration, pitch * (0.84 + 0.062 * index), brightness, 1,
                           10000 + school_index * 1000 + KINDS.index(kind) * 100 + index)
                work.append((variant, school, index))
    work.extend((variant, 'neutral', 0) for variant in VARIANTS)
    with tempfile.TemporaryDirectory(prefix='gabba-wand-') as directory:
        for variant, school, index in work:
            name, label, kind, *_ = variant
            samples = synthesize(variant) if school == 'neutral' else synthesize_school(variant, school, index)
            wav_path = Path(directory) / (name + '.wav')
            write_wav(wav_path, samples)
            destination = sounds_dir / (name + '.ogg')
            encode_ogg(wav_path, destination)
            manifest.append({'name': label, 'school': school, 'file': str(destination.relative_to(ROOT)), 'kind': kind, 'duration': round(len(samples) / RATE, 3), 'sample_rate': RATE, 'channels': 2, 'peak_dbfs': round(20 * np.log10(np.max(np.abs(samples))), 2), 'rms_dbfs': round(20 * np.log10(np.sqrt(np.mean(samples**2))), 2)})
            if school != 'neutral':
                demo.extend([samples, np.zeros((round(RATE * 0.45), 2))])
        write_wav(ROOT / 'Hoerprobe.wav', np.concatenate(demo))
        encode_ogg(ROOT / 'Hoerprobe.wav', ROOT / 'Hoerprobe.ogg')
    (ROOT / 'manifest.json').write_text(json.dumps(manifest, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    lines = ['-- Generated by tools/generate_sounds.py', 'local _, addon = ...', 'addon.schoolOrder = { ' + ', '.join('"' + school[0] + '"' for school in SCHOOLS) + ' }', 'addon.schoolLabels = {']
    for school, label, *_ in SCHOOLS:
        lines.append(f'    {school} = "{label}",')
    lines.extend(['    neutral = "Unbekannt",', '}', 'addon.schoolMasks = {'])
    for school, label, mask, *_ in SCHOOLS:
        lines.append(f'    [{mask}] = "{school}",')
    lines.extend(['}', 'addon.schoolSounds = {'])
    for school in [s[0] for s in SCHOOLS] + ['neutral']:
        lines.append('    ' + school + ' = {')
        for kind in KINDS:
            files = [Path(item['file']).name for item in manifest if item['kind'] == kind and item['school'] == school]
            lines.append('        ' + kind + ' = { ' + ', '.join('"' + file + '"' for file in files) + ' },')
        lines.append('    },')
    lines.extend(['}', '-- Neutral fallback also preserves existing preview API.', 'addon.sounds = addon.schoolSounds.neutral', 'addon.soundDurations = {'])
    for item in manifest:
        lines.append('    ["' + Path(item['file']).name + '"] = ' + str(item['duration']) + ',')
    lines.append('}')
    (ROOT / 'SoundData.lua').write_text('\n'.join(lines) + '\n', encoding='utf-8')
    player = make_player(manifest, (ROOT / 'Hoerprobe.ogg').read_bytes())
    (ROOT / 'Anhoeren.html').write_text(player, encoding='utf-8')
    (ROOT / 'Anhoeren-v0.6.html').write_text(player, encoding='utf-8')
    print(f'Generated {len(manifest)} sounds: 108 school-specific + 18 neutral fallback.')
    for school, *_ in SCHOOLS:
        print(school, {kind: sum(item['kind'] == kind and item['school'] == school for item in manifest) for kind in KINDS})


if __name__ == '__main__':
    main()
