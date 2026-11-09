# Changelog

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
