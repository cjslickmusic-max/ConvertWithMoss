# macOS release (Intel + Apple Silicon)

Patched ConvertWithMoss **17.2.0** for Razumov Ultimate Sampler (RUS progress on stderr).

## Quick path (recommended)

1. `git checkout rus-patched-2026-05`
2. `brew install maven openjdk@25`
3. `./rus-contrib/mac-release/build-patched-macos.sh`
4. `./rus-contrib/mac-release/package-macos-universal.sh`
5. Upload `target/rus-mac-release/ConvertWithMoss-rus-patched-17.2.0-macos-universal.zip` to
   [releases/rus-patched-17.2.0](https://github.com/cjslickmusic-max/ConvertWithMoss/releases/tag/rus-patched-17.2.0)

The universal zip contains **x64** and **arm64** `.app` bundles; `INSTALL.sh` picks the right one.

## arm64 slice (CI)

Apple Silicon app-image is built by GitHub Actions:

- Workflow: `.github/workflows/cwm-mac-arm64.yml`
- Trigger: manual (`workflow_dispatch`) or automatically from `package-macos-universal.sh`

Intel (x64) app-image is built locally with `jpackage` on the build machine.

## RUS repo mirror

The same scripts live in Razumov Ultimate Sampler as:

- `tools/build-convert-with-moss-patched.sh` (clones this fork branch into `tools/.cwm-patch-build/`)
- `tools/package-cwm-rus-mac-release.sh`

Canonical fork branch for patched sources: **`rus-patched-2026-05`**.
