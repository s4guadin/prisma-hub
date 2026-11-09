# Prisma Hub (Blox Fruits) — Memória do Projeto

> Arquivo de memória. Ler isto antes de abrir o código. Atualizar ao fim de cada sessão.
> Última atualização: 2026-11-08

---

## 1. Decisões fechadas

| Item | Decisão |
|---|---|
| Executor | Nenhum específico. Código compatível com o máximo de executores. |
| UI | **Custom** (ScreenGui escrito do zero, sem Rayfield/Fluent). |
| Arquitetura | **Arquivo único**, organizado internamente em seções (core / config / modules / ui). |
| Key system | **Não** por enquanto. |
| Plataforma | **PC only** por enquanto. |
| Anti-detecção | **Sim**, camada incluída desde a Fase 1. |
| Escopo inicial | **Fase 1** (definida abaixo). |

### Por que UI custom
Sem executor definido, dependência externa (Rayfield/Fluent) é risco: se a lib quebra
no executor X, o hub inteiro quebra. Custom = zero dependência, visual próprio,
anti-detecção mais limpo (menos código de terceiros rodando).

### Por que arquivo único
Distribuição simples (um loadstring), fácil de versionar. Internamente dividido em
seções para não virar bagunça. Se crescer muito, migrar para loader + módulos.

---

## 2. Arquitetura interna do arquivo único

Ordem das seções no arquivo:

1. **CONFIG** — constantes globais (nomes de remote, tetos de velocidade, delays base, paths).
2. **CORE** — utilitários compartilhados:
   - `getRemote(name)` — varre ReplicatedStorage por RemoteEvent/RemoteFunction.
   - `teleport(pos)` / `tpTo(part)`
   - `getChar()` / `getHRP()` / `getHum()` / `isAlive()`
   - `notify(text, dur)`
   - `waitFor(parent, name, timeout)`
3. **ANTI-DETECÇÃO** — jitter, rate limit, pcall wrapper, kill switch, sem prints.
4. **MODULES** — uma função/bloco por feature, cada uma com start/stop.
5. **UI** — janela custom, abas, toggles, sliders, botão de pânico.
6. **BOOT** — monta UI, liga config, inicia loops necessários.

### Regras de código
- Todo loop de ação usa delay com jitter aleatório.
- Todo remote tem rate limit (fila + intervalo mínimo).
- Todo bloco de feature é isolado com `pcall`.
- Feature que falha repetido desliga sozinha (contador de erro).
- Sem `print` no console. Log interno em memória, opcional.
- Nomes neutros em variáveis, GUI e arquivos.
- Compatibilidade: usar apenas APIs comuns (`task.wait`, `pcall`, `Instance`, serviços padrão).
  `writefile`/`readfile`/`getgenv` são opcionais com fallback em memória.

---

## 3. Camada anti-detecção — o que faz

Não é bypass mágico. Reduz padrões detectáveis:

1. Delays humanizados (jitter, ex: 0.08–0.15s em vez de 0.1 fixo).
2. Limite de velocidade em teleporte/speed (teto definido no CONFIG).
3. Rate limit em remotes (não dispara 50x/s).
4. `pcall` em tudo — erro não derruba o hub.
5. Auto-pausa em erro repetido.
6. Anti-AFK nativo.
7. Auto-rejoin em disconnect.
8. Zero prints.
9. Nomes neutros.
10. Kill switch (desliga tudo instantâneo).

---

## 4. Escopo — Fases

### FASE 1 — Base (CONCLUÍDA — `hub.lua`)
**Core**
- [x] getRemote (busca em ReplicatedStorage + pasta Remotes, com cache)
- [x] teleport / tweenTo
- [x] getChar / getHRP / getHum / isAlive
- [x] notify
- [x] config save/load (writefile se existir, senão aviso)

**UI**
- [x] Janela custom arrastável (620x470, tema escuro com sidebar)
- [x] Abas: Farm, Boss, Util, Ilhas, Config
- [x] Toggle por feature
- [x] Slider de delay / distância / velocidade
- [x] Botão de pânico (PARAR TUDO)
- [x] Botão de minimizar/reabrir

**Features**
- [x] Auto attack (reequipa arma + tool:Activate + clique VirtualUser)
- [x] Auto farm de mob por nome (via `Workspace.Enemies`, cache curto)
- [x] Auto farm de boss (aba separada)
- [x] Teleport: jogador, coordenadas, ilhas, spawn, mob
- [x] Anti-AFK
- [x] Kill switch

