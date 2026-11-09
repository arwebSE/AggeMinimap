# AggeMinimap

**A clean square minimap. Two sliders. A better fit for your UI.**

AggeMinimap gives **WoW Forever** a square minimap with a thin border and a compact header. Set the size and spacing, move it with Blizzard Edit Mode, and get back to playing.

**[Get AggeMinimap on CurseForge](https://www.curseforge.com/wow/addons/aggeminimap)** · [Latest GitHub release](https://github.com/arwebSE/AggeMinimap/releases/latest)

![AggeMinimap in WoW Forever: square map with a compact header](assets/screenshots/square-minimap-in-game.png)

## Make room for the game

- **A square that stays square.** Equal map width and height, finished with a thin charcoal border.
- **Your controls, together.** Tracking, zone name, clock, calendar and addon compartment sit in one compact row above or below the map.
- **Just two sliders.** Choose your map size and the gap between the map and header. Blizzard Edit Mode handles position, extra scaling and header placement.
- **Keep the familiar controls.** Native zoom, map clicks, mail and minimap buttons remain available.

## Set it up your way

1. Install **AggeMinimap** for **WoW Forever** from CurseForge and restart the game after first installation.
2. Type **`/amm`**, or open **Options → AddOns → AggeMinimap**.
3. Adjust **Map size** and **Spacing**. Open Blizzard **Edit Mode** to position the map and place its header.

![Map size and spacing: the two AggeMinimap settings](assets/screenshots/map-size-and-spacing-settings.png)

Map size ranges from **160 to 360 UI pixels**; spacing ranges from **0 to 40**. Settings are saved account-wide. Changes made during combat apply when combat ends.

## Compatibility and installation

For **WoW Forever 1.60.1 (Camelot), interface 16001**. Use one minimap skin at a time to avoid layout conflicts. Retail and other Classic clients are not supported.

Prefer a manual install? Download the addon ZIP from [GitHub Releases](https://github.com/arwebSE/AggeMinimap/releases/latest), then extract the `AggeMinimap` folder into your Forever client's `Interface/AddOns` folder. The resulting path should be `Interface/AddOns/AggeMinimap/AggeMinimap.toc`. Restart the client after first installation; use `/reload` when updating.

The map itself is square; Blizzard's Edit Mode selection also includes the header. Long zone names are clipped to fit the available space. To restore Blizzard's layout, disable AggeMinimap and reload.

## Enjoying the cleaner map?

[Favorite AggeMinimap on CurseForge](https://www.curseforge.com/wow/addons/aggeminimap) to find it again, or share the project link with your guild. [Report a bug or suggest an improvement](https://github.com/arwebSE/AggeMinimap/issues) with your client build, addon version and a screenshot.

**Also playing a healer?** [AggeHealBot](https://www.curseforge.com/wow/addons/aggehealbot) adds click-to-heal bindings and missing-buff reminders to Blizzard party and raid frames in WoW Forever.

<details>
<summary>Development and verification</summary>

Requires Node.js and PowerShell 7.

```powershell
npm ci
npm test
./scripts/package.ps1
```

Automated tests check Lua syntax, manifests, square dimensions, scaled header layouts, settings, load order and combat deferral in a simulated WoW environment. Client behavior and appearance also require in-game verification when changes are made. See [release testing](docs/TESTING.md).

The package script includes the addon, license, README and changelog. Local backups, development dependencies and submission assets are excluded. No external libraries or polling timers are required by the addon.

</details>

[MIT license](LICENSE).
