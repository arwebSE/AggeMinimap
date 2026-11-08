$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Add-Type -AssemblyName System.Drawing
$source = [System.Drawing.Image]::FromFile((Join-Path $root 'assets/AggeMinimap-icon.png'))
$size = 128
$bitmap = [System.Drawing.Bitmap]::new($size, $size)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
try {
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.DrawImage($source, 0, 0, $size, $size)
    # Uncompressed 32-bit BGRA TGA, top-left origin, 8-bit alpha.
    $data = [byte[]]::new(18 + $size * $size * 4)
    $data[2] = 2
    $data[12] = $size
    $data[14] = $size
    $data[16] = 32
    $data[17] = 40
    $offset = 18
    for ($y = 0; $y -lt $size; $y++) {
        for ($x = 0; $x -lt $size; $x++) {
            $pixel = $bitmap.GetPixel($x, $y)
            $data[$offset++] = $pixel.B
            $data[$offset++] = $pixel.G
            $data[$offset++] = $pixel.R
            $data[$offset++] = $pixel.A
        }
    }
    [System.IO.File]::WriteAllBytes((Join-Path $root 'AggeMinimap/Icon.tga'), $data)
} finally { $graphics.Dispose(); $bitmap.Dispose(); $source.Dispose() }
