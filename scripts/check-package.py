"""Check the archive created by the external addon packager."""
from pathlib import Path
from zipfile import ZipFile

archives = list(Path('.release').glob('*.zip'))
assert len(archives) == 1, f'Expected one ZIP, found {archives}'
expected = {
    'AggeMinimap/AggeMinimap.toc',
    'AggeMinimap/AggeMinimap_Camelot.toc',
    'AggeMinimap/AggeMinimap.lua',
    'AggeMinimap/Icon.tga',
    'AggeMinimap/Square.tga',
    'AggeMinimap/LICENSE',
    'AggeMinimap/README.md',
    'AggeMinimap/CHANGELOG.md',
}
with ZipFile(archives[0]) as archive:
    files = {name for name in archive.namelist() if not name.endswith('/')}
    assert files == expected, f'Unexpected package contents: {files ^ expected}'
    for name in expected:
        relative = Path(name)
        source = relative if relative.exists() else Path(relative.name)
        # Packagers may normalize text line endings, but must preserve content.
        packaged = archive.read(name)
        original = source.read_bytes()
        if source.suffix == '.tga':
            assert packaged == original, f'Texture changed: {name}'
        else:
            assert packaged.replace(b'\r\n', b'\n') == original.replace(b'\r\n', b'\n'), name
print('PASS: external package contains exactly the installable addon and release documents.')
