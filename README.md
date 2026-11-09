# Prisma Hub

Hub customizado para **Blox Fruits**, em **arquivo único**, com UI própria (sem Rayfield/Fluent), **sem key system** e **PC only**.

```
loadstring(game:HttpGet("https://raw.githubusercontent.com/s4guadin/prisma-hub/main/hub.lua"))()
```

## Recursos

- **Farm** — lista mobs matáveis de `Workspace.Enemies` com nível; clique escolhe o mob do Auto Farm e, sem seleção, ele escolhe o melhor para o seu nível. Inclui **Farm instantâneo** (`SimulationRadius` + `Humanoid.Health = 0`), Auto Quest (1º/2º/3º mar) e ataque rápido.
- **Raid** — aba dedicada ao **Auto Raid** de verdade: compra/equipa o Microchip, teleporta até o botão da raid, entra e fica **pairando alto (~55 studs) sobre o centro de cada ilha**, matando na hora tudo o que aparece no raio (sem atacar). Só avança quando a ilha está limpa. Inclui seletor de chip, comprar chip, checar raid e Auto Awakening.
- **Boss** — aba separada com bosses vivos no servidor, TP e Auto Boss.
- **Combat** — Auto Skills Z/X/C (via `Tool.RemoteFunction`), Auto Ataque, Kill Aura instantâneo (mata mobs no raio via `SimulationRadius` + `Humanoid.Health = 0`), Auto Stats com atributo ciclável.
- **ESP** — jogadores, bosses, frutas e baús (`Highlight` + `BillboardGui` com nome e distância).
- **Frutas** — notificador (inclui frutas spawnadas pelo servidor), lista, teleporte e "puxar fruta".
- **Util** — fly, noclip, pulo infinito, server hop, reconectar, auto rejoin, anti-AFK, espectar, TP por coordenadas.
- **Ilhas** — coordenadas reais por mar + viagem via `CommF_`.
- **Config** — salvar/carregar (`prisma_config.json`), TP para o spawn.
- **Kill switch** — botão "PARAR TUDO" desliga todas as features.

## Uso

1. Execute o loadstring no seu executor (PC).
2. A janela abre centralizada; arraste pela barra de título.
3. Selecione um mob/boss/jogador — o clique **só seleciona**. TP e farm começam pelo botão/toggle.
4. Minimize com `–`; reabra pelo botão **P**.

## Aviso

- Use por sua conta e risco. Scripts de terceiros violam os Termos de Serviço do jogo.
- Não há bypass de anti-cheat garantido: a camada anti-detecção apenas reduz padrões (jitter, rate limit, `pcall`, sem prints).
- Recursos podem quebrar após atualizações do jogo. Nomes de remotes ficam centralizados no topo de `hub.lua`.

## Estrutura

| Arquivo | Descrição |
|---|---|
| `hub.lua` | Hub completo (arquivo único). |
| `MEMORIA.md` | Decisões, arquitetura, changelog e checklist de teste. |
| `teste.lua` | Teste mínimo de GUI. |

## Versão

`1.6` — Prisma Hub
