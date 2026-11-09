"""Check addon manifests and textures using only Python's standard library."""
from pathlib import Path
from struct import unpack_from

root = Path(__file__).resolve().parents[1]
for name in ('AggeMinimap.toc', 'AggeMinimap_Camelot.toc'):
    toc = (root / 'AggeMinimap' / name).read_text(encoding='utf-8')
    lines = toc.splitlines()
    assert '## Interface: 16001' in lines, name
    assert '## Category: Map' in lines, name
    assert r'## IconTexture: Interface\AddOns\AggeMinimap\Icon.tga' in lines, name
    files = [line for line in lines if line and not line.startswith('#')]
    assert files == ['AggeMinimap.lua'], (name, files)
    for filename in files:
        assert (root / 'AggeMinimap' / filename).is_file(), filename

mask = (root / 'AggeMinimap/Square.tga').read_bytes()
assert mask[2] == 2
assert unpack_from('<HH', mask, 12) == (8, 8)
assert mask[16] == 32
assert len(mask) == 274
assert all(value == 255 for value in mask[18:])

icon = (root / 'AggeMinimap/Icon.tga').read_bytes()
assert icon[2] == 2
assert unpack_from('<HH', icon, 12) == (128, 128)
assert icon[16] == 32
assert icon[17] == 40
assert len(icon) == 18 + 128 * 128 * 4

print('PASS: addon manifests, file references, square mask, and icon texture.')
