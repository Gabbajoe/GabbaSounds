"""Measure actual pitch and timing of the same renderer used for shipped clips."""
import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
import build_noggenfogger


class NoggenfoggerAudio(unittest.TestCase):
    def test_pitch_increases_four_semitones_without_speedup_or_original_changes(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            source = root / 'Sounds/test.ogg'
            source.parent.mkdir()
            wave = .10 * np.sin(2 * np.pi * 440 * np.arange(44100) / 44100)
            stereo = np.column_stack((wave, wave)).astype('<f4')
            subprocess.run(['ffmpeg', '-v', 'error', '-f', 'f32le', '-ar', '44100', '-ac', '2',
                            '-i', '-', '-c:a', 'libvorbis', str(source)], input=stereo.tobytes(), check=True)
            digest = hashlib.sha256(source.read_bytes()).hexdigest()
            with patch.object(build_noggenfogger, 'ROOT', root):
                item = build_noggenfogger.render({'file': 'Sounds/test.ogg', 'duration': 1})
            target = root / item['file']
            probe = json.loads(subprocess.check_output(['ffprobe', '-v', 'error', '-show_streams',
                                                       '-of', 'json', str(target)]))['streams'][0]
            self.assertEqual(probe['codec_name'], 'vorbis')
            self.assertEqual(probe['channels'], 2)
            self.assertAlmostEqual(float(probe['duration']), 1, places=4)
            raw = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(target), '-f', 'f32le', '-'])
            signal = np.frombuffer(raw, dtype='<f4').reshape(-1, 2)[:44100].mean(axis=1)
            peak = np.argmax(np.abs(np.fft.rfft(signal * np.hanning(len(signal)))))
            self.assertAlmostEqual(peak, 440 * 2 ** (4 / 12), delta=2)
            self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), digest)
            self.assertEqual(item['source_sha256'], digest)


if __name__ == '__main__':
    unittest.main()
