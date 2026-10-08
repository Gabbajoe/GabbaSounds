"""Check that pause cutting preserves syllables, channel phase and edges."""
import sys
import os
from pathlib import Path
import unittest

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from import_spoken import split_ranges

ROOT = Path(__file__).resolve().parents[1]
RUNTIME_ONLY = os.environ.get('GABBA_RUNTIME_ONLY') == '1'
PRIVATE_SOURCE = unittest.skipIf(RUNTIME_ONLY, 'Private source WAVs are excluded from the public repository')


class PauseCutting(unittest.TestCase):
    def test_short_gaps_stay_inside_a_sound_and_long_pause_splits(self):
        rate = 1000
        samples = np.zeros((3000, 2))
        samples[200:500] = 0.1
        samples[650:900] = 0.1  # Same sound with an internal syllable gap.
        samples[1700:2100] = 0.1
        ranges = split_ranges(samples, rate, pause_seconds=0.40)
        self.assertEqual(len(ranges), 2)
        self.assertLessEqual(ranges[0][0], 200)
        self.assertGreaterEqual(ranges[0][1], 900)
        self.assertLess(ranges[0][1], ranges[1][0])
        self.assertLessEqual(ranges[1][0], 1700)
        self.assertGreaterEqual(ranges[1][1], 2100)

    def test_silent_or_very_quiet_input_does_not_make_noise_clips(self):
        for level in (0, 0.00001):
            self.assertEqual(split_ranges(np.full((1000, 2), level), 1000), [])

    def test_phase_inverted_channels_and_recording_edges_are_preserved(self):
        samples = np.zeros((1000, 2))
        samples[:300] = [0.1, -0.1]
        samples[800:] = [0.1, -0.1]
        ranges = split_ranges(samples, 1000)
        self.assertEqual(len(ranges), 2)
        self.assertEqual(ranges[0][0], 0)
        self.assertEqual(ranges[1][1], len(samples))

    def test_repeated_sounds_are_split_without_overlapping_the_safety_margins(self):
        samples = np.zeros((1000, 2))
        samples[100:400] = 0.1
        samples[400:420] = 0.012  # Quiet release below the main onset threshold.
        samples[480:500] = 0.012  # Quiet onset of the second repetition.
        samples[500:800] = 0.1
        ranges = split_ranges(samples, 1000)
        self.assertEqual(len(ranges), 2)
        self.assertGreaterEqual(ranges[0][1], 420)
        self.assertLessEqual(ranges[1][0], 480)
        self.assertLessEqual(ranges[0][1], ranges[1][0])
        self.assertLess(ranges[0][1], 500)
        self.assertGreater(ranges[1][0], 400)

    @PRIVATE_SOURCE
    def test_user_recording_is_ten_separate_takes_with_no_shared_samples(self):
        import wave
        source = Path(__file__).resolve().parents[1] / 'spoken' / 'gesammelt.wav'
        with wave.open(str(source), 'rb') as recording:
            rate = recording.getframerate()
            samples = np.frombuffer(recording.readframes(recording.getnframes()), dtype='<i2').reshape(-1, recording.getnchannels()) / 32768
        ranges = split_ranges(samples, rate)
        self.assertEqual(len(ranges), 10)
        self.assertTrue(all(end - start > rate * 0.12 for start, end in ranges))
        self.assertTrue(all(a[1] <= b[0] for a, b in zip(ranges, ranges[1:])))


