#!/bin/bash
# Gera um DMG x86_64 do Hermes Desktop em dist/ a partir do app já compilado
# (release/mac/Hermes.app). Requer ./build-intel.sh executado antes.
#
# Por que não `npm run dist:mac:dmg` direto: ele reempacota o app SEM assinatura
# (CSC_IDENTITY_AUTO_DISCOVERY=false pula tudo, inclusive ad-hoc), e o wrapper
# run-electron-builder.mjs não aceita mais --prepackaged. Aqui aplicamos o mesmo
# fixup ad-hoc do instalador e empacotamos o app pronto com hdiutil.
set -e

INSTALL_DIR="${HERMES_INSTALL_DIR:-$HOME/.hermes/hermes-agent}"
DESKTOP_DIR="$INSTALL_DIR/apps/desktop"
APP="$DESKTOP_DIR/release/mac/Hermes.app"
DIST="$(cd "$(dirname "$0")" && pwd)/dist"

[ -d "$APP" ] || { echo "App não encontrado em $APP — rode ./build-intel.sh primeiro." >&2; exit 1; }
export PATH="$HOME/.hermes/node/bin:$PATH"

# 1. Assinatura ad-hoc estável (mesma rotina que `hermes desktop` usa).
(cd "$INSTALL_DIR" && HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}" venv/bin/python -c '
import sys
from pathlib import Path
from hermes_cli.main import _desktop_macos_relaunchable_fixup
sys.exit(0 if _desktop_macos_relaunchable_fixup(Path(sys.argv[1]), publisher_signing_configured=False) else 1)
' "$DESKTOP_DIR"
)
codesign --verify --deep --strict "$APP"

# 2. DMG (app + atalho para /Applications) com a versão gravada no app pelo build.
VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")
DMG="$DIST/Hermes-$VERSION-mac-x64.dmg"
STAGE=$(mktemp -d)
trap 'rm -rf "$STAGE"' EXIT
ditto "$APP" "$STAGE/Hermes.app"
ln -s /Applications "$STAGE/Applications"
mkdir -p "$DIST"
hdiutil create -volname "Hermes $VERSION" -srcfolder "$STAGE" -format UDZO -ov "$DMG"

# 3. Checksum.
(cd "$DIST" && shasum -a 256 "$(basename "$DMG")" > "$(basename "$DMG").sha256")
echo "DMG: $DMG"
