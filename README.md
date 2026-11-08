# AggeMinimap

A clean, square minimap for **World of Warcraft: Forever (Camelot)**.

## Features

- Square map with equal width and height and a thin charcoal border.
- Compact, single-row header above or below the map: tracking, zone name, clock, calendar, and addon compartment.
- `/amm` and **Options → AddOns → AggeMinimap** offer the same two sliders: **Map size** (160–360 UI pixels) and **Spacing** (0–40 UI pixels).
- A short login/reload message reminds you of the `/amm` command.
- Project icon and Maps category in the in-game AddOns list.
- Native zoom, map clicks, tracking, mail, and minimap buttons remain available.
- Blizzard Edit Mode controls position, additional scaling, and header placement.
- No external libraries or polling timers.

The map is square; the full Edit Mode selection also includes the header row. Long zone names are clipped to the space available between the controls. Changes made during combat apply when combat ends. Size and spacing are saved account-wide.

## Install

1. Download **AggeMinimap-*.zip** from [Releases](https://github.com/arwebSE/AggeMinimap/releases). GitHub's automatic **Source code** archives are for development.
2. Extract the ZIP into your **Forever client's** `Interface/AddOns` folder.
3. Restart WoW after first installation and enable **AggeMinimap** in the AddOns list.

The folder structure should include:

```text
Interface/AddOns/AggeMinimap/AggeMinimap.toc
Interface/AddOns/AggeMinimap/AggeMinimap_Camelot.toc
Interface/AddOns/AggeMinimap/AggeMinimap.lua
Interface/AddOns/AggeMinimap/Square.tga
Interface/AddOns/AggeMinimap/Icon.tga
```

Disable other minimap skins, including DejaMinimap, to avoid competing layout changes. Updating an existing installation normally requires `/reload`. If upgrading from the early `AggeMiniMap` spelling, replace the old folder and restart WoW once. Disable the addon and reload to restore Blizzard's layout.

## Compatibility and beta status

Targets **Forever interface 16001** with default and Camelot TOCs. Other WoW clients are not supported. Future client changes may require updates.

**The latest layout is a beta and has not completed in-game visual verification.** Automated checks run the Lua in a simulated frame environment; they do not replace testing in WoW. Earlier versions were tried in-game and their layout issues informed this update.

Report issues at [GitHub Issues](https://github.com/arwebSE/AggeMinimap/issues), including your client build, addon version, other minimap addons, header placement, and a screenshot if relevant.

## Development

Requires Node.js and PowerShell 7 for the release build.

```powershell
npm ci
npm test
./scripts/package.ps1
```

Tests check Lua 5.1 syntax, manifests, mask, load order, rotation updates, combat deferral, square dimensions, scaled single-row layouts, slider bounds, and window reuse. The package script verifies both manifests agree and builds only the addon, license, README, and changelog. Local backups, development dependencies, and submission assets are excluded.

See [release testing](docs/TESTING.md) for development checks.

## License

[MIT license](LICENSE).
