"""Exercise the upload guard without publishing any files."""
import os
import re
import subprocess
import sys
from pathlib import Path

toc = Path('AggeMinimap/AggeMinimap.toc').read_text(encoding='utf-8')
version = re.search(r'^## Version: (.+)$', toc, re.MULTILINE)[1].strip()
for tag, expected in (
    (f'v{version}', 0),
    ('v0.0.0', 1),
    ('main', 1),
    ('v1.2.4; echo unexpected', 1),
):
    env = dict(os.environ, GITHUB_REF_NAME=tag)
    result = subprocess.run(
        [sys.executable, 'scripts/check-release.py'],
        env=env, capture_output=True, text=True,
    )
    assert result.returncode == expected, (tag, result.stdout, result.stderr)
print('PASS: release guard accepts the installed version and rejects mismatched or invalid tags.')
