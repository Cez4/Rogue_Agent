# MVP LimboAI + Combate + Wander - Status Tecnico

Data: 2026-05-09
Branch historica: `feat/mvp-combate-fase1`  
Estado atual consolidado: `feat/actor-combat-profile-runtime`

## Objetivo atual
- Base jogavel com:
  - Player controlado por clique.
  - Ataque 8 direcoes com janela de hit.
  - NPCs com vida (wander/look/emotes) via LimboAI.
- Estrutura pronta para evolucao multiplayer autoritativa (cliente envia intencao, servidor valida/simula).

## Decisoes de arquitetura
- Actor base compartilhado: `Scripts/actors/actor_8dir_limbo.gd`.
- Separacao por responsabilidade:
  - Input/controlador (`PlayerController`).
  - Movimento/nav (`PlayerMotor` + `NavigationAgent2D`).
  - Estado/comportamento (`LimboHSM` e BT para NPC).
  - Combate modular (Health/Hurtbox/Hitbox + `CombatActionData`).
- Configuracao data-driven:
  - Acoes de combate em `.tres` (ex: dano, windup, active, recover, cooldown).

## Fluxo de input e combate (estado atual)
1. Clique entra em `_unhandled_input` do actor.
2. Resolver de intencao define a acao:
   - esquerdo/chao -> move;
   - esquerdo/hostile -> none;
   - direito/hostile -> chase_attack.
3. BT do player decide chase/ataque; HSM executa animacao/ataque.
4. `AttackState` executa:
   - windup -> ativa hitbox -> active -> desativa hitbox -> recover.
5. Estado aguarda fim natural da animacao de ataque antes de finalizar.
6. Flag de ataque pendente e sempre liberada ao finalizar estado (inclui caminho de cooldown).

## Correcoes criticas ja aplicadas
- Padronizacao de input para **uma unica action**:
  - `attack` (minusculo) em `project.godot`.
  - Remocao de fallback duplicado.
- Evitado conflito ataque/movimento no mesmo clique:
  - ataque tem prioridade e retorna antes do fluxo de movimento.
- Bug de travamento de ataque resolvido:
  - limpeza garantida de `_attack_pending`.
- Corte de animacao de ataque resolvido:
  - estado agora sincroniza com fim real da animacao nao-loop.
- Fix de chase por clique direito distante (apos cancelar):
  - `intent none` nao cancela mais todos os estados.
  - aumento de tolerancia de picking (`PICK_RADIUS`).
  - ajuste do BT de combate do player para remover conflito de percepcao no ramo de ataque.
  - doc tecnico: `docs/estudo-fix-chase-right-click-distancia-2026-05-08.md`.
- Wildcat combate BT-first (inimigo simbolo do projeto):
  - BT do wildcat migrado para pipeline de combate completo + fallback wander.
  - task dedicada de aquisicao de alvo por percepcao (`bt_acquire_combat_target_in_group.gd`).
  - telemetria de decisao ativa para wildcat (acquire/reacquire/blocked/commit).
- Ciclo de morte/respawn do wildcat estabilizado:
  - morte toca `Die_*` sem sobrescrita de walk/attack.
  - reset de memoria de combate no respawn (limpa blackboard e target lock).
  - correcao de blackboard missing var em `bt_request_attack`.
  - doc tecnico: `docs/estudo-wildcat-death-respawn-bt-memory-2026-05-08.md`.
- Desacoplamento tecnico BT/HSM (passes v1/v2):
  - tipagem explicita dos componentes core (`Actor8DirLimbo`, `PlayerController`, `PlayerMotor`).
  - remocao de `has_method/.call` na trilha critica de input/combate.
  - centralizacao de keys de blackboard em `Scripts/ai/blackboard_keys.gd`.
  - migracao das tasks principais para `AIBlackboardKeys.*`.
  - docs: `docs/estudo-desacoplamento-bt-hsm-2026-05-09.md`.
- Desacoplamento tecnico BT/HSM (passes v3):
  - `ActorCombatProfileRuntime` extraido (range/percepcao data-driven fora do actor principal).
  - `ActorTargetingRuntime` centraliza acquire/validate/perception/reacquire; tasks BT viraram adaptadoras finas.
  - `CombatBlockedReasons` padroniza motivos de bloqueio (`out_of_range`, `no_valid_target`, etc).
  - `Hitbox/Hurtbox` tipados (`HurtboxComponent`/`HealthComponent`) sem reflexao dinamica.
  - `ActorSetupRuntime` extraido (`_ready`, grupos, setup de config/motor/controller/stats/interactable/sinais/HSM).
  - `ActorLifecycleRuntime` extraido (respawn/reset/reativacao de brain/telemetria).
  - `actor_8dir_limbo.gd` reduzido para 558 linhas.
- Desacoplamento tecnico BT/HSM (passes v4):
  - `ActorActionRuntime` extraido para face/play/wait/orient/finalizacao de ataque.
  - API publica do actor preservada; HSM/BT continuam sem mudanca de comportamento.
  - validacao MCP obrigatoria apos refactor: `open_scene` + `play_scene` + `get_godot_errors`.
  - `actor_8dir_limbo.gd` reduzido para 526 linhas.
