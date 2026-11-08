# CurseForge submission kit

## Create the listing

Open the [CurseForge Authors Console](https://authors.curseforge.com/#/projects/create/choose-game), sign in, and create a World of Warcraft addon project.

| Field | Value |
| --- | --- |
| Name | AggeMinimap |
| Summary | A clean square minimap with a compact header and adjustable size and spacing. |
| Class | Addons |
| Main category | Map & Minimap |
| License | MIT License |
| Avatar | `assets/AggeMinimap-icon.png` (square PNG; export a 400 × 400 copy if requested by the console) |
| Description | Paste `docs/CURSEFORGE-DESCRIPTION.md` |
| Source | https://github.com/arwebSE/AggeMinimap |
| Issues | https://github.com/arwebSE/AggeMinimap/issues |

Keep the project non-experimental if you want it distributed through the app. Project name availability and game-version options must be confirmed in the console at submission time.

## Upload the file

- Build with `./scripts/package.ps1` or download the addon ZIP attached to the GitHub prerelease.
- Upload **AggeMinimap-1.2.0-beta.1.zip**, not the GitHub source archive.
- Select **WoW Forever / 1.60.1** if offered. The addon targets interface **16001**; do not tag Retail or Classic as supported.
- Set the release type to **Beta** for this initial build. Paste the current entry from `CHANGELOG.md` into the changelog field.
- No external addon dependencies are required.
- Uploading the first file submits the project/file for moderation. Watch the console for requested changes; approval timing is controlled by CurseForge.

CurseForge's submission guide says a project needs at least one **Release** file before it syncs to the app. A beta listing is useful for initial review, but normal app distribution should follow the in-game checks in `docs/TESTING.md` and a stable Release upload. Do not relabel an unverified beta merely to appear in the app.

After the project is created, record its project ID in the TOCs as `## X-Curse-Project-ID: <actual ID>`. Future uploads can be automated using a CurseForge upload token stored as a GitHub Actions secret; never commit the token. This kit does not assume an account, project ID, or token already exists.

## References

- [Creating and submitting a project](https://support.curseforge.com/support/solutions/articles/9000197241)
- [Submission tips and avatar requirements](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips)
- [Moderation policies](https://support.curseforge.com/support/solutions/articles/9000197279)