**Anti-detecção**
- [x] Jitter nos delays
- [x] pcall em tudo
- [x] Rate limit de remote
- [x] Auto-pausa em erro repetido
- [x] Sem prints

> Observação: nomes de ilhas são resolvidos por busca no Workspace.
> Se não achar, preencher `CONFIG.islandCoords["Ilha"] = Vector3.new(x,y,z)` no `hub.lua`.

### FASE 2 — Farm essencial
- [ ] Auto farm level
- [ ] Auto farm money
- [x] Auto quest parcial (aceitar + farmar; entrega manual) — 1º/2º/3º mar
- [x] Teleport list completa
- [ ] Seletor de mar (primeiro/segundo/terceiro)

### FASE 3 — Frutas + ESP
- [x] Fruit sniper parcial (detecta, lista, teleporta e puxa)
- [x] Fruit notifier (nome)
- [ ] Fruit whitelist
- [ ] Auto store / sell
- [x] ESP jogadores (nome + distância)
- [x] ESP frutas
- [x] ESP baús
- [x] ESP bosses / mobs

### FASE 4 — Combate completo
- [x] Skill rotation parcial (Z/X/C automáticos com cooldown)
- [ ] Aimbot / silent aim
- [ ] Auto Haki (Busoshoku / Kenbunshoku)
- [ ] Auto dodge / block
- [ ] Auto combo
- [ ] Auto gun / sword equip

### FASE 5 — Utilidades + QoL
- [x] Fly
- [x] Noclip
- [x] Infinite jump
- [x] Server hop
- [x] Auto collect parcial (puxar fruta)
- [ ] Auto claim daily
- [ ] Auto mastery (arma/gun)
- [ ] Trade notifier / scam detector
- [x] Player list com teleporte

### FASE 6 — Polimento
- [ ] Revisão da anti-detecção
- [ ] Suporte mobile (quando pedido)
- [ ] Key system (só se for distribuir)
- [ ] Documentação de uso

---

## 5. Riscos técnicos mapeados

- **Nomes de remote mudam por update** → todos centralizados na seção CONFIG.
- **Anti-cheat do jogo** → camada de redução de padrão, não bypass garantido.
- **Detecção comportamental** → delays humanizados e tetos.
- **Quebra pós-update** → features isoladas com pcall e auto-pausa.
- **Compatibilidade de executor** → só APIs comuns; opcionais com fallback.

---

## 6. Nomes comuns de remote no Blox Fruits (referência — variam por update)

`CommF_`, `CommE`, `Attack`, `UseSkill`, `PurchaseFruit`, `BuyHaki`,
`SellFruit`, `ClaimQuest`, `CompleteQuest`, `StoreFruit`

> Sempre confirmar no jogo antes de usar. Manter esta lista na CONFIG do código.

---

## 7. Arquivos da pasta

| Arquivo | O que é |
|---|---|
| `MEMORIA.md` | Este documento. Ler antes de abrir código. |
| `hub.lua` | Prisma Hub 1.8.3 (arquivo único). |
| `teste.lua` | Teste mínimo de GUI (quadrado azul "GUI OK"). |

## 8. Estado atual

- Planejamento: **completo** (este arquivo).
- Código: **Fase 1.8.3** em `hub.lua`.
- Versão atual: `1.8.3` (Prisma Hub).

### Mudanças da 1.4 (pacote "Tudo" inspirado em hubs públicos)
- **Renomeado para Prisma Hub** (`CONFIG.name`, título da janela, botão de reabrir "P").
- **UI restilizada no estilo de hub genérico**: janela 620x470 centralizada,
  sidebar de navegação (150px) com abas verticais, tema escuro `#0E0E13`,
  acento violeta `#7C5CFF`, cabeçalhos de seção em maiúsculas, toggles em
  formato pílula, sliders com valor separado, hover em botões e scrollbars finas.
- Config salva em `prisma_config.json`; ScreenGui nomeada `PrismaUI_<random>`.
- **Lista de mobs com nível**: mostra `Nome [Lv. X] (quantidade)`, lido do
  atributo/`DisplayName`/BillboardGui do mob ou, como fallback, da tabela de
  quests. Lista ordenada por nível.
- **Auto Farm escolhe o mob**: usa o mob selecionado na lista. Se nenhum estiver
  selecionado, escolhe automaticamente o mob mais forte que o nível do jogador
  permite. O alvo e o status mostram o nível.
