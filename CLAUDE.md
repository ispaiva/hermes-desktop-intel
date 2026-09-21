# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Objetivo

Baixar o Hermes Desktop oficial (Nous Research), compilar a partir do fonte e rodar em Macs **Intel (x86_64)**. Os DMGs pré-compilados do site são só arm64; o build local gera um `.app` x64 nativo (sem Rosetta).

Este diretório é um **wrapper**, não um checkout do upstream:

- `build-intel.sh` — instala/atualiza tudo e compila o desktop; `--rebuild` recompila, aplica a assinatura ad-hoc e substitui a cópia em `/Applications/Hermes.app` (fecha o app se estiver aberto).
- `build-dmg.sh` — assina (ad-hoc) o app compilado e gera `dist/Hermes-<versão>-mac-x64.dmg` + `.sha256` para instalar em outros Macs Intel. Os `.dmg` são ignorados pelo git (~145 MB) e publicados em GitHub Releases: https://github.com/ispaiva/hermes-desktop-intel/releases (tag = versão do app desktop, ex. `v0.17.6`; `gh release create vX.Y.Z dist/*.dmg dist/*.sha256`).
- `hermes-agent/` — symlink para `~/.hermes/hermes-agent`, o checkout real de `NousResearch/hermes-agent` (branch `main`, `--depth 1`).

**Nunca** apontar `HERMES_INSTALL_DIR` para este diretório: o instalador faz `rm -rf "$INSTALL_DIR"` quando um clone falha.

## Layout da instalação (fora deste repo)

| Caminho | Conteúdo |
|---|---|
| `~/.hermes/hermes-agent/` | fonte (Python + `apps/desktop` Electron) |
| `~/.hermes/hermes-agent/venv/` | venv Python (uv) |
| `~/.hermes/hermes-agent/apps/desktop/release/mac/Hermes.app` | app x64 compilado (`release/mac-arm64/` seria arm64) |
| `/Applications/Hermes.app` | **cópia** do app acima (não symlink); `hermes update` não a atualiza — use `./build-intel.sh --rebuild` |
| `~/.hermes/bin/uv`, `~/.hermes/node/` | uv e Node 26 x64 gerenciados pelo instalador (não usa o nvm do usuário) |
| `~/.hermes/` | config, sessões, skills, logs (`HERMES_HOME`) |

## Comandos

```bash
./build-intel.sh               # instalação completa + build do desktop
./build-intel.sh --rebuild     # recompilar o desktop + atualizar /Applications
hermes desktop                 # compila (se preciso) e abre o app
hermes update                  # atualiza checkout + recompila do fonte
hermes setup                   # configurar provider/API key (pulado no install: --skip-setup)
open ~/.hermes/hermes-agent/apps/desktop/release/mac/Hermes.app
```

Build manual, dentro do checkout:

```bash
cd ~/.hermes/hermes-agent && npm ci --include=optional   # deps do workspace (raiz, não apps/desktop)
cd apps/desktop
CSC_IDENTITY_AUTO_DISCOVERY=false npm run pack           # app não empacotado em release/
npm run dist:mac:dmg   # DMG, MAS deixa o app SEM assinatura — use ./build-dmg.sh
npm run typecheck && npm run lint && npm test            # checks do desktop
npx vitest run src/caminho/arquivo.test.tsx              # um teste
```

O `npm ci` **tem** de rodar na raiz do repo (workspaces); `scripts/assert-root-install.mjs` falha se rodar só em `apps/desktop`.

## Como o build x64 funciona

- O `install.sh` (`https://hermes-agent.nousresearch.com/install.sh`) **compila** o desktop com `--include-desktop`; não há download de binário. O electron-builder não fixa arquitetura, então `npm run pack --dir` gera para o host.
- `apps/desktop/scripts/stage-native-deps.mjs` copia o prebuild `darwin-x64` do `node-pty`; se faltar, roda `electron-rebuild --arch x64` (exige Xcode CLT, presente).
- O helper nativo de atalho de screenshot (macOS) é compilado no build — também exige Xcode CLT.
- Sem certificado Apple o app é assinado ad-hoc pelo `_desktop_macos_relaunchable_fixup` (em `hermes_cli/main.py`) com Designated Requirement estável, para as permissões TCC sobreviverem a rebuilds.
- O instalador exige Node 26 por causa do `.npmrc` do repo (`min-release-age-exclude`); npm 11.10–11.16 ignora essa chave, por isso ele baixa um Node próprio em `~/.hermes/node/`.

## Armadilhas conhecidas

- `npm run dist:*` com `CSC_IDENTITY_AUTO_DISCOVERY=false` pula até a assinatura ad-hoc; o app resultante em `release/mac/` e no DMG fica não assinado. `build-dmg.sh` resolve aplicando `_desktop_macos_relaunchable_fixup` e empacotando com `--prepackaged <caminho do .app>` (passar `release/mac` coloca a pasta inteira no DMG). Não repetir `--publish never` — o wrapper `run-electron-builder.mjs` já o adiciona e a duplicata causa erro de `GH_TOKEN`.
- A versão do app desktop (`apps/desktop/package.json`, ex. 0.17.6) é independente da do agente Python (`hermes --version`, ex. 0.21.3).

- Dependências de voz/wake-word (`onnxruntime`, `faster-whisper`) falharam na resolução do uv em x86_64-macOS no install de 2026-09-21 (não-fatal; o agente tenta lazy-install no primeiro uso da voz). Voz pode não funcionar neste Mac.

- Download do Electron (~150 MB) pode travar; o instalador tem timeout e fallback para mirror (`ELECTRON_MIRROR=<url>` para forçar um).
- Atualização in-app pode tentar o binário arm64 pré-compilado; preferir `hermes update`, que recompila do fonte.
- Documentação de arquitetura do desktop está no upstream: `apps/desktop/AGENTS.md` e `apps/desktop/DESIGN.md`; raiz do repo: `AGENTS.md`.
