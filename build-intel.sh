#!/bin/bash
# Instala/atualiza o Hermes Agent e compila o Hermes Desktop a partir do fonte
# para a arquitetura do host (x86_64 neste iMac Intel).
#
# Uso:
#   ./build-intel.sh            # instala tudo + compila o desktop
#   ./build-intel.sh --rebuild  # só recompila o desktop (checkout já existe)
set -e

INSTALL_DIR="${HERMES_INSTALL_DIR:-$HOME/.hermes/hermes-agent}"
DESKTOP_DIR="$INSTALL_DIR/apps/desktop"

if [ "$(uname -m)" != "x86_64" ]; then
    echo "Aviso: este script foi pensado para x86_64; host é $(uname -m)." >&2
fi

if [ "$1" = "--rebuild" ]; then
    [ -d "$DESKTOP_DIR" ] || { echo "Checkout não encontrado em $INSTALL_DIR — rode sem --rebuild." >&2; exit 1; }
    cd "$INSTALL_DIR" && npm ci --include=optional
    cd "$DESKTOP_DIR" && CSC_IDENTITY_AUTO_DISCOVERY=false npm run pack
    echo "App: $DESKTOP_DIR/release/mac/Hermes.app"
    exit 0
fi

# --skip-setup: a configuração de provider/API key é feita no primeiro launch
# do app (onboarding) ou via `hermes setup`.
curl -fsSL https://hermes-agent.nousresearch.com/install.sh \
    | bash -s -- --include-desktop --skip-setup