- **Auto Raid (aba Raid, raid de verdade)**: implementação baseada em hubs
  públicos (Sankeurr/OpenSource-Blox-Fruits-Script e nyannos/AutoRaid_Improved).
  Sem chip, compra via `CommF_:InvokeServer("RaidsNpc", "Select", elemento)`;
  equipa o Microchip; teleporta para o tubo (`RAID_LOCATIONS[mar].tube`); dispara
  `ProximityPrompt`/`ClickDetector`/`TouchTransmitter` perto do botão; detecta a
  raid por `Remotes.Raids` (`StartTimer`/`Finished`) ou pelo `RaidTimer` da HUD.
  Durante a raid fica **pairando ~55 studs acima do centro da ilha** usando um
  `BodyPosition` (`PrismaRaidHover`, `MaxForce` 1e6, `PlatformStand = true`),
  alto o bastante para os mobs não acertarem. A cada ciclo aplica
  `SimulationRadius` e zera o `Humanoid.Health` de **todos** os mobs no raio de
  ~450 studs (morte/reset instantâneo, sem atacar). Só avança de `Island 1` a
  `Island 5` depois de ~6 s sem nenhum mob na ilha. Inclui seletor de chip,
  comprar chip, checar raid e Auto Awakening (`Awakener Check/Awaken`).
- **Kill Aura instantâneo**: usa o método dos hubs públicos
  `sethiddenproperty(LP, "SimulationRadius", math.huge)` +
  `sethiddenproperty(LP, "MaxSimulationRadius", math.huge)` + `Humanoid.Health = 0`
  em todos os inimigos do raio. O cliente passa a simular os mobs e a morte
  replica no servidor. Como reforço, dispara `RE/RegisterAttack` +
  `RE/RegisterHit` (com `hitId` capturado por `hookmetamethod`) e, se o executor
  não tiver `sethiddenproperty`, cai para os remotes + ataque normal. Raio
  ajustável (10–100 studs, padrão 30). Não afeta jogadores.
- **UI reorganizada em 8 abas**: Farm, Raid, Boss, Combat, ESP, Util, Ilhas, Config.
  - Largura das abas: 58px, padding 3, texto 12 (cabe nas 424px úteis).
- **ESP**: jogadores, bosses, frutas e baús. `Highlight` + `BillboardGui` com
  nome e distância. Cache curto para não pesar (frutas 0.5s, baús 2s).
- **Notificador de frutas**: avisa quando uma fruta nova aparece no chão,
  inclusive as que o **servidor spawna** (filhos diretos do `Workspace`). A
  detecção aceita `Tool`/`Model` com `Handle` quando o nome contém uma fruta
  conhecida (`FRUIT_NAMES`), "Fruit" com prefixo, `ToolTip` `Blox Fruit`,
  `OriginalName` ou nome com "-". Nomes genéricos como **"Fruit"**,
  "FruitSpawn", "FruitDealer" e "PhysicalFruit" são rejeitados (evita o prop
  "Fruit" da Creation). Pastas com "fruit"/"spawn" no nome também são varridas.
- **Timer de spawn**: o jogo só avisa depois que a fruta nasce
  (`Remotes.RadarNotify`). O hub escuta esse remote (alerta imediato) e mantém
  uma contagem estimada: ciclo de ~60 min (45 min no fim de semana), fruta some
  em 20 min. A estimativa é calibrada pela média dos intervalos observados.
  Label na aba ESP + botão "Resetar timer de spawn".
- **Lista de frutas + TP**: aba ESP lista frutas, teleporta e tem "Puxar fruta"
  (grab client-side do Handle).
- **Auto guardar fruta**: varre a mochila (`Backpack`) e guarda frutas via
  `CommF_:InvokeServer("StoreFruit", nome, tool)`. Antes de guardar, conta
  quantas cópias daquela fruta já estão guardadas com `getInventoryFruits` e
  compara com "Espaço por fruta (slots)" (padrão 1, +1 por Fruit Storage).
  Se estiver cheio, não guarda e avisa uma vez. Se o servidor recusar mesmo
  com vaga, o hub reduz a capacidade aprendida. Também há o botão
  "Guardar frutas da mochila agora". Só olha a mochila, nunca a fruta
  equipada no personagem.
