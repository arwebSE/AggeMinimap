# Changelog

## 1.2.7

- Fixed empty strips and detached borders after enlarging the map or changing its proportions by refreshing native rendering while preserving zoom.
- Added Reset defaults to both settings views, restoring dimensions, spacing, aspect linking, and icon positions.
- Added separate width and height sliders, with aspect ratio linked by default and an option to resize independently.
- New profiles default to 200 × 200 and 0 px spacing; defaults are shown beside the controls, and existing saved sizes carry over.
- Allowed spacing down to −20 px to overlap the header with the map while keeping the full map inside Edit Mode bounds.
- The AggeMinimap settings window can now be moved by dragging its title bar.
- Restyled settings to match AggeHealBot, with the native character-window frame, dark background, gold selection outlines, and a two-column layout.

## 1.2.6

- Right-click the minimap to open AggeMinimap options.
- Added saved options for the sun/moon corner and zoom button edge in both settings views.
- Moved the zoom buttons and their hover area to the minimap's left edge.
- Anchored the sun/moon indicator to the top-left corner across map sizes and Edit Mode scales.

## 1.2.5

- Enabled publishing to CurseForge from verified GitHub version tags.
- Release uploads now wait for addon tests, package-layout checks, and matching manifest versions.
- No in-game behavior changes.

## 1.2.4

- Changed the in-game AddOns category from Maps to Map.
- Added automatic-packager configuration with the correct addon folder layout.
- Added the CurseForge project ID to both manifests.
- Added a separate packager build check to CI.

## 1.2.3

- Added the project icon to the in-game AddOns list.
- Listed AggeMinimap under the Maps category.

## 1.2.2

- Login/reload message now includes the installed version, read from addon metadata.

## 1.2.1

- Added the Map size and Spacing sliders to Options → AddOns → AggeMinimap.
- Both settings views update the same saved values and stay synchronized.
- Added a single login/reload message: "AggeMinimap: Loaded. /amm for settings."

Automated checks cover Options registration, synchronization, and the login message. In-game verification of this update is pending.

## 1.2.0-beta.1

First public beta for WoW Forever (interface 16001).

- Square minimap with a thin dark border and reduced decorative artwork.
- Single-row header with tracking, zone name, clock, calendar, and addon compartment.
- Header above/below follows Blizzard Edit Mode; removed the old two-row gap.
- `/amm` opens saved Map size and Spacing sliders.
- Map width and height stay equal when resized.
- Reapplies the skin after minimap rotation changes; defers changes during combat.

Automated checks pass. The latest header layout still needs in-game visual verification.
