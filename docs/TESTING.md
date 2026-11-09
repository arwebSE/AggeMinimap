# Release testing

Install Lua 5.1 (interpreter and compiler), Python 3, and PowerShell 7. Run the following from the repository root before tagging a release. On systems with versioned executable names, substitute `lua5.1` and `luac5.1` for `lua` and `luac`.

```sh
luac -p AggeMinimap/AggeMinimap.lua tests/runtime.lua
lua tests/runtime.lua
lua tests/runtime.lua delayed
python tests/check-inputs.py
python tests/check-release.py
pwsh -File scripts/package.ps1
```

The behavior tests and simulated WoW environment are written in `tests/runtime.lua` and run in separate Lua processes for normal and delayed minimap loading. Syntax checks use the native Lua 5.1 compiler. Python checks manifest and texture inputs, release guards, and packaged archive contents; it requires no third-party libraries. CI uses the same checks and also verifies the external CurseForge packager output with `python3 scripts/check-package.py`.

The tests simulate WoW frames. Before promoting the beta to a stable Release, verify the following in the actual Forever client:

- Fresh login and `/reload` show a square map, thin border, and no Lua errors.
- `/amm` opens once, reopens without duplicates, and Escape closes it.
- Right-clicking the minimap opens the same settings window; left-click and wheel zoom still work.
- All four sun/moon corners and zoom edges work, persist after reload, and stay synchronized between settings views.
- All three sliders update the layout; dimensions, spacing, and aspect-link state persist after `/reload` and relogging.
- New profiles start at 200 × 200 with linked dimensions and 0 spacing; upgrades preserve the old saved square size.
- Unlinked sliders resize independently; re-linking preserves current proportions, including at either dimension's bounds.
- Size extremes and Edit Mode scales preserve dimensions and keep header controls on one row.
- Negative spacing overlaps the header without shrinking Edit Mode bounds inside the map, with the header above and below.
- Header above and below have no excessive gap, wrapping, or overlapping controls.
- Long zone names stay within their allocated area.
- Tracking menu, zone button, clock, calendar, addon compartment, mail, queues, and addon minimap buttons work.
- Wheel and button zoom, map clicks, rotation on/off, zoning, and dungeon maps work.
- Zoom buttons and their hover area stay on the selected edge, and the sun/moon stays in the selected corner, across rectangular sizes, Edit Mode scales, and header positions.
- Layout updates during combat wait until combat ends without blocked actions.
- Disable and reload restores the default UI.

Do not claim a check passed until it has been performed. Capture screenshots of the final header-above and header-below layouts for the project gallery after visual verification.
