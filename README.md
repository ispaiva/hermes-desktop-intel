# Hermes Desktop para macOS Intel (x86_64)

Build **não oficial** do [Hermes Desktop](https://github.com/NousResearch/hermes-agent/tree/main/apps/desktop) — o app nativo do [Hermes Agent](https://github.com/NousResearch/hermes-agent), da Nous Research — para Macs com processador Intel.

Os instaladores oficiais em [hermes-agent.nousresearch.com](https://hermes-agent.nousresearch.com/) são só para Apple Silicon (arm64). Este repositório compila o mesmo código-fonte, sem modificações, para x86_64. O app resultante é nativo: **não precisa de Rosetta**.

## Requisitos

- Mac com processador Intel
- macOS 11 (Big Sur) ou superior
- Internet no primeiro launch (o app baixa o runtime do Hermes Agent)
- [Xcode Command Line Tools](https://developer.apple.com/download/all/) — só se optar por instalar o runtime localmente (o instalador compila módulos nativos). Instale com `xcode-select --install`.

## Instalação pelo DMG

1. Baixe o `.dmg` mais recente em [**Releases**](https://github.com/ispaiva/hermes-desktop-intel/releases).
2. Abra o `.dmg` e arraste **Hermes** para **Applications**.
3. Primeira abertura: o app é assinado ad-hoc e **não é notarizado pela Apple**, então o Gatekeeper vai bloqueá-lo. Faça um dos dois:
   - Clique com o botão direito em `Hermes.app` → **Abrir** → confirme; ou
   - No Terminal: `xattr -d com.apple.quarantine /Applications/Hermes.app`
4. No primeiro launch o app oferece duas opções:
   - **Instalar o Hermes localmente** — baixa o runtime Python para `~/.hermes` e guia a escolha de provedor/modelo e chave de API.
   - **Conectar a um gateway existente** — se você já roda o Hermes em outra máquina.

### Verificar o download

```bash
shasum -a 256 -c Hermes-<versão>-mac-x64.dmg.sha256
```

## Compilar a partir do fonte

Se preferir não usar o DMG, ou quiser acompanhar o `main` do upstream:

```bash
git clone https://github.com/ispaiva/hermes-desktop-intel.git
cd hermes-desktop-intel
./build-intel.sh
```

O script roda o instalador oficial (`install.sh`) com `--include-desktop`: clona o upstream em `~/.hermes/hermes-agent`, cria o venv Python, baixa um Node 26 x64 próprio e compila o Electron. O app fica em `~/.hermes/hermes-agent/apps/desktop/release/mac/Hermes.app` e pode ser aberto com `hermes desktop`.

Comandos úteis depois disso:

| Comando | O que faz |
|---|---|
| `./build-intel.sh --rebuild` | Recompila o desktop, assina e atualiza a cópia em `/Applications/Hermes.app` |
| `./build-dmg.sh` | Gera `dist/Hermes-<versão>-mac-x64.dmg` + `.sha256` |
| `hermes update` | Atualiza o checkout do upstream e recompila (não atualiza `/Applications`) |
| `hermes setup` | Configura provedor, modelo e chave de API pela CLI |

## Limitações conhecidas

- **Sem notarização Apple.** Cada nova versão exige o passo do Gatekeeper acima. A assinatura ad-hoc usa identidade estável, então permissões concedidas (microfone, tela, acessibilidade) persistem entre atualizações.
- **Atualização in-app.** O botão de update dentro do app pode tentar baixar o binário arm64 oficial. Prefira `hermes update` + `./build-intel.sh --rebuild`, ou baixe o DMG novo daqui.
- **Voz / wake-word.** As dependências `onnxruntime` e `faster-whisper` não resolveram para x86_64-macOS no build atual; o agente tenta instalá-las no primeiro uso da voz, mas o recurso pode não funcionar.

## Créditos e licença

Todo o código do app é da [Nous Research](https://nousresearch.com), licenciado sob [MIT](https://github.com/NousResearch/hermes-agent/blob/main/LICENSE). Este repositório contém apenas scripts de build e documentação; não é afiliado nem endossado pela Nous Research. Para problemas do app em si, veja as [issues do upstream](https://github.com/NousResearch/hermes-agent/issues); para problemas específicos do build Intel, abra uma issue aqui.