class CategorizedRecordings(unittest.TestCase):
    def read_recording(self, relative):
        import subprocess
        path = Path(__file__).resolve().parents[1] / relative
        raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(path), '-ar', '44100', '-ac', '2', '-f', 'f32le', '-'])
        return np.frombuffer(raw, dtype='<f4').reshape(-1, 2).astype(float)

    @PRIVATE_SOURCE
    def test_graze_comment_with_an_internal_pause_stays_one_complete_phrase(self):
        samples = self.read_recording('spoken/shared/graze.wav')
        phrases = split_ranges(samples, 44100, pause_seconds=0.60)
        self.assertEqual(len(phrases), 8)
        self.assertLess(phrases[3][0] / 44100, 7)
        self.assertGreater(phrases[3][1] / 44100, 8.5)
        self.assertTrue(all(a[1] <= b[0] for a,b in zip(phrases, phrases[1:])))

    @PRIVATE_SOURCE
    def test_miss_sayings_are_eight_complete_comments(self):
        samples = self.read_recording('spoken/shared/miss.wav')
        phrases = split_ranges(samples, 44100, pause_seconds=0.60)
        self.assertEqual(len(phrases), 8)
        self.assertTrue(all(end - start > 44100 * 0.5 for start,end in phrases))

    @PRIVATE_SOURCE
    def test_every_original_is_unchanged(self):
        import hashlib, json
        manifest = json.loads((ROOT / 'spoken/manifest.json').read_text())
        for source in manifest['sources']:
            self.assertEqual(hashlib.sha256((ROOT / source['file']).read_bytes()).hexdigest(), source['sha256'])

    def test_every_category_has_its_own_clips(self):
        import json
        manifest = json.loads((ROOT / 'spoken/manifest.json').read_text())
        self.assertEqual(manifest['version'], 2)
        self.assertEqual(len(manifest['sources']), 51)
        self.assertEqual(len(manifest['sounds']), 219)
        for source in manifest['sources']:
            clips = [item for item in manifest['sounds'] if item['source'] == source['file']]
            self.assertEqual(len(clips), source['clips'])
            self.assertTrue(all(a['source_end'] <= b['source_start'] for a,b in zip(clips, clips[1:])))
        for weapon, normal, crit in [('wand',16,3),('bow',7,4),('gun',7,4),('frostbolt',7,7),('blade',6,4),('blunt',6,4),('dagger',6,4),('fist',6,4)]:
            bank = manifest['banks'][weapon]
            self.assertEqual(len(bank['hit']), normal)
            self.assertEqual(len(bank['crit']), crit)
            self.assertTrue(set(bank['hit']).isdisjoint(bank['crit']))
            self.assertEqual(bank['miss'], manifest['banks']['wand']['miss'])
            self.assertEqual(bank['graze'], manifest['banks']['wand']['graze'])

    def test_frostbolt_uses_its_own_recordings_and_only_failures_are_shared(self):
        import json
        from import_spoken_library import build_banks
        root = Path(__file__).resolve().parents[1]
        manifest = json.loads((root / 'spoken/manifest.json').read_text())
        for kind in ('hit', 'crit'):
            clips = [item for item in manifest['sounds'] if item['weapon'] == 'frostbolt' and item['kind'] == kind]
            self.assertEqual(len(clips), 7)
            self.assertTrue(all(item['source'] == f'spoken/mage/frostbolt/{kind}.wav' for item in clips))
        without_frost = [item for item in manifest['sounds'] if item['weapon'] != 'frostbolt']
        pending = build_banks(without_frost)['frostbolt']
        self.assertEqual(pending['hit'], [])
        self.assertEqual(pending['crit'], [])
        self.assertEqual(pending['graze'], manifest['banks']['wand']['graze'])

    def test_all_mage_recordings_have_separate_cast_hit_and_crit_pools(self):
        import json
        from import_spoken_library import MAGE_SPELLS, CAST_ONLY
        root = Path(__file__).resolve().parents[1]
        manifest = json.loads((root / 'spoken/manifest.json').read_text())
        for spell in MAGE_SPELLS:
            bank = manifest['banks'][spell]
            self.assertEqual(len(bank['cast']), 3 if spell == 'frostnova' else 2)
            self.assertEqual(len(bank['hit']), 0 if spell in CAST_ONLY else 7 if spell == 'frostbolt' else 5)
            self.assertEqual(len(bank['crit']), 0 if spell in CAST_ONLY or spell == 'blizzard' else 7 if spell == 'frostbolt' else 4)
            for kind in ('cast', 'hit', 'crit'):
                expected_files = {item['file'].split('/')[-1] for item in manifest['sounds'] if item['weapon'] == spell and item['kind'] == kind}
                self.assertEqual(set(bank[kind]), expected_files)
                self.assertTrue(all(item['source'] == f'spoken/mage/{spell}/{kind}.wav' for item in manifest['sounds'] if item['weapon'] == spell and item['kind'] == kind))
            self.assertTrue(set(bank['cast']).isdisjoint(bank['hit']))
            self.assertEqual(bank['miss'], manifest['banks']['wand']['miss'])

    def test_browser_preview_contains_every_mage_spell_and_all_recordings(self):
        import json
        from import_spoken_library import MAGE_SPELLS, build_preview
        root = Path(__file__).resolve().parents[1]
        manifest = json.loads((root / 'spoken/manifest.json').read_text())
        page = build_preview(manifest['sounds'])
        self.assertNotIn('PLACEHOLDER_OPTIONS', page)
        self.assertEqual(page.count('<article '), len(manifest['sounds']))
        for spell in MAGE_SPELLS:
            self.assertIn(f'<option value="{spell}">', page)

    def test_cast_recordings_are_optional_and_have_a_separate_frostbolt_pool(self):
        import json
        from import_spoken_library import build_banks
        root = Path(__file__).resolve().parents[1]
        manifest = json.loads((root / 'spoken/manifest.json').read_text())
        without_cast = [item for item in manifest['sounds'] if item['kind'] != 'cast']
        banks = build_banks(without_cast)
        self.assertEqual(banks['frostbolt']['cast'], [])
        added = without_cast + [{
            'file': 'Sounds/voice_frostbolt_cast_01.ogg', 'weapon': 'frostbolt', 'kind': 'cast'}]
        imported = build_banks(added)
        self.assertEqual(imported['frostbolt']['cast'], ['voice_frostbolt_cast_01.ogg'])
        for kind in ('hit', 'crit', 'miss', 'graze'):
            self.assertEqual(imported['frostbolt'][kind], banks['frostbolt'][kind])
        self.assertTrue(all('cast' not in imported[weapon] for weapon in ('wand', 'bow', 'gun')))
        self.assertTrue(all(imported[weapon]['cast'] == [] for weapon in ('fireball', 'iceblock', 'blizzard')))


