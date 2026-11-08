# Release testing

Run `npm ci`, `npm test`, and `./scripts/package.ps1` before tagging a release.

The tests simulate WoW frames. Before promoting the beta to a stable Release, verify the following in the actual Forever client:

- Fresh login and `/reload` show a square map, thin border, and no Lua errors.
- `/amm` opens once, reopens without duplicates, and Escape closes it.
- Both sliders update the layout; values persist after `/reload` and relogging.
- Size extremes and Edit Mode scales keep the map square and controls on one row.
- Header above and below have no excessive gap, wrapping, or overlapping controls.
- Long zone names stay within their allocated area.
- Tracking menu, zone button, clock, calendar, addon compartment, mail, queues, and addon minimap buttons work.
- Wheel and button zoom, map clicks, rotation on/off, zoning, and dungeon maps work.
- Layout updates during combat wait until combat ends without blocked actions.
- Disable and reload restores the default UI.

Do not claim a check passed until it has been performed. Capture screenshots of the final header-above and header-below layouts for the project gallery after visual verification.
