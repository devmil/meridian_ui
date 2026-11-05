#!/usr/bin/env python3
"""Verify bundled Mono source bytes, licence and native weight metadata."""
import hashlib
import json
from pathlib import Path
import struct

root = Path(__file__).resolve().parents[1] / 'assets/fonts'
manifest = json.loads((root / 'sources.json').read_text())
expected = {
    'JetBrainsMono-Regular.ttf': 400,
    'JetBrainsMono-Medium.ttf': 500,
    'JetBrainsMono-Bold.ttf': 700,
    'OFL.txt': None,
}
if {entry['file'] for entry in manifest['assets']} != set(expected):
    raise SystemExit('fonts.manifest_mismatch')
for entry in manifest['assets']:
    data = (root / entry['file']).read_bytes()
    if len(data) != entry['bytes'] or hashlib.sha256(data).hexdigest() != entry['sha256']:
        raise SystemExit('fonts.asset_drift')
    weight = expected[entry['file']]
    if weight is None:
        if b'SIL OPEN FONT LICENSE' not in data:
            raise SystemExit('fonts.licence_missing')
        continue
    count = struct.unpack_from('>H', data, 4)[0]
    tables = {
        data[12 + index * 16:16 + index * 16]:
        struct.unpack_from('>II', data, 20 + index * 16)
        for index in range(count)
    }
    offset, length = tables[b'OS/2']
    if length < 6 or offset + length > len(data) or struct.unpack_from('>H', data, offset + 4)[0] != weight:
        raise SystemExit('fonts.weight_mismatch')
print('fonts.integrity_passed weights=400,500,700')
