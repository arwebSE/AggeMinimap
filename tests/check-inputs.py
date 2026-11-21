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

crop_files = {path.name: path for path in (root / 'AggeMinimap/Masks').glob('*.tga')}
assert set(crop_files) == {f'{axis}{span}.tga' for axis in ('W', 'T') for span in range(114, 256, 2)}
for name, path in crop_files.items():
    data = path.read_bytes()
    assert data[2] == 10 and data[16:18] == bytes([32, 40])
    assert unpack_from('<HH', data, 12) == (256, 256)
    pixels, offset = bytearray(), 18
    while offset < len(data):
        packet = data[offset]
        assert packet & 128, name
        pixels.extend(data[offset + 1:offset + 5] * ((packet & 127) + 1))
        offset += 5
    assert len(pixels) == 256 * 256 * 4
    filled = [index for index, alpha in enumerate(pixels[3::4]) if alpha == 255]
    span = int(name[1:-4])
    margin = (256 - span) // 2
    bounds = (min(i % 256 for i in filled), min(i // 256 for i in filled),
              max(i % 256 for i in filled), max(i // 256 for i in filled))
    expected = (0, margin, 255, 255 - margin) if name[0] == 'W' else (margin, 0, 255 - margin, 255)
    assert bounds == expected and len(filled) == span * 256, name

print('PASS: addon manifests, icon, square mask, and all centered rectangle masks.')
