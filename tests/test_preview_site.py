"""Verify the hosted listening site and its separation from the addon package."""
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from build_preview_site import ROOT, build_site, validate_links
from build_package import package_files


class PreviewSite(unittest.TestCase):
    def test_site_links_resolve_and_only_public_assets_are_shipped(self):
        with tempfile.TemporaryDirectory() as directory:
            site = Path(directory) / 'site'
            count = build_site(ROOT, site)
            files = {p.relative_to(site).as_posix() for p in site.rglob('*') if p.is_file()}
            self.assertEqual(count, len(files))
            self.assertEqual(sum(n.endswith('.ogg') for n in files), 345)
            self.assertEqual(sum(n.endswith('.html') for n in files), 9)
            self.assertFalse(any(n.endswith('.wav') or '/archive/' in n for n in files))
            self.assertTrue(all(n.endswith(('.ogg', '.html')) or n in
                                ('.nojekyll', 'curseforge/logo.png') for n in files))
            self.assertNotIn('previews/index.html', package_files(ROOT))
            # A missing audio asset must fail the same check used during deployment.
            next(site.rglob('*.ogg')).unlink()
            with self.assertRaisesRegex(ValueError, 'Broken site link'):
                validate_links(site)

    def test_existing_output_is_rejected_instead_of_publishing_stale_files(self):
        with tempfile.TemporaryDirectory() as directory:
            site = Path(directory)
            (site / 'private.wav').write_bytes(b'private recording')
            with self.assertRaisesRegex(ValueError, 'Output already exists'):
                build_site(ROOT, site)


if __name__ == '__main__':
    unittest.main()
