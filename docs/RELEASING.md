# Repository and releases

Repository: https://github.com/Gabbajoe/GabbaSounds

CurseForge project ID: **1733615**. The project page must be created through the author dashboard; the upload API manages files on that existing project.

## What happens automatically

Pushes to `main` and pull requests run the Lua 5.1 tests, Python tests and encoded-audio validation, then build an installable ZIP and SHA256 checksum. Successful CI runs retain these as downloadable workflow artifacts for 14 days.

## Branches and pull requests

All changes must start on a separate branch, such as `feature/melee-skills`,
`fix/sound-routing` or `docs/curseforge-description`. Open a pull request targeting
`main`. The active repository ruleset requires the GitHub Actions check
**Tests, audio and package** to succeed and the pull request to be up to date
with `main` before merging. Its definition is kept in `.github/main-ruleset.json`.
That JSON documents the live GitHub configuration; editing the file alone does
not update the ruleset.

Direct pushes, force pushes and deletion of `main` are blocked. There are no
bypass actors, so the same rules apply to the repository owner. A second person's
review approval is not required; the owner can merge their own pull request once
CI succeeds. The separate CurseForge access test is not the required CI check.

```sh
git switch main
git pull --ff-only
git switch -c feature/my-change
# Make changes, then run the relevant local checks.
git add <changed-files>
git commit -m 'Describe the change'
git push -u origin feature/my-change
gh pr create --base main --fill
gh pr checks --watch
gh pr merge --squash --delete-branch
```

If another pull request changes `main`, update your branch and wait for CI again.
Pull requests and merges build packages; only release tags publish releases.

Pushing a stable tag such as `v1.0.0` performs the same checks. The tag must match `## Version` in `GabbaSounds.toc`, and `curseforge/CHANGELOG-1.0.0.md` must exist. On success the workflow publishes the ZIP and checksum as a GitHub Release. An existing GitHub release is retained on a workflow rerun.

The ZIP always contains a top-level `GabbaSounds` directory, even if a checkout is named differently. It includes only the explicit runtime allowlist and audio files referenced by the manifests. Microphone source WAVs, logs, research downloads, listening HTML, tools, tests and Git metadata are excluded. Package entry timestamps and file modes are fixed so identical contents produce identical bytes with the same Python/zlib environment.

## Enable CurseForge uploads

Repository variable `CURSEFORGE_PROJECT_ID` is set to `1733615`.

Create an author upload token at https://authors.curseforge.com/#/api-token and save it under **Settings → Secrets and variables → Actions → New repository secret**:

- Name: `CURSEFORGE_API_TOKEN`
- Value: your CurseForge author upload token.

Direct settings link: https://github.com/Gabbajoe/GabbaSounds/settings/secrets/actions/new

To check the configured token without uploading, run the **Check CurseForge access** workflow from the Actions tab. It queries the authenticated author API and resolves the exact client version. This read-only check does not prove project-specific upload permission; the first actual upload verifies that separately.

The release workflow skips CurseForge when either setting is absent. With both present, it resolves the exact client version from the TOC Interface via the author API and uploads the same checked ZIP with the version's changelog as Markdown. Missing or ambiguous client versions fail rather than falling back to a different client. GitHub Release publishing happens first, so a CurseForge outage does not erase a successful GitHub release.

Uploads still pass through CurseForge moderation. The token is not passed through command-line arguments, committed, printed, or forwarded across redirects. Upload POSTs are not automatically retried: check the author dashboard before rerunning a failed or interrupted upload. Rerunning an already successful CurseForge upload can create a duplicate; do not do that.

Official API details: https://support.curseforge.com/support/solutions/articles/9000197321-curseforge-api

The prepared local version is **1.1.0**. Its Discord package and notes are ready; pushing `main` does not publish a release or upload to CurseForge. A release tag explicitly starts that publishing workflow.

**Author instruction (2026-10-08): hold the CurseForge 1.1.0 release until the
initial 1.0.0 addon release has been approved.** Check the author dashboard for
approval before starting that upload. API upload acceptance is insufficient.
Because the tag workflow uploads to CurseForge automatically when configured,
do not push the `v1.1.0` release tag while this hold applies.

## Prepare the next version

1. Update addon code and any sound mappings. If you have new recordings locally, import them first with `python3 tools/import_spoken_library.py`.
2. Update `## Version` in `GabbaSounds.toc`, README version/install filename, and any changed feature/count documentation.
3. Add `curseforge/CHANGELOG-<version>.md` with the release notes.
4. Run local checks and build:

```sh
python3 -m pip install -r requirements-dev.txt
bash tests/run_tests.sh
python3 tools/validate_sounds.py --pack all
python3 tools/build_package.py --output-dir dist --tag v1.0.1
```

5. Commit and push your change branch, open a pull request to `main`, and merge
only after **Tests, audio and package** succeeds. Update your local `main` to the
merged commit, then tag it:

```sh
git switch main
git pull --ff-only
git tag -a v1.0.1 -m 'GabbaSounds 1.0.1'
git push origin v1.0.1
```

Replace `1.0.1` with the actual next version. Published tags should remain fixed; use a new version for corrections.

## Public checkout versus local recording workspace

The public repository contains the finished OGGs, manifests, addon source, tools, documentation and anonymized combat-event fixtures. Browser previews under `previews/` are also checked in, with relative links to the shipped OGGs. `python3 tools/build_previews.py` rebuilds them without source recordings. Source WAVs and generated editable cuts stay in the original recording workspace. `.gitignore` preserves these local files without uploading them.

On a fresh public checkout, run:

```sh
GABBA_RUNTIME_ONLY=1 bash tests/run_tests.sh
python3 tools/validate_sounds.py --pack all --runtime-only
python3 tools/build_package.py --output-dir dist
```

Runtime-only mode explicitly skips four tests that require the private source recordings and omits source-WAV hash verification. All Lua behavior tests, manifest/bank/preview checks, packaging tests, upload metadata tests and checks of all 345 encoded OGGs still run. The full local suite continues to verify the original recording hashes and phrase cuts when recordings are available.

The pipeline packages reviewed audio; it does not re-slice or re-encode recordings. `python3 tools/import_spoken_library.py --registry-only` can regenerate the spoken browser preview from the checked-in OGGs without any WAV recordings.

The current project has no open-source reuse license applied. Choose and record the final license consistently on CurseForge and in this repository before changing reuse permissions for code or voice assets.