- **Auto Quest (1º/2º/3º mar)**: detecta o mar pelo `PlaceId` e usa a tabela de
  quests correspondente (27 do 1º mar, 22 do 2º e 37 do 3º). Cada entrada tem
  nível, mob e remote (`CommF_:InvokeServer("StartQuest", remote, id)`). Lê
  `Player.Data.Level`, escolhe a melhor quest disponível e liga o farm no mob.
  Entrega é manual (botão "Tentar entregar quest" + falar com o NPC).
- **Auto Skills Z/X/C**: usa `Tool.RemoteFunction:InvokeServer` da arma equipada,
  com cooldowns separados. Z manda CFrame; C tem fallback por VirtualInputManager.
  Só dispara com alvo vivo a até 60 studs.
- **Ataque rápido**: reduz o delay do ataque para ~0.03s.
- **Auto Stats**: gasta pontos via `CommF_:InvokeServer("AddStat", stat, 1)`,
  com atributo ciclável (Melee/Defense/Sword/Gun/Blox Fruit).
- **Movimento**: fly (BodyVelocity + WASD/Space/Ctrl, velocidade ajustável),
  noclip contínuo e pulo infinito.
- **Servidor**: server hop (lista pública de servidores via `HttpGet`),
  reconectar neste servidor e auto rejoin (detecta `ErrorPrompt`).
- Kill switch atualizado: desliga ESP, frutas, skills, stats, quest, fly,
  noclip, pulo infinito, auto rejoin e todos os toggles.
- Save/load agora inclui `flySpeed` e `statTarget`.
- Continua sem speed (removido na 1.3 por não funcionar).

### Mudanças da 1.3
- Lista de mobs agora usa **`Workspace.Enemies`**: só aparece o que é matável.
  NPCs de missão e outras entidades ficam de fora.
- Bosses separados dos mobs comuns por lista de nomes (`BOSS_NAMES`).
- **Nova aba Boss**: lista apenas bosses vivos no servidor, com contagem.
  Clique seleciona; toggle **Auto Boss** liga o farm de boss.
- **Correção do auto farm não atacar**: antes de cada ataque o hub reequipa
  a última arma usada (o jogo desequipa tools durante/depois do TP).
  - `watchTools` registra a última arma equipada.
  - `equipWeapon` tenta `Humanoid:EquipTool` e, se falhar, move a tool
    direto para o Character.
  - `attackOnce` chama `tool:Activate()` + clique VirtualUser.
- Farm agora chega a **10 studs** do alvo (corpo a corpo real), não só ao
  range do slider.
- Depois do TP: zera velocidade, cancela PlatformStand/Sit, muda estado
  Physics/FallingDown para Running e vira o personagem para o mob.
- Hitbox do alvo aumentada para **20x20x20** e mob congelado
  (`PlatformStand`/`Sit`/`WalkSpeed 0`) para o golpe corpo a corpo registrar.
- Antes de cada golpe o alvo é **puxado para 4 studs na frente do player**
  (magnet client-side), garantindo o acerto mesmo se o TP falhar.
- Botão **Reequipar arma** nas abas Farm e Boss.
- Se o Auto Farm for ligado sem alvo, escolhe o primeiro mob disponível.
- 5 abas (Farm, Boss, Util, Ilhas, Config); largura das abas ajustada.

### Mudanças da 1.2
- Lista de mobs mostra **todos os mobs do servidor**, com contagem por tipo
  (ex: `Bandit (12)`), escaneando o Workspace inteiro.
- Clicar no mob **só seleciona**. O teleporte/farm começa apenas quando o
  toggle **Auto Farm** é ligado.
- Clicar no jogador **só seleciona**. Botões separados:
  - `TP para jogador selecionado`
  - `Espectar jogador selecionado`
  - `Parar de espectar`
- Teleporte reescrito: **movimento contínuo a 300 studs/s** (passo a passo),
  com noclip durante o trajeto e status de progresso ("faltam X studs").
  O método antigo (CFrame direto + tween) era revertido pelo jogo.
- Limite de 60s por teleporte; se não chegar, mostra "TP bloqueado".
- `maxScan` subiu para 100000.

### Mudanças da 1.1
- Lista de mobs clicável (scroll) na aba Farm: clique no mob → define alvo,
  teleporta e liga o auto farm.
