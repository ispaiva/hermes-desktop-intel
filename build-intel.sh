#!/bin/bash
# Instala/atualiza o Hermes Agent e compila o Hermes Desktop a partir do fonte
# para a arquitetura do host (x86_64 neste iMac Intel).
#
# Uso:
#   ./build-intel.sh            # instala tudo + compila o desktop
#   ./build-intel.sh --rebuild  # só recompila o desktop e atualiza /Applications/Hermes.app
set -e

INSTALL_DIR="${HERMES_INSTALL_DIR:-$HOME/.hermes/hermes-agent}"
DESKTOP_DIR="$INSTALL_DIR/apps/desktop"

if [ "$(uname -m)" != "x86_64" ]; then
    echo "Aviso: este script foi pensado para x86_64; host é $(uname -m)." >&2
fi

if [ "$1" = "--rebuild" ]; then
    [ -d "$DESKTOP_DIR" ] || { echo "Checkout não encontrado em $INSTALL_DIR — rode sem --rebuild." >&2; exit 1; }
    export PATH="$HOME/.hermes/node/bin:$PATH"
    cd "$INSTALL_DIR" && npm ci --include=optional
    cd "$DESKTOP_DIR" && CSC_IDENTITY_AUTO_DISCOVERY=false npm run pack
    APP="$DESKTOP_DIR/release/mac/Hermes.app"

    # `npm run pack` deixa o app sem assinatura; aplicar o mesmo fixup ad-hoc
    # que o instalador usa (identidade estável -> permissões TCC persistem).
    (cd "$INSTALL_DIR" && HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}" venv/bin/python - "$DESKTOP_DIR" <<'PYEOF'
import sys
from pathlib import Path
from hermes_cli.main import _desktop_macos_relaunchable_fixup
sys.exit(0 if _desktop_macos_relaunchable_fixup(Path(sys.argv[1]), publisher_signing_configured=False) else 1)
PYEOF
    )
    codesign --verify --deep --strict "$APP"

    # Atualizar a cópia em /Applications (fecha o app se estiver aberto).
    if pgrep -qf '/Applications/Hermes.app/Contents/MacOS/Hermes'; then
        echo "Fechando Hermes em execução..."
        osascript -e 'quit app "Hermes"' || true
        sleep 3
    fi
    rm -rf /Applications/Hermes.app
    cp -R "$APP" /Applications/
    echo "App: $APP"
    echo "Copiado para /Applications/Hermes.app"
    exit 0
fi

# --skip-setup: a configuração de provider/API key é feita no primeiro launch
# do app (onboarding) ou via `hermes setup`.
curl -fsSL https://hermes-agent.nousresearch.com/install.sh \
    | bash -s -- --include-desktop --skip-setup
