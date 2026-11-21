"""Generate small RLE TGA masks for centered rectangular native minimaps."""
from pathlib import Path
from struct import pack

size = 256
destination = Path(__file__).resolve().parents[1] / 'AggeMinimap' / 'Masks'
destination.mkdir(exist_ok=True)

def encode(pixels):
    result = bytearray()
    start = 0
    while start < len(pixels):
        end = start + 1
        while end < min(start + 128, len(pixels)) and pixels[end] == pixels[start]:
            end += 1
        result += bytes([0x80 | (end - start - 1)]) + bytes([pixels[start]]) * 4
        start = end
    return result

for span in range(114, 256, 2):
    margin = (size - span) // 2
    for axis in ('W', 'T'):
        header = bytearray(18)
        header[2], header[16], header[17] = 10, 32, 40
        header[12:16] = pack('<HH', size, size)
        pixels = [255 if margin <= (y if axis == 'W' else x) < size - margin else 0
                  for y in range(size) for x in range(size)]
        data = b''.join(encode(pixels[y * size:(y + 1) * size]) for y in range(size))
        (destination / f'{axis}{span}.tga').write_bytes(header + data)
print('Generated 142 centered rectangular masks (RLE TGA).')
