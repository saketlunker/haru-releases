# Wispling Releases

This repository is the public release channel for **Wispling**, a desktop companion pet.

It contains the installer, release manifests, checksums, and binary assets.
It does **not** contain the source code, which lives in a private repository.

## Install

One line, once:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/saketlunker/wispling-releases/main/install.ps1 | iex"
```

That installs Wispling into `%LOCALAPPDATA%\Wispling`, adds a Start Menu shortcut, and
puts `wispling` on your `PATH`.

## Updating

You don't. Wispling checks this repository on every launch, verifies the release
signature, and installs the update in the background. There is no second
install step and no manual update command.

## Repository layout

- `install.ps1` — the one-line install entry point
- `scripts/windows/` — bootstrap and installer support scripts
- `releases/latest.json` — update manifest read by the in-app updater
- GitHub Releases — binary assets, checksums, and release notes

## Status

No binary release has been published yet. `releases/latest.json` is a
placeholder pinned to the current version, so the updater correctly reports
"no update available" rather than erroring.

## Security

Updates are signed with a minisign keypair and verified by the app before
installation. An unsigned or tampered artifact is rejected.

Only release artifacts intended for public distribution belong here. No source
archives, internal build output, private debugging material, or CI secrets.

## Credits

Wispling began as a rebrand of [`jupram/tokki`](https://github.com/jupram/tokki) by
Jupram, used with permission, and has diverged since.
