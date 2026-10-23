"""Verify real herb audio import, private sources, preserved buff clips and ZIP coverage."""
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
from import_herbalism import import_recordings
from preview_herbalism import HERBS, build_previews
from test_herbalism_preview import recording


class HerbalismImport(unittest.TestCase):
    def test_import_preserves_sources_and_other_audio_and_covers_normal_and_pitched_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in RUNTIME:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('fixture')
            sources = {}
            for key in HERBS:
                source = root / 'spoken/herbalism' / (key + '.wav')
                recording(source)
                sources[source] = hashlib.sha256(source.read_bytes()).hexdigest()
            (root / 'spoken/mage/buffs').mkdir(parents=True)
            for name, data in [('manifest.json', []), ('spoken/manifest.json', {'sounds': []}),
                               ('spoken/mage/buffs/manifest.json', {'sounds': []})]:
                (root / name).write_text(json.dumps(data))
            (root / 'noggenfogger').mkdir()
            existing = {'source_file': 'Sounds/buff.ogg', 'file': 'Sounds/noggenfogger/buff.ogg'}
            (root / existing['file']).parent.mkdir(parents=True)
            (root / existing['file']).write_bytes(b'existing buff stays unchanged')
            pitch = root / 'noggenfogger/manifest.json'
            pitch.write_text(json.dumps({'semitones': 4, 'sounds': [existing]}))
            with patch.object(build_noggenfogger, 'ROOT', root):
                sounds = import_recordings(root)
                import_recordings(root)
            self.assertEqual(len(sounds), 2)
            self.assertEqual(len(json.loads(pitch.read_text())['sounds']), 3)
            self.assertEqual(json.loads(pitch.read_text())['sounds'][0], existing)
            self.assertEqual(sum('voice_herb_' in name for name in package_files(root)), 4)
            registry = (root / 'HerbSoundData.lua').read_text()
            for item in sounds:
                self.assertIn(Path(item['file']).name, registry)
                self.assertIn('addon.soundDurations[', registry)
            page = root / 'previews/herbalism/index.html'
            original_page = page.read_text()
            build_previews(root)
            self.assertEqual(page.read_text(), original_page, 'The old preview command must preserve runtime audio links')
            for source, digest in sources.items():
                self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), digest)
            self.assertFalse(any(name.endswith('.wav') or 'previews/' in name for name in package_files(root)))

    def test_missing_recordings_fail_before_writing_outputs(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with patch.object(build_noggenfogger, 'ROOT', root):
                with self.assertRaisesRegex(ValueError, 'Missing recordings'):
                    import_recordings(root)
            self.assertEqual(list(root.iterdir()), [])


if __name__ == '__main__':
    unittest.main()