- Desacoplamento tecnico BT/HSM (passes v5):
  - limpeza de wrappers privados redundantes no actor (contrato minimo mais enxuto).
  - `actor_8dir_limbo.gd` reduzido para 501 linhas.
- Desacoplamento tecnico BT/HSM (passes v6):
  - consolidacao adicional do contrato minimo: lifecycle/combat wrappers internos removidos.
  - `ActorLifecycleRuntime` passa a chamar runtime de combate diretamente para reset/colisao/brain.
  - `actor_8dir_limbo.gd` reduzido para 473 linhas.
- Desacoplamento tecnico BT/HSM (passes v7):
  - `ActorRuntimeBridge` introduzido para integracao tecnica entre runtimes e actor.
  - runtimes deixam de acessar wrappers `runtime_*` no actor e usam bridge explicito.
  - `actor_8dir_limbo.gd` mantido em 473 linhas com contrato de gameplay estavel.
- Desacoplamento tecnico BT/HSM (passes v8):
  - migracao de estado social/wander/emote para `ActorRuntimeBridge`.
  - remocao dos getters/setters sociais redundantes do actor.
  - `actor_8dir_limbo.gd` reduzido para 469 linhas sem regressao MCP.
- Telemetria de decisao BT (passo inicial):
  - adicionado `Scripts/ai/bt_decision_telemetry.gd` para eventos `bt_decision` com `task/status/reason`.
  - tasks de combate principais instrumentadas:
    - `bt_acquire_combat_target_in_group.gd`
    - `bt_validate_combat_target_alive.gd`
    - `bt_validate_combat_target_perception.gd`
    - `bt_chase_combat_target.gd`
    - `bt_is_combat_target_in_attack_range.gd`
    - `bt_request_attack.gd`
  - flag de controle no blackboard: `debug_bt_decision_telemetry` (default OFF).
  - chave centralizada em `Scripts/ai/blackboard_keys.gd`.

## LimboAI no projeto
- HSM para execucao de locomocao/ataque no actor.
- BT para vida de NPC (look/wander com cooldown/janela de interesse).
- BT de combate ativa no player (`player_combat_bt.tres`) para chase+attack.
- Emotes acionados por comportamento (ex: surpresa ao notar player, assovio ao vagar).

## Multiplayer-ready (diretriz em andamento)
- Cliente: enviar intencao (input/move/attack request).
- Host/servidor: validar alvo/nav/range/cooldown e simular estado oficial.
- Replica para clientes: posicao, velocidade, estado e eventos de combate.
- Cliente: predicao/interpolacao apenas visual.

## Proximos passos tecnicos
1. Calibracao fina por archetype/arma/status com matriz oficial v1:
   - `docs/combat-tuning-matrix-v1.md`
2. Padronizar pipeline BT de combate para novos hostis (base enemy template) apos tuning v1.
3. Finalizar acabamento de desacoplamento residual (nao critico):
   - fechar "boundary 100%": remover ultimos acessos diretos a metodo privado do actor fora do bridge.
   - separar no actor: API de gameplay (BT/HSM/Controller) vs API tecnica (bridge-only).
   - consolidar duplicidade de timers/estado entre `actor_social_runtime` e `actor_wander_runtime`.
   - adicionar telemetria tecnica de boundary em modo debug.
4. Evoluir telemetria BT:
   - ampliar cobertura para tasks sociais/wander.
   - opcional: eventos enter/exit separados por task para analise de arvore.
4. Feedback de hit:
   - FX local de impacto, flash de dano, popup de numero.
5. Validacao para futuro multiplayer:
   - gates de range/LOS/cooldown centralizados no host.
6. Padrao para NPCs:
   - manter BT + tasks reutilizaveis para hostis, companions e bosses.

## Arquivos-chave
- Actor base:
  - `Scripts/actors/actor_8dir_limbo.gd`
- Runtimes de setup/lifecycle:
  - `Scripts/actors/services/actor_setup_runtime.gd`
  - `Scripts/actors/services/actor_lifecycle_runtime.gd`
- Runtime de perfil de combate:
  - `Scripts/actors/services/actor_combat_profile_runtime.gd`
- Runtime de targeting:
  - `Scripts/actors/services/actor_targeting_runtime.gd`
- Estado ataque:
  - `Scripts/actors/state_attack_8dir.gd`
- Componentes combate:
  - `Scripts/combat/health_component.gd`
  - `Scripts/combat/hurtbox_component.gd`
  - `Scripts/combat/hitbox_component.gd`
  - `Scripts/combat/combat_action_data.gd`
- Config combate:
  - `configs/combat/player_light_attack.tres`
- Cena principal:
  - `cenas/mundo.tscn`

## Referencias
- Godot AnimatedSprite2D:
  - https://docs.godotengine.org/en/4.4/classes/class_animatedsprite2d.html
- Godot Area2D:
  - https://docs.godotengine.org/en/stable/classes/class_area2d.html
- LimboAI docs:
  - https://limboai.readthedocs.io/en/latest/
- Estudo data-driven (Athena/rAthena aplicado ao projeto):
  - `docs/estudo-athena-datadriven-aplicacao-rogue-agent-2026-05-08.md`
