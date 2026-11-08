# AggeMinimap

A small minimap addon for **World of Warcraft: Forever**. AggeMinimap replaces the circular map presentation with a clean square and keeps the everyday controls in a compact header.

## Features

- Square map with equal width and height and a thin dark border.
- Single-row header above or below the map, following Blizzard Edit Mode.
- Tracking, zone name, clock, calendar, and addon compartment remain accessible.
- `/amm` opens Map size and Spacing sliders.
- Native mouse-wheel zoom, map clicks, and minimap indicators remain available.
- No external libraries required.

## Setup

Install AggeMinimap and restart the game after first installation. Use `/amm` to adjust map size and spacing. Use Blizzard Edit Mode to move or scale the minimap and choose whether its header sits above or below it.

Disable other minimap skins to avoid conflicting changes. Long zone names are clipped to the available header space. Changes made during combat apply after combat ends.

## Compatibility

Targets **WoW Forever (Camelot), interface 16001**. Other WoW clients are not supported.

The initial build is a beta. Automated layout checks pass; the latest header layout has not completed in-game visual verification.

## Support and credits

Report problems through the project's GitHub issue tracker, including your client build, addon version, header placement, and other minimap addons.

Inspired by DejaMinimap's square, minimal appearance. Independently implemented; no DejaMinimap code or assets are included. Distributed under the MIT license.