class PreviewFiles(unittest.TestCase):
    def test_all_checked_in_previews_link_existing_audio_without_embedding_duplicates(self):
        from html.parser import HTMLParser
        class AudioPaths(HTMLParser):
            def __init__(self):
                super().__init__()
                self.paths = []
            def handle_starttag(self, tag, attrs):
                if tag == 'audio': self.paths.append(dict(attrs)['src'])
        for name, count in [('spoken/index.html', 219), ('melee/index.html', 56),
                            ('magic/index.html', 126), *[(f'melee/{key}.html',26) for key in ('blade','blunt','dagger','fist')]]:
            page = ROOT / 'previews' / name
            parser = AudioPaths()
            parser.feed(page.read_text())
            self.assertEqual(len(parser.paths), count)
            for audio in parser.paths:
                self.assertNotIn('data:', audio)
                self.assertTrue((page.parent / audio).is_file(), audio)


class MeleeCuts(unittest.TestCase):
    def test_reviewed_cuts_are_hash_guarded_and_preserve_short_blade_sound(self):
        import hashlib, json
        from import_spoken_library import reviewed_ranges
        cuts = json.loads((ROOT / 'spoken/melee/cuts.json').read_text())
        self.assertEqual(len(cuts), 8)
        for name, record in cuts.items():
            ranges = record['ranges_seconds']
            self.assertEqual(len(ranges), 6 if name.endswith('/hit.wav') else 4)
            self.assertTrue(all(a[1] <= b[0] for a, b in zip(ranges, ranges[1:])))
            with self.assertRaisesRegex(ValueError, 'Recording changed'):
                reviewed_ranges(name, 'changed', np.zeros((441000, 2)), 0.2)
        self.assertEqual(cuts['spoken/melee/blade/hit.wav']['ranges_seconds'][2], [3.28, 4.0])


if __name__ == '__main__':
    unittest.main()