- Lista de jogadores clicável (scroll) na aba Util: clique → teleporta.
- Botão "Espectar jogador selecionado" e "Parar de espectar".
- Ilhas com **coordenadas reais** por mar (PlaceId), não mais busca por nome.
- Botões de viagem entre mares via `CommF_:InvokeServer("TravelMain"/"TravelDressrosa"/"TravelZou")`.
- Ghost Ship via `CommF_:InvokeServer("requestEntrance", Vector3)`.
- Teleporte com duas tentativas: CFrame direto, depois tween (velocidade 365–900).
- Feedback em tela para todo TP: "TP ok", "TP bloqueado (dist X)", "sem personagem".
- Speed removido (não funcionava).
- Spawn: procura `SpawnLocation` recursivo, fallback na posição capturada no boot.
- Erros de botão agora aparecem no status (não são mais engolidos por pcall).

### Coordenadas das ilhas (fonte)
Obtidas de scripts públicos de Blox Fruits. Podem mudar em updates.
Ficam em `ISLANDS` no topo do `hub.lua`, agrupadas por mar:
- `[1]` primeiro mar (PlaceId 2753915549)
- `[2]` segundo mar (PlaceId 4442272183)
- `[3]` terceiro mar (PlaceId 7449423635)

### Pontos a testar
- Aba Farm → "Atualizar lista de mobs" → só deve listar mobs matáveis do `Workspace.Enemies`.
- Clicar no mob → só seleciona. "TP para mob selecionado" teleporta. Ligar Auto Farm → ele vai, reequipa a arma e ataca.
- Aba Farm → ligar "Auto Quest (todos os mares)" → confere se o nível é lido em `Player.Data.Level`,
  se a quest inicia (`StartQuest`) e se o farm vai no mob certo. Entrega é manual.
- Aba Boss → "Atualizar lista de bosses" → deve listar bosses vivos. "TP para boss selecionado" ou Auto Boss.
- Aba Combat → Auto Skills Z/X/C com uma arma que tenha `RemoteFunction`; conferir cooldowns.
  "Ataque rápido" reduz o delay; "Auto Stats" deve gastar pontos no atributo escolhido.
- Aba ESP → ligar um destaque por vez. Se o FPS cair, desligar "ESP baús" (varredura do mapa).
  Lista de frutas → selecionar → TP/Puxar.
- Aba ESP → "Guardar frutas": ajustar "Espaço por fruta" para o total real (padrão 1;
  +1 por Fruit Storage). Com fruta na mochila, "Guardar frutas da mochila agora" deve
  guardar só se houver vaga; com espaço cheio deve avisar e não guardar.
  O toggle automático repete a checagem a cada 1,5s.
- Aba Util → fly (WASD/Space/Ctrl), noclip, pulo infinito, server hop e auto rejoin.
- Aba Util → clicar no jogador → só seleciona. Usar botão de TP ou Espectar.
- Aba Ilhas → cada botão deve teleportar; viagem de mar via remote.
- Se aparecer "TP bloqueado", o jogo está revertendo o movimento mesmo a 300 studs/s.
  Mesmo assim o farm puxa o mob para perto e ataca.
- Se o farm chegar e não atacar, usar "Reequipar arma" e conferir o nome da tool.

---

## 9. Log de sessões

### 2026-11-07
- Definido planejamento completo do hub.
- Decisões fechadas: custom UI, arquivo único, sem key, PC only, anti-detecção sim.
- Escopo inicial = Fase 1.
- Criado este arquivo de memória.
- Fase 1 implementada em `hub.lua`.
- Corrigido erro de compilação (`...` em função aninhada) que impedia tudo de rodar.
- Hub abriu em jogo.
- Fase 1.1: listas clicáveis, coordenadas reais das ilhas, espectar, speed removido,
  feedback de TP, viagem entre mares.
- Fase 1.2: lista de mobs completa com contagem, clique só seleciona,
  clique em jogador só seleciona (TP em botão separado), teleporte por
  movimento contínuo a 300 studs/s com noclip.
- Fase 1.3: lista via `Workspace.Enemies` (só matável), aba Boss separada,
  reequipamento automático de arma antes do ataque, farm corpo a corpo a
  10 studs, reset de estado do Humanoid após TP, botão Reequipar arma.
- Pendente: teste em jogo da 1.3.

### 2026-11-08
- Pesquisado hub público aberto (xHeptc/BloxFruits) como referência de remotes:
  `ReplicatedStorage.Remotes.CommF_`, `StartQuest`, padrão de skills
  `Tool.RemoteFunction:InvokeServer("Z"/"X")` e frutas como Tool no Workspace.
