"""Check packaging across checkout names and upload metadata without network writes."""
import hashlib
import json
from pathlib import Path
import shutil
import sys
import tempfile
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from build_package import ROOT, RUNTIME, build, package_files, version
from upload_curseforge import metadata, multipart

CURRENT_TAG = 'v' + version(ROOT)


class ReleaseTools(unittest.TestCase):
    def test_archive_is_reproducible_and_keeps_addon_folder_for_renamed_checkout(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            checkout = base / 'arbitrary-github-checkout-name'
            for name in package_files():
                destination = checkout / name
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copyfile(ROOT / name, destination)
            (checkout / 'spoken').mkdir(exist_ok=True)
            shutil.copyfile(ROOT / 'manifest.json', checkout / 'manifest.json')
            shutil.copyfile(ROOT / 'spoken/manifest.json', checkout / 'spoken/manifest.json')
            release, archive, checksum, count = build(checkout, base / 'dist', CURRENT_TAG)
            first = archive.read_bytes()
            with zipfile.ZipFile(archive) as package:
                names = package.namelist()
                self.assertEqual(count, len(names))
                self.assertTrue(all(name.startswith('GabbaSounds/') for name in names))
                self.assertEqual(sum(name.endswith('.ogg') for name in names), 345)
                self.assertTrue(all('/tools/' not in name and not name.endswith('.wav') for name in names))
            for name in RUNTIME:
                (checkout / name).touch()
            build(checkout, base / 'dist', CURRENT_TAG)
            self.assertEqual(first, archive.read_bytes())
            self.assertEqual(checksum.read_text().split()[0], hashlib.sha256(first).hexdigest())

    def test_wrong_tag_fails_before_creating_an_archive(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / 'dist'
            with self.assertRaisesRegex(ValueError, 'does not match'):
                build(ROOT, output, 'v9.9.9')
            self.assertFalse(output.exists())

    def test_manifest_cannot_add_paths_outside_addon(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'spoken').mkdir()
            for name in RUNTIME:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_bytes(b'test')
            (root / 'manifest.json').write_text(json.dumps([{'file': '../secret.txt'}]))
            (root / 'spoken/manifest.json').write_text('{"sounds": []}')
            with self.assertRaisesRegex(ValueError, 'Unsafe package path'):
                package_files(root)

    def test_upload_uses_exact_classic_version_and_rejects_ambiguous_match(self):
        data = metadata(ROOT, CURRENT_TAG, 'Changes', [{'id': 123, 'name': '1.15.9'}, {'id': 999, 'name': '12.0.0'}])
        self.assertEqual(data['gameVersions'], [123])
        self.assertEqual(data['releaseType'], 'release')
        for entries in ([], [{'id': 1, 'name': '1.15.9'}, {'id': 2, 'name': '1.15.9'}]):
            with self.assertRaisesRegex(ValueError, 'one exact'):
                metadata(ROOT, CURRENT_TAG, 'Changes', entries)
        with self.assertRaisesRegex(ValueError, 'does not match'):
            metadata(ROOT, 'v9.9.9', 'Changes', [])

    def test_upload_multipart_contains_original_zip_and_markdown_metadata(self):
        with tempfile.TemporaryDirectory() as directory:
            archive = Path(directory) / 'GabbaSounds-1.0.0.zip'
            archive.write_bytes(b'PK\x03\x04original ZIP bytes')
            body, content_type = multipart({'changelog': 'First\nSecond', 'changelogType': 'markdown'}, archive)
            self.assertIn(archive.read_bytes(), body)
            self.assertIn(b'name="metadata"', body)
            self.assertIn(b'name="file"; filename="GabbaSounds-1.0.0.zip"', body)
            self.assertIn(b'First\\nSecond', body)
            boundary = content_type.split('boundary=')[1].encode()
            self.assertTrue(body.endswith(b'--' + boundary + b'--\r\n'))


if __name__ == '__main__':
    unittest.main()
