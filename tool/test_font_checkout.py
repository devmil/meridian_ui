#!/usr/bin/env python3
"""Require exact reviewed font/notice bytes under Git CRLF checkout policy."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class FontCheckout(unittest.TestCase):
    def test_clean_crlf_checkout_preserves_manifest_bytes(self):
        # An isolated real repository verifies candidate attributes even before
        # committing. It retains reviewed files verbatim; no developer Git state.
        with tempfile.TemporaryDirectory(prefix='meridian-font-checkout-') as folder:
            root = Path(folder)
            subprocess.run(['git', 'init', '--quiet', str(root)], check=True)
            subprocess.run(['git', '-C', str(root), 'config', 'core.autocrlf', 'true'], check=True)
            (root / '.gitattributes').write_bytes((ROOT / '.gitattributes').read_bytes())
            fonts = root / 'assets/fonts'
            fonts.mkdir(parents=True)
            manifest = json.loads((ROOT / 'assets/fonts/sources.json').read_text())
            for entry in manifest['assets']:
                (fonts / entry['file']).write_bytes((ROOT / 'assets/fonts' / entry['file']).read_bytes())
            subprocess.run(['git', '-C', str(root), 'add', '.'], check=True, capture_output=True)
            # Checkout-index regenerates the files from the index using the real
            # attributes/policy after deleting the original working copies.
            for entry in manifest['assets']:
                (fonts / entry['file']).unlink()
            subprocess.run(['git', '-C', str(root), 'checkout-index', '--all', '--force'], check=True)
            for entry in manifest['assets']:
                with self.subTest(asset=entry['file']):
                    data = (fonts / entry['file']).read_bytes()
                    self.assertEqual(len(data), entry['bytes'])
                    self.assertEqual(hashlib.sha256(data).hexdigest(), entry['sha256'])


if __name__ == '__main__':
    unittest.main()