- Implementado o pacote "Tudo" na 1.4: ESP (jogadores/bosses/frutas/baús),
  notificador de frutas, lista + TP + grab de frutas, Auto Quest do 1º/2º/3º mar,
  Auto Skills Z/X/C, ataque rápido, Auto Stats, fly, noclip, pulo infinito,
  server hop, auto rejoin e reconectar.
- UI passou de 5 para 7 abas (Farm, Boss, Combat, ESP, Util, Ilhas, Config),
  com largura 58/padding 3/texto 12.
- Kill switch e save/load atualizados para as novas features.
- Sintaxe validada com luaparse (`OK: sintaxe valida`).
- Renomeado para **Prisma Hub** e UI refeita no estilo de hub genérico
  (sidebar, tema escuro, acento violeta). Publicado no GitHub (`prisma-hub`).
- Pendente: teste em jogo da 1.4 (principalmente ESP, Auto Quest, skills,
  fly e server hop).

### 2026-11-09
- Auto Quest expandido para **1º, 2º e 3º mar**. Tabelas por mar (27/22/37
  entradas), seleção automática pelo `PlaceId` (`CURRENT_SEA`). Removido o
  bloqueio que impedia ligar a feature fora do 1º mar.
- Label "Mar detectado" adicionada na aba Farm.
- Teleporte com deadline maior para distâncias longas (até 180s) e cancelável
  quando o farm/boss é desligado, ajudando o farm em ilhas distantes do 2º/3º mar.
- Referência das quests: repositório aberto `Sankeurr/OpenSource-Blox-Fruits-Script`.
- Sintaxe validada (`OK: sintaxe valida`).
- Lista de mobs passou a mostrar nível e o Auto Farm escolhe automaticamente o
  mob mais forte que o nível do jogador permite (ou o mob clicado).
- Adicionados **Auto Raid** (progressão ilha por ilha com entrega automática de
  quest) e **Kill Aura** (raio ajustável de 10–100 studs). Kill switch e
  save/load atualizados (`killAuraRange`). Sintaxe validada.
- **Espectar** virou um único toggle: o mesmo clique liga e desliga (removido o
  botão separado "Parar de espectar"). Trocar o jogador selecionado enquanto
  especta muda o alvo automaticamente.
- **Kill Aura** agora é **instantâneo**: usa `sethiddenproperty` para elevar
  `SimulationRadius`/`MaxSimulationRadius` ao infinito e zera o
  `Humanoid.Health` de todos os inimigos do raio (mesmo método de hubs públicos
  como DragonHUB/Btteam/RimuraHub). Reforço com `RE/RegisterAttack` +
  `RE/RegisterHit` e fallback para ataque normal quando `sethiddenproperty` não
  existe no executor.
- **Farm instantâneo** (`State.instantFarm`, toggle na aba Farm, ligado por
  padrão): `engageEnemy` chama `instantKillMob`, que aplica o mesmo método no
  alvo do Auto Farm/Auto Quest. Salvo/carregado no config.
- **Aba Raid** criada e **Auto Raid de verdade** implementado (base:
  Sankeurr/OpenSource-Blox-Fruits-Script e nyannos/AutoRaid_Improved):
  compra/equipa Microchip, teleporta ao tubo da raid, dispara prompts do botão,
  detecta início/fim por `Remotes.Raids`, limpa as ondas com morte instantânea e
  avança de `Island 1` a `Island 5`. Também adicionados seletor de chip,
  "Comprar chip", "Checar raid" e **Auto Awakening**. O antigo "Auto Raid (ilha
  por ilha)" de quests foi removido da aba Farm (o Auto Quest continua lá).
  Sintaxe validada.
- **Auto Raid 1.6 (pairando, como o hub público testado)**: durante a raid o
  personagem fica pairando a ~55 studs acima do centro da ilha via `BodyPosition`
  (`PrismaRaidHover`) + `PlatformStand`, longe do alcance dos mobs. A cada ciclo
  aplica `forceSimulationRadius()` e zera o `Humanoid.Health` de **todos** os
  mobs dentro de ~450 studs (morte/reset instantâneo, sem ataque nem TP por
  mob). Só troca de ilha após ~6 s sem mobs (`State.raidIsland`,
  `State.raidClearSince`). O hover é removido ao desligar o Auto Raid, ao acabar
  a raid, no kill switch e ao voltar para o tubo. Ligar o Auto Raid desliga o
  Fly (BodyVelocity brigaria com o BodyPosition). Novos helpers:
  `raidSetHover`, `raidStopHover`, `raidCurrentIsland`, `raidIslandPart`,
  `raidMobsNear`. Versão 1.6. Sintaxe validada.
