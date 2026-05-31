#!/usr/bin/env bash
# Build patched ConvertWithMoss on macOS (mvn + CLI wrapper).
# Run from repo root on branch rus-patched-2026-05.
#
# Prerequisites: brew install maven openjdk@25
# Usage: ./rus-contrib/mac-release/build-patched-macos.sh

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_BIN="${ROOT}/bin/convertwithmoss-rus-cli"

if [[ -z "${JAVA_HOME:-}" ]] && [[ -d "/usr/local/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home" ]]; then
  export JAVA_HOME="/usr/local/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
elif [[ -z "${JAVA_HOME:-}" ]] && [[ -d "/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home" ]]; then
  export JAVA_HOME="/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
fi
export PATH="${JAVA_HOME:-}/bin:/usr/local/bin:/opt/homebrew/bin:${PATH}"

if ! command -v java >/dev/null || ! command -v mvn >/dev/null; then
  echo "ERROR: Need java + mvn. Install: brew install maven openjdk@25" >&2
  exit 1
fi

cd "${ROOT}"
BRANCH="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
if [[ "${BRANCH}" != "rus-patched-2026-05" ]]; then
  echo "[warn] expected branch rus-patched-2026-05, on ${BRANCH}" >&2
fi

echo "== JAVA =="; java -version
echo "== MVN =="; mvn -version | head -2
echo "== maven package =="
mvn -DskipTests clean package

VER=$(grep -m1 '<version>' pom.xml | sed -E 's/.*<version>([^<]+)<\/version>.*/\1/')
JAR=""
for candidate in "target/lib/convertwithmoss-${VER}.jar" "target/convertwithmoss-${VER}.jar"; do
  [[ -f "${candidate}" ]] && JAR="$(pwd)/${candidate}" && break
done
[[ -n "${JAR}" ]] || { echo "ERROR: jar missing"; exit 1; }

mkdir -p "${ROOT}/bin"
cat >"${OUT_BIN}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
export RUS_CWM_MACHINE_PROGRESS="\${RUS_CWM_MACHINE_PROGRESS:-1}"
CWM_HOME="${ROOT}"
JB="\${JAVA_HOME:-}/bin/java"
[[ -x "\${JB}" ]] || JB="java"
exec "\${JB}" --enable-native-access=ALL-UNNAMED \\
  -cp "\${CWM_HOME}/target/convertwithmoss-${VER}.jar:\${CWM_HOME}/target/lib/*" \\
  de.mossgrabers.convertwithmoss.ui.ConvertWithMossApp "\$@"
EOF
chmod +x "${OUT_BIN}"
echo "[done] ${OUT_BIN} (v${VER})"
