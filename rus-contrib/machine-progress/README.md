# RUS machine-progress patch for ConvertWithMoss

Contribution for upstream issue https://github.com/git-moss/ConvertWithMoss/issues/141

## Build (Windows)

Requires JDK 25+ and Maven 3.9+.

1. Clone https://github.com/git-moss/ConvertWithMoss
2. `git apply rus-contrib/machine-progress/cwm-rus-machine-progress.patch`
3. Copy `MachineProgressReporter.java` into `src/main/java/de/mossgrabers/convertwithmoss/core/`
4. Run `apply-cwm-sample-progress.ps1` on `AbstractDetector.java`
5. `mvn -DskipTests clean package`

Or checkout branch `rus-patched-2026-05` in this fork (includes this patch plus other RUS Kontakt fixes).

## Pre-built

See https://github.com/cjslickmusic-max/ConvertWithMoss/releases — **rus-patched-17.2.0** (Windows zip; macOS build on Mac).
