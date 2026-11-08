$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$addon = Join-Path $root 'AggeMinimap'
$dist = Join-Path $root 'dist'
$toc = Get-Content -LiteralPath (Join-Path $addon 'AggeMinimap.toc') -Raw
$camelot = Get-Content -LiteralPath (Join-Path $addon 'AggeMinimap_Camelot.toc') -Raw
if ($toc -cne $camelot) { throw 'The default and Camelot manifests must match.' }
if ($toc -notmatch '(?m)^## Version: ([0-9A-Za-z.-]+)\r?$') { throw 'Missing or invalid addon version.' }
$version = $Matches[1]
$files = @('AggeMinimap.toc', 'AggeMinimap_Camelot.toc', 'AggeMinimap.lua', 'Square.tga')
foreach ($file in $files) {
    if (-not (Test-Path -LiteralPath (Join-Path $addon $file) -PathType Leaf)) { throw "Missing addon file: $file" }
}
New-Item -ItemType Directory -Path $dist -Force | Out-Null
$destination = Join-Path $dist "AggeMinimap-$version.zip"
if (Test-Path -LiteralPath $destination) { Remove-Item -LiteralPath $destination }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::Open($destination, 'Create')
try {
    foreach ($file in $files) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,
            (Join-Path $addon $file), "AggeMinimap/$file") | Out-Null
    }
    foreach ($file in @('LICENSE', 'README.md', 'CHANGELOG.md')) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive,
            (Join-Path $root $file), "AggeMinimap/$file") | Out-Null
    }
} finally { $archive.Dispose() }
Write-Output $destination
