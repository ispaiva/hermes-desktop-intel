#!/bin/bash
# Gera um DMG x86_64 do Hermes Desktop em dist/ a partir do app já compilado
# (release/mac/Hermes.app). Requer ./build-intel.sh executado antes.
#
# Por que não `npm run dist:mac:dmg` direto: ele reempacota o app SEM assinatura
# (CSC_IDENTITY_AUTO_DISCOVERY=false pula tudo, inclusive ad-hoc). Aqui aplicamos
# o mesmo fixup ad-hoc do instalador e empacotamos o app pronto com --prepackaged.
set -e

INSTALL_DIR="${HERMES_INSTALL_DIR:-$HOME/.hermes/hermes-agent}"
DESKTOP_DIR="$INSTALL_DIR/apps/desktop"
APP="$DESKTOP_DIR/release/mac/Hermes.app"
DIST="$(cd "$(dirname "$0")" && pwd)/dist"

[ -d "$APP" ] || { echo "App não encontrado em $APP — rode ./build-intel.sh primeiro." >&2; exit 1; }
export PATH="$HOME/.hermes/node/bin:$PATH"

# 1. Assinatura ad-hoc estável (mesma rotina que `hermes desktop` usa).
(cd "$INSTALL_DIR" && HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}" venv/bin/python - "$DESKTOP_DIR" <<'PYEOF'
import sys
from pathlib import Path
from hermes_cli.main import _desktop_macos_relaunchable_fixup
sys.exit(0 if _desktop_macos_relaunchable_fixup(Path(sys.argv[1]), publisher_signing_configured=False) else 1)
PYEOF
)
codesign --verify --deep --strict "$APP"

# 2. DMG a partir do app pronto. O caminho tem de ser o .app, não release/mac
#    (senão a pasta inteira vai parar dentro do DMG). O wrapper já passa
#    --publish never; não repetir a flag (dispara erro de GH_TOKEN).
(cd "$DESKTOP_DIR" && rm -f release/Hermes-*-mac-x64.dmg* \
  && CSC_IDENTITY_AUTO_DISCOVERY=false node scripts/run-electron-builder.mjs --prepackaged "$APP" --mac dmg)

# 3. Copiar para dist/ com checksum.
mkdir -p "$DIST"
DMG=$(ls "$DESKTOP_DIR"/release/Hermes-*-mac-x64.dmg)
cp "$DMG" "$DIST/"
(cd "$DIST" && shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256")
echo "DMG: $DIST/$(basename "$DMG")"
