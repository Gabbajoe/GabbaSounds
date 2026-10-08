#!/usr/bin/env python3
"""Build the public listening site from an explicit set of pages and shipped OGGs."""
import argparse
from html.parser import HTMLParser
from pathlib import Path
import shutil
from urllib.parse import unquote, urlsplit

from build_package import ROOT, package_files

PAGES = (
    'previews/index.html', 'previews/spoken/index.html',
    'previews/melee/index.html', 'previews/melee/blade.html',
    'previews/melee/blunt.html', 'previews/melee/dagger.html',
    'previews/melee/fist.html', 'previews/magic/index.html',
)


class Links(HTMLParser):
    def __init__(self):
        super().__init__()
        self.urls = []

    def handle_starttag(self, tag, attrs):
        self.urls.extend(value for key, value in attrs
                         if key in ('src', 'href') and value)


def validate_links(site):
    for page in site.rglob('*.html'):
        links = Links()
        links.feed(page.read_text(encoding='utf-8'))
        for url in links.urls:
            parsed = urlsplit(url)
            if parsed.scheme or parsed.netloc or not parsed.path:
                continue
            target = (page.parent / unquote(parsed.path)).resolve()
            if not target.is_relative_to(site.resolve()) or not target.is_file():
                raise ValueError(f'Broken site link in {page.relative_to(site)}: {url}')


def build_site(root, output):
    # Refuse existing output, so old recordings or other assets cannot leak in.
    if output.exists():
        raise ValueError(f'Output already exists; choose an empty destination: {output}')
    files = list(PAGES) + ['curseforge/logo.png']
    files += [name for name in package_files(root) if name.endswith('.ogg')]
    for name in files:
        source = root / name
        if source.is_symlink() or not source.resolve().is_relative_to(root.resolve()):
            raise ValueError(f'Site source escapes checkout: {name}')
        if not source.is_file():
            raise ValueError(f'Missing site source: {name}')
    for name in files:
        target = output / name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(root / name, target)
    # Keep the same directory structure online and when opening previews locally.
    landing = (root / 'previews/index.html').read_text(encoding='utf-8')
    landing = landing.replace('href="', 'href="previews/')
    landing = landing.replace('src="../curseforge/', 'src="curseforge/')
    (output / 'index.html').write_text(landing, encoding='utf-8')
    (output / '.nojekyll').touch()
    validate_links(output)
    return len(files) + 2


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path, default=ROOT / 'dist/site')
    args = parser.parse_args()
    print(f'Built listening site: {build_site(ROOT, args.output_dir)} files in {args.output_dir}')


if __name__ == '__main__':
    main()
