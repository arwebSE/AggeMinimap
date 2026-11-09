# AggeMinimap

A square minimap for **World of Warcraft: Forever**, with a compact header, adjustable size, and Blizzard Edit Mode support.

**[Install from CurseForge](https://www.curseforge.com/wow/addons/aggeminimap)** · [Latest GitHub release](https://github.com/arwebSE/AggeMinimap/releases/latest) · [Report a bug](https://github.com/arwebSE/AggeMinimap/issues)

Keep your minimap clean with just two settings: **Map size** and **Spacing**. Your tracking menu, zone name, clock, calendar, and addon compartment stay together in one row.

![Square minimap in WoW Forever with a compact single-row header](assets/screenshots/square-minimap-in-game.png)

## Features

- Square map with equal width and height and a thin charcoal border.
- Compact, single-row header above or below the map: tracking, zone name, clock, calendar, and addon compartment.
- `/amm` and **Options → AddOns → AggeMinimap** offer the same two sliders: **Map size** (160–360 UI pixels) and **Spacing** (0–40 UI pixels).
- A short login/reload message reminds you of the `/amm` command.
- Project icon and Map category in the in-game AddOns list.
- Native zoom, map clicks, tracking, mail, and minimap buttons remain available.
- Blizzard Edit Mode controls position, additional scaling, and header placement.
- No external libraries or polling timers.

The map is square; the full Edit Mode selection also includes the header row. Long zone names are clipped to the space available between the controls. Changes made during combat apply when combat ends. Size and spacing are saved account-wide.

## Install

Install through the [CurseForge app or project page](https://www.curseforge.com/wow/addons/aggeminimap), selecting **WoW Forever**. For a manual installation:

1. Download the addon ZIP from CurseForge or [GitHub Releases](https://github.com/arwebSE/AggeMinimap/releases). GitHub's automatic **Source code** archives are for development.
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

## Settings

Type **`/amm`** or open **Options → AddOns → AggeMinimap**. Use Blizzard **Edit Mode** to move the map, change its scale, and put the header above or below it.

![AggeMinimap settings: square map size and spacing sliders](assets/screenshots/map-size-and-spacing-settings.png)

## Compatibility

Built for **WoW Forever 1.60.1 (Camelot), interface 16001**, with default and Camelot TOCs. Retail and other Classic clients are not supported. Future client changes may require updates.

Report issues at [GitHub Issues](https://github.com/arwebSE/AggeMinimap/issues), including your client build, addon version, other minimap addons, header placement, and a screenshot if relevant.

## Development

Requires Node.js and PowerShell 7 for the release build.

Automated tests cover layout, settings, loading, and combat deferral in a simulated frame environment. Client behavior and appearance also need in-game verification when changes are made.

```powershell
npm ci
npm test
./scripts/package.ps1
```

Tests check Lua 5.1 syntax, manifests, mask, load order, rotation updates, combat deferral, square dimensions, scaled single-row layouts, slider bounds, and window reuse. The package script verifies both manifests agree and builds only the addon, license, README, and changelog. Local backups, development dependencies, and submission assets are excluded.

See [release testing](docs/TESTING.md) for development checks.

## More from ARWeb

[AggeHealBot](https://www.curseforge.com/wow/addons/aggehealbot) adds click-cast healing to Blizzard party and raid frames in WoW Forever.

## License

[MIT license](LICENSE).
