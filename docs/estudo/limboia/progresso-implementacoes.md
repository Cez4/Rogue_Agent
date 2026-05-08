# Progresso de Implementações (Godot + LimboAI)

## Objetivo deste documento
Registrar cada passo funcional concluído no projeto para manter rastreabilidade técnica, facilitar onboarding e evitar regressões.

---

## 2026-05-08 - Movimento base + IA inicial de NPCs

### 1) Player/NPC com base comum de ator 8 direções
Status: **Concluído e funcional**

Implementado:
- Base compartilhada de ator em `actor_8dir_limbo.gd`.
- Suporte a animações direcionais 8-dir para idle/walk/attack.
- Integração com `NavigationAgent2D` + `PlayerMotor`.
- Proteções para input de ataque apenas no player controlável.

Arquivos principais:
- `Cliente/nexus/Scripts/actors/actor_8dir_limbo.gd`
- `Cliente/nexus/Scripts/actors/state_idle_8dir.gd`
- `Cliente/nexus/Scripts/actors/state_walk_8dir.gd`
- `Cliente/nexus/Scripts/actors/state_attack_8dir.gd`

---

### 2) Wildcat com “vida” básica (Idle + Wander)
Status: **Concluído e funcional**

Implementado:
- Ativação de `enable_wander` com timers/raio aleatórios.
- Estado de wander ligado ao fluxo de animação e movimentação.

Arquivos principais:
- `Cliente/nexus/Scripts/actors/state_wander_8dir.gd`
- `Cliente/nexus/cenas/wildcat_1.tscn`

---

### 3) Evitação entre agentes (fim do “agarrando”)
Status: **Concluído e funcional**

Problema resolvido:
- Player e NPCs travavam entre si ao cruzar caminho.

Solução:
- Avoidance real via `NavigationAgent2D` (`set_velocity` + `velocity_computed`).
- Configuração data-driven de avoidance no movement config.
- Ajuste de layer/mask para evitar bloqueio físico entre personagens.

Arquivos principais:
- `Cliente/nexus/Scripts/player/player_motor.gd`
- `Cliente/nexus/Scripts/player/player_movement_config.gd`
- `Cliente/nexus/cenas/player.tscn`
- `Cliente/nexus/cenas/villager_1.tscn`
- `Cliente/nexus/cenas/wildcat_1.tscn`

Doc relacionado:
- `docs/estudo/arquitetura-ia/avoidance-player-npc.md`

---

### 4) Padrão oficial de NPC com LimboAI
Status: **Concluído**

Definido:
- Diretriz para todos NPCs com LimboAI (HSM/BT/Blackboard).
- Roadmap de evolução de IA.
- Regra multiplayer autoritativa.

Doc relacionado:
- `docs/estudo/limboia/padrao-npcs-limboai.md`

---

### 5) Villager migrado para BT com LookAtPlayer + Wander
Status: **Concluído e funcional**

Implementado:
- `BTPlayer` no Villager.
- BT com aquisição de alvo (`player`), checagem de distância e ação de olhar.
- Fallback de comportamento contínuo idle/wander.

Arquivos criados:
- `Cliente/nexus/Scripts/ai/tasks/bt_acquire_target_in_group.gd`
- `Cliente/nexus/Scripts/ai/tasks/bt_is_target_in_range.gd`
- `Cliente/nexus/Scripts/ai/tasks/bt_look_at_target.gd`
- `Cliente/nexus/Scripts/ai/tasks/bt_idle_wander_loop.gd`
- `Cliente/nexus/ai/trees/npc/villager_look_wander_bt.tres`

Arquivo ajustado:
- `Cliente/nexus/cenas/villager_1.tscn`

---

### 6) Tuning anti-spam do “Look” (problema: anda/olha repetindo)
Status: **Concluído e funcional**

Problema:
- Villager alternava “andando e olhando” em excesso.

Ajustes aplicados:
- Look só quando NPC está parado.
- Ao iniciar look, NPC para o movimento.
- Faixa de distância curta (quase colado):
  - `look_interest_min_distance = 52`
  - `look_interest_max_distance = 84`
- Cooldown longo com aleatoriedade:
  - `look_cooldown_sec = 8.0`
  - `look_cooldown_jitter_sec = 3.0`
- BT com:
  - `BTDynamicSelector` (reavaliação contínua)
  - `BTProbability(0.4)` no ramo de look
  - `BTCooldown(8.0)`

Arquivos principais:
- `Cliente/nexus/Scripts/actors/actor_8dir_limbo.gd`
- `Cliente/nexus/Scripts/ai/tasks/bt_look_at_target.gd`
- `Cliente/nexus/Scripts/ai/tasks/bt_is_target_in_range.gd`
- `Cliente/nexus/ai/trees/npc/villager_look_wander_bt.tres`
- `Cliente/nexus/cenas/villager_1.tscn`

---

## Validação de execução
Fluxo de validação usado:
- Godot MCP com `open_scene`, `play_scene`, `get_scene_tree`, `get_godot_errors`.
- Cena de validação principal: `res://cenas/mundo.tscn`.

Estado atual:
- Sem erro crítico de runtime nas últimas validações.
- Comportamentos base solicitados funcionando.

---

## Próximos passos naturais
1. Aplicar o mesmo padrão BT (look+wander anti-spam) no `wildcat`.
2. Extrair parâmetros de percepção/cooldown para resource por tipo de NPC.
3. Evoluir para blackboard compartilhado por grupo/facção (quando necessário).
4. Começar camada de replicação autoritativa para IA no host.

