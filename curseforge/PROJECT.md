# CurseForge project setup

Description and release-file metadata for GabbaSounds **1.2.0**. CurseForge project ID: **1733615**. The author explicitly requested this release on 2026-10-15 after the Noggenfogger feature was implemented, tested and installed locally.

Previous completed upload: **1.1.0**, CurseForge file **9125327**, on 2026-10-11. The author reported approval of the initial addon before that release. Upload acceptance does not confirm moderation approval for a new file.

Source repository: https://github.com/Gabbajoe/GabbaSounds

GitHub release target: https://github.com/Gabbajoe/GabbaSounds/releases/tag/v1.2.0
Verified previous release workflow: https://github.com/Gabbajoe/GabbaSounds/actions/runs/38109783956

## General

| Field | Value |
| --- | --- |
| Game | World of Warcraft |
| Project name | GabbaSounds |
| Logo | `logo.png` in this directory (512 × 512 PNG, rendered from the original addon icon) |
| Summary | Randomized German voice clips for weapons and mage spells in WoW Classic Era, with a higher voice while shrunk by Noggenfogger. |
| Class | Addons |
| Main category | Audio & Video |
| Additional categories | Optional: Mage, Hunter, Priest, if offered by the form |
| Allow Comments | Enabled, recommended for feedback |
| Unlisted project | Disabled, for public discovery |
| Social links | Source: https://github.com/Gabbajoe/GabbaSounds |

The final public project URL should be recorded after CurseForge confirms the project slug and moderation status.

## Description

Paste `DESCRIPTION.md` using the Markdown editor. The page is in English; the included spoken recordings and current options interface are German.

For the 1.2.0 update, use the current `DESCRIPTION.md` and Summary above.
The description includes automatic Noggenfogger pitch, all existing sound packs,
browser previews and community credits. Changing repository files prepares the
text; it does not change the live CurseForge project description.

## License

No license has been chosen for the source workspace. Choose the project's license deliberately on the License tab; an open-source license would grant reuse rights beyond downloading and playing the addon. Do not select MIT just because a sound-ID reference uses MIT: that is a separate project.

If you want to keep the rights to your code and voice recordings, the proposed starting selection is **All Rights Reserved**, if offered. This is a suggestion, not a license already applied to the package. Decide this before uploading.

## Release file (1.2.0)

**Release authorized by the author on 2026-10-15.** Publish through the
`v1.2.0` tag workflow after required CI passes. The workflow builds a fresh ZIP
from the tagged checkout and uploads the same package to GitHub and CurseForge.

| Field | Value |
| --- | --- |
| Upload | `GabbaSounds-1.2.0.zip` built by the release workflow |
| Display name | GabbaSounds 1.2.0 |
| Release type | Release |
| Game flavor | Classic / Classic Era (the matching label offered by the form) |
| Game version | 1.15.9 |
| Changelog | Contents of `CHANGELOG-1.2.0.md` |
| Dependencies | None |

Do not select Retail, Burning Crusade, Wrath or other unverified clients. The package targets Interface 11509.

The ZIP contains one top-level `GabbaSounds` directory with the TOC, runtime Lua, icon, documentation and 690 OGGs (345 normal and 345 pitched variants). It excludes microphone source WAVs, logs, saved variables, research data, development tools and these submission materials.

Upload the ZIP to submit the release for moderation. Approval of both project and file is required for public availability. The TOC includes the confirmed numeric project ID. Future automated uploads are described in `docs/RELEASING.md`.

## Official instructions

- [Creating and submitting a project](https://support.curseforge.com/support/solutions/articles/9000197241)
- [Project submission guide and tips](https://support.curseforge.com/support/solutions/articles/9000199552-project-submission-guide-and-tips)

Updated on 2026-10-15. Form labels and available client versions may change.
