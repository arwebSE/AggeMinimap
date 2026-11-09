"""Require a versioned tag and matching TOCs before a release upload."""
import os
import re
from pathlib import Path

tag = os.environ['GITHUB_REF_NAME']
match = re.fullmatch(r'v(\d+\.\d+\.\d+(?:-(?:alpha|beta)\.\d+)?)', tag)
if not match:
    raise SystemExit(f'Not a supported release tag: {tag}')
version = match[1]
for filename in ('AggeMinimap.toc', 'AggeMinimap_Camelot.toc'):
    text = (Path('AggeMinimap') / filename).read_text(encoding='utf-8')
    declared = re.search(r'^## Version: (.+)$', text, re.MULTILINE)
    if not declared or declared[1].strip() != version:
        raise SystemExit(f'{filename} does not match tag {tag}')
    if not re.search(r'^## X-Curse-Project-ID: 1792808$', text, re.MULTILINE):
        raise SystemExit(f'{filename} does not target the expected CurseForge project')
print(f'PASS: {tag} matches both manifests and CurseForge project 1792808.')
