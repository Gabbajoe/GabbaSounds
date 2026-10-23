"""Import real fixture audio and verify warning registry, pitch and package integration."""
import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import build_noggenfogger
from build_package import RUNTIME, package_files
from import_buff_alerts import import_recordings, KINDS, PHASES, PRIEST_KINDS
from test_herbalism_preview import recording


class BuffAlertImport(unittest.TestCase):
    def test_import_keeps_sources_and_other_variants_and_packages_all_eight_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in RUNTIME:
                target = root / name
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text('fixture')
            sources = {}
            for kind in KINDS:
                for phase in PHASES:
                    source = root / 'spoken/mage/buffs' / kind / (phase + '.wav')
                    recording(source)
                    sources[source] = hashlib.sha256(source.read_bytes()).hexdigest()
            for name, data in [('manifest.json', []), ('spoken/manifest.json', {'sounds': []})]:
                (root / name).write_text(json.dumps(data))
            (root / 'spoken/herbalism').mkdir()
            (root / 'spoken/herbalism/manifest.json').write_text('{"sounds": []}')
            (root / 'noggenfogger').mkdir()
            existing = {'source_file': 'Sounds/previous.ogg', 'file': 'Sounds/noggenfogger/previous.ogg'}
            (root / existing['file']).parent.mkdir(parents=True)
            (root / existing['file']).write_bytes(b'previous audio remains unchanged')
            pitch = root / 'noggenfogger/manifest.json'
            pitch.write_text(json.dumps({'semitones': 4, 'sounds': [existing]}))
            with patch.object(build_noggenfogger, 'ROOT', root):
                sounds = import_recordings(root)
                import_recordings(root)  # Repeat imports replace, never duplicate, entries.
            self.assertEqual(len(sounds), 4)
            self.assertEqual(len(json.loads(pitch.read_text())['sounds']), 5)
            self.assertEqual(json.loads(pitch.read_text())['sounds'][0], existing)
            files = package_files(root)
            self.assertEqual(sum('voice_buff_' in name for name in files), 8)
            self.assertFalse(any(name.endswith('.wav') or 'previews/' in name for name in files))
            registry = (root / 'BuffAlertSoundData.lua').read_text()
            for item in sounds:
                self.assertIn(Path(item['file']).name, registry)
                self.assertIn('addon.soundDurations[', registry)
                self.assertTrue((root / item['file']).is_file())
            self.assertTrue((root / 'previews/buffs/index.html').is_file())
            for source, digest in sources.items():
                self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), digest)

            # Importing either class must preserve the other class's files and registry.
            for kind in PRIEST_KINDS:
                for phase in PHASES:
                    source = root / 'spoken/priest/buffs' / kind / (phase + '.wav')
                    recording(source)
                    sources[source] = hashlib.sha256(source.read_bytes()).hexdigest()
            mage_audio = {item['file']: (root / item['file']).read_bytes() for item in sounds}
            with patch.object(build_noggenfogger, 'ROOT', root):
                priest_sounds = import_recordings(root, priest=True)
                for name, data in mage_audio.items():
                    self.assertEqual((root / name).read_bytes(), data)
                import_recordings(root)  # A later mage import retains every priest recording.
            self.assertEqual(len(priest_sounds), 8)
            registry = (root / 'BuffAlertSoundData.lua').read_text()
            for item in sounds + priest_sounds:
                self.assertIn(Path(item['file']).name, registry)
                self.assertIn('addon.buffAlertSounds.' + item['buff'] + '.' + item['phase'], registry)
            self.assertEqual(len(json.loads(pitch.read_text())['sounds']), 13)
            self.assertEqual(len(build_noggenfogger.source_sounds(root)), 12)
            self.assertEqual(sum('voice_buff_' in name for name in package_files(root)), 24)
            preview = (root / 'previews/buffs/index.html').read_text()
            self.assertEqual(preview.count('<audio '), 4)
            self.assertNotIn('src="../../Sounds/voice_buff_fortitude_missing.ogg"', preview)

            # Neutral clips have separate sources, filenames and Lua banks.
            personal_audio = {item['file']: (root / item['file']).read_bytes() for item in priest_sounds}
            for kind in PRIEST_KINDS:
                for phase in PHASES:
                    source = root / 'spoken/priest/buffs/generic' / kind / (phase + '.wav')
                    recording(source)
                    sources[source] = hashlib.sha256(source.read_bytes()).hexdigest()
            with patch.object(build_noggenfogger, 'ROOT', root):
                neutral = import_recordings(root, generic=True)
                import_recordings(root, generic=True)  # Stable on repeated neutral imports.
                import_recordings(root, priest=True)  # Personal reimports retain neutral clips.
            self.assertEqual(len(neutral), 8)
            registry = (root / 'BuffAlertSoundData.lua').read_text()
            self.assertTrue(set(item['file'] for item in neutral).isdisjoint(personal_audio))
            for item in neutral:
                expected = 'addon.priestBuffGenericSounds.' + item['buff'] + '.' + item['phase']
                self.assertIn(expected + ' = ' + json.dumps(Path(item['file']).name), registry)
            for name, data in personal_audio.items():
                self.assertEqual((root / name).read_bytes(), data)
            self.assertEqual(len(json.loads(pitch.read_text())['sounds']), 21)
            self.assertEqual(len(build_noggenfogger.source_sounds(root)), 20)
            self.assertEqual(sum('voice_buff_' in name for name in package_files(root)), 40)
            preview = (root / 'previews/buffs/index.html').read_text()
            self.assertEqual(preview.count('<audio '), 12)
            self.assertIn('voice_buff_priest_generic_fortitude_missing.ogg', preview)
            self.assertNotIn('src="../../Sounds/voice_buff_fortitude_missing.ogg"', preview)
            for source, digest in sources.items():
                self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), digest)

    def test_missing_recordings_fail_before_writing_output(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with patch.object(build_noggenfogger, 'ROOT', root):
                for options in ({}, {'priest': True}, {'generic': True}):
                    with self.subTest(options=options):
                        with self.assertRaisesRegex(ValueError, 'Missing recordings'):
                            import_recordings(root, **options)
            self.assertEqual(list(root.iterdir()), [])


if __name__ == '__main__':
    unittest.main()
