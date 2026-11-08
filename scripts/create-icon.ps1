$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$assets = Join-Path (Split-Path -Parent $PSScriptRoot) 'assets'
New-Item -ItemType Directory -Path $assets -Force | Out-Null
$bitmap = [System.Drawing.Bitmap]::new(400, 400)
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$background = [System.Drawing.ColorTranslator]::FromHtml('#111820')
$grid = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml('#293945'), 2)
$outline = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml('#D9E5EB'), 5)
$route = [System.Drawing.Pen]::new([System.Drawing.ColorTranslator]::FromHtml('#54CDB1'), 8)
$marker = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#54CDB1'))
$text = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#D9E5EB'))
$font = [System.Drawing.Font]::new('Segoe UI', 27, [System.Drawing.FontStyle]::Bold)
$format = [System.Drawing.StringFormat]::new()
$format.Alignment = [System.Drawing.StringAlignment]::Center
try {
    $graphics.Clear($background)
    foreach ($line in @(140, 220)) {
        $graphics.DrawLine($grid, $line, 60, $line, 300)
        $graphics.DrawLine($grid, 60, $line, 300, $line)
    }
    $graphics.DrawRectangle($outline, 60, 60, 240, 240)
    $points = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new(85, 265), [System.Drawing.PointF]::new(140, 210),
        [System.Drawing.PointF]::new(210, 210), [System.Drawing.PointF]::new(250, 150))
    $graphics.DrawLines($route, $points)
    $triangle = [System.Drawing.PointF[]]@(
        [System.Drawing.PointF]::new(261, 114), [System.Drawing.PointF]::new(232, 161),
        [System.Drawing.PointF]::new(274, 157))
    $graphics.FillPolygon($marker, $triangle)
    $graphics.DrawString('AM', $font, $text, [System.Drawing.RectangleF]::new(0, 321, 400, 60), $format)
    $bitmap.Save((Join-Path $assets 'AggeMinimap-icon.png'), [System.Drawing.Imaging.ImageFormat]::Png)
} finally {
    $format.Dispose(); $font.Dispose(); $text.Dispose(); $marker.Dispose()
    $route.Dispose(); $outline.Dispose(); $grid.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
}
