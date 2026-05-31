#!/usr/bin/env bash
# Package macOS universal release (x64 app-image + arm64 from GitHub Actions).
# Run from repo root after build-patched-macos.sh (or mvn package).
#
# Prerequisites: JDK 25+ (jpackage), gh CLI authenticated.
# Usage: ./rus-contrib/mac-release/package-macos-universal.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LIB="${ROOT}/target/lib"
VER="17.2.0"
JAR="${LIB}/convertwithmoss-${VER}.jar"
RELEASE_DIR="${ROOT}/target/rus-mac-release"
FORK="cjslickmusic-max/ConvertWithMoss"

if [[ -z "${JAVA_HOME:-}" ]] && [[ -d "/usr/local/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home" ]]; then
  export JAVA_HOME="/usr/local/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
elif [[ -z "${JAVA_HOME:-}" ]] && [[ -d "/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home" ]]; then
  export JAVA_HOME="/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
fi
export PATH="${JAVA_HOME:-}/bin:/usr/local/bin:/opt/homebrew/bin:${PATH}"

if [[ ! -f "${JAR}" ]]; then
  echo "[build] Running build-patched-macos.sh first..."
  "${ROOT}/rus-contrib/mac-release/build-patched-macos.sh"
fi

if ! command -v jpackage >/dev/null; then
  echo "ERROR: jpackage not found (need JDK 25+)" >&2
  exit 1
fi

APP_DEST="${ROOT}/target/rus-app-image"
X64_APP="${APP_DEST}/ConvertWithMoss-rus.app"
if [[ ! -d "${X64_APP}" ]]; then
  echo "[jpackage] x64 app-image..."
  rm -rf "${APP_DEST}"
  jpackage \
    --input "${LIB}" \
    --main-jar "convertwithmoss-${VER}.jar" \
    --main-class de.mossgrabers.convertwithmoss.ui.ConvertWithMossApp \
    --name "ConvertWithMoss-rus" \
    --app-version "${VER}" \
    --type app-image \
    --dest "${APP_DEST}" \
    --java-options "--enable-native-access=ALL-UNNAMED" \
    --vendor "Razumov (LGPL ConvertWithMoss fork)"
fi

ARM_STAGE="${ROOT}/target/rus-arm64-artifact"
ARM_DIR="${ARM_STAGE}/cwm-mac-arm64-app"
if [[ ! -d "${ARM_DIR}" ]]; then
  echo "[ci] Downloading arm64 app from GitHub Actions..."
  RUN_ID=$(gh run list -R "${FORK}" --workflow=cwm-mac-arm64.yml --limit 1 --json databaseId --jq '.[0].databaseId')
  if [[ -z "${RUN_ID}" || "${RUN_ID}" == "null" ]]; then
    echo "[ci] Triggering arm64 workflow..."
    gh workflow run "CWM Mac ARM64 package" -R "${FORK}"
    sleep 10
    gh run watch "$(gh run list -R "${FORK}" --workflow=cwm-mac-arm64.yml --limit 1 --json databaseId --jq '.[0].databaseId')" -R "${FORK}" --exit-status
    RUN_ID=$(gh run list -R "${FORK}" --workflow=cwm-mac-arm64.yml --limit 1 --json databaseId --jq '.[0].databaseId')
  fi
  rm -rf "${ARM_STAGE}"
  gh run download "${RUN_ID}" -R "${FORK}" -D "${ARM_STAGE}"
fi

mkdir -p "${RELEASE_DIR}"
STAGE=$(mktemp -d)
trap 'rm -rf "${STAGE}"' EXIT

cp -R "${X64_APP}" "${STAGE}/ConvertWithMoss-rus-x64.app"
cp -R "${ARM_DIR}" "${STAGE}/ConvertWithMoss-rus-arm64.app"

cat > "${STAGE}/INSTALL.sh" << 'INSTALL'
#!/usr/bin/env bash
set -euo pipefail
ARCH="$(uname -m)"
DEST="${HOME}/Library/Application Support/Razumov/Razumov Ultimate Sampler/ConvertWithMoss-rus"
ROOT="$(cd "$(dirname "$0")" && pwd)"
if [[ "${ARCH}" == "arm64" ]]; then
  SRC="${ROOT}/ConvertWithMoss-rus-arm64.app"
else
  SRC="${ROOT}/ConvertWithMoss-rus-x64.app"
fi
echo "Installing patched ConvertWithMoss (${ARCH}) to ${DEST}"
mkdir -p "${DEST}"
rm -rf "${DEST}/ConvertWithMoss-rus.app"
ditto --norsrc "${SRC}" "${DEST}/ConvertWithMoss-rus.app"
echo ""
echo "Done. RUS will auto-detect:"
echo "  ${DEST}/ConvertWithMoss-rus.app"
INSTALL
chmod +x "${STAGE}/INSTALL.sh"

ZIP_PATH="${RELEASE_DIR}/ConvertWithMoss-rus-patched-${VER}-macos-universal.zip"
rm -f "${ZIP_PATH}"
( cd "${STAGE}" && zip -r -q "${ZIP_PATH}" . )

echo "[done] ${ZIP_PATH}"
echo "Upload: gh release upload rus-patched-17.2.0 -R ${FORK} --clobber ${ZIP_PATH}"