- **Botão de reabrir no canto**: o "P" que reabre o hub saiu do centro e agora
  fica fixo no **canto superior direito** (`Position = UDim2.new(1, -58, 0, 12)`,
  `ZIndex = 50`).
- **Notificador cobre frutas spawnadas pelo servidor**: `isFruitTool` foi
  reescrito para aceitar `Tool` e `Model` com `Handle` e detectar por nome
  ("Fruit"), `ToolTip == "Blox Fruit"`, `OriginalName`, nome com "-"
  ("Rocket-Rocket") ou nome simples de fruta (`FRUIT_NAMES`, 50 frutas).
  `collectFruits` também varre pastas com "fruit"/"spawn" no nome. "Puxar fruta"
  passou a usar `fruitHandle` (funciona com Model também). Sintaxe validada.
- **Correção do falso "Fruit" + timer de spawn**: nomes genéricos
  (`fruit`, `fruits`, `fruitspawn`, `fruitdealer`, `physicalfruit`,
  `fruitmodel`, etc.) agora são rejeitados. `FRUIT_NAMES` é comparado com
  limites de palavra e o "Fruit" só entra se tiver prefixo (ex. "Rocket Fruit").
  Adicionado timer estimado na aba ESP: escuta `Remotes.RadarNotify` para
  alerta imediato, assume ciclo de 60 min (45 min no fim de semana) e calibra
  pela média dos intervalos observados. Botão "Resetar timer de spawn".
  Sintaxe validada.
- **Auto guardar fruta (1.8)**: `fruitBaseKey`, `fruitDisplayName`,
  `fruitStoreName`, `isBackpackFruit`, `getStoredFruitCounts`, `tryStoreFruit`,
  `fruitStorePass` e `fruitStoreLoop`. Conta as frutas guardadas por tipo via
  `getInventoryFruits`, compara com `State.fruitStoreCapacity` (slider "Espaço
  por fruta", 1–50, salvo no config) e só chama `StoreFruit` se houver vaga.
  Verifica se o tool saiu da mochila para confirmar; se o servidor recusar com
  vaga na conta, diminui a capacidade aprendida. Botão manual na aba ESP.
  Sintaxe validada.
- **Correção do grab puxando ilhas (1.8.1)**: a detecção usava
  `fruitNameHasKnown` em qualquer posição do nome, então Models de ilha como
  "Ice Castle" (Ice) e "Magma Village" (Magma) entravam na lista de frutas, e o
  grab pegava uma parte qualquer do modelo com `FindFirstChildWhichIsA`. Agora
  `isFruitTool` exige um `Handle` como **filho direto** (BasePart), aceita
  `Tool` com `ToolTip` "Blox Fruit", `OriginalName` com "Fruit" ou nome
  `Base-Base`, e só aceita nome simples de fruta quando é o nome inteiro
  ("Rocket"), nunca nome composto ("Ice Castle"). "Puxar fruta" revalida o alvo
  e usa só o `Handle` direto. `fruitHandle` e `fruitNameHasKnown` removidos.
  Sintaxe validada.
- **Kill switch / descarregar hub (1.8.2)**: botão **"PARAR TUDO"** no rodapé
  da sidebar (sempre existiu). Adicionados atalhos **RightShift** (mostra/esconde
  a janela) e **End** (roda o kill switch e destrói a GUI). Aba Config ganhou o
  botão "Descarregar hub (parar tudo e fechar)". Ao reexecutar, o hub agora
  remove ScreenGuis antigas com prefixo `PrismaUI_` para não empilhar interfaces.
  Sintaxe validada.
- **Correção de boot/GUI invisível (1.8.3)**: `resolveGuiParent` agora valida
  o tipo do parent (`PlayerGui`, `CoreGui` ou `Folder` com parent) antes de usar
  `gethui`, caindo para o `PlayerGui` se o `gethui` devolver algo inválido. A
  remoção de GUIs antigas roda com `pcall` por item e nunca destrói o próprio
  parent. Se a ScreenGui não for aceita, ela é reparentada no `PlayerGui`. Logs
  `warn("[Prisma] ...")` mostram o parent e falhas de boot no console (F9).
  Sintaxe validada.
