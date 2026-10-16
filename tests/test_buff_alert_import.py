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
from import_buff_alerts import import_recordings, KINDS, PHASES
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

    def test_missing_recordings_fail_before_writing_output(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with patch.object(build_noggenfogger, 'ROOT', root):
                with self.assertRaisesRegex(ValueError, 'Missing recordings'):
                    import_recordings(root)
            self.assertEqual(list(root.iterdir()), [])


if __name__ == '__main__':
    unittest.main()
