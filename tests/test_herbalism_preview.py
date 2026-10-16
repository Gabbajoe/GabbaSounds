"""Exercise the actual WAV-to-preview path without private voice recordings."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
import wave

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from preview_herbalism import HERBS, RATE, build_previews, encode


def recording(path, silent=False):
    path.parent.mkdir(parents=True, exist_ok=True)
    tone = .12 * np.sin(2 * np.pi * 440 * np.arange(round(.7 * RATE)) / RATE)
    signal = np.concatenate((np.zeros(round(.2 * RATE)), tone, np.zeros(round(.3 * RATE))))
    if silent:
        signal *= 0
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes((signal * 32767).astype('<i2').tobytes())


class HerbalismPreviews(unittest.TestCase):
    def test_previews_trim_silence_preserve_sources_and_decode_as_stereo_vorbis(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            hashes = {}
            for key in HERBS:
                source = root / 'spoken/herbalism' / (key + '.wav')
                recording(source)
                hashes[source] = hashlib.sha256(source.read_bytes()).hexdigest()
            page = build_previews(root)
            items = json.loads((page.parent / 'manifest.json').read_text())
            self.assertEqual(len(items), 2)
            for item in items:
                path = page.parent / item['file']
                self.assertIn('src="' + path.name + '"', page.read_text())
                probe = json.loads(subprocess.check_output(['ffprobe', '-v', 'error',
                                  '-show_streams', '-of', 'json', str(path)]))['streams'][0]
                self.assertEqual(probe['codec_name'], 'vorbis')
                self.assertEqual(probe['channels'], 2)
                self.assertAlmostEqual(float(probe['duration']), item['duration'], places=4)
                self.assertLess(item['duration'], 1)
                self.assertGreater(item['duration'], .7)
                raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(path), '-f', 'f32le', '-'])
                samples = np.frombuffer(raw, dtype='<f4')
                self.assertTrue(np.isfinite(samples).all())
                self.assertLess(float(np.max(np.abs(samples))), .9)
                self.assertGreater(float(np.sqrt(np.mean(samples ** 2))), .04)
            for source, digest in hashes.items():
                self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), digest)
            self.assertFalse((root / 'Sounds').exists(), 'Previews must not modify the runtime sound library')

    def test_missing_sources_and_silence_do_not_create_fake_audio(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            with self.assertRaisesRegex(ValueError, 'Missing recordings'):
                build_previews(root)
            self.assertFalse((root / 'previews').exists())
            source, destination = root / 'silent.wav', root / 'silent.ogg'
            recording(source, silent=True)
            with self.assertRaisesRegex(ValueError, 'No audible phrase'):
                encode(source, destination)
            self.assertFalse(destination.exists())


if __name__ == '__main__':
    unittest.main()
