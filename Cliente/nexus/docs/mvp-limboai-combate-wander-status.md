# MVP LimboAI + Combate + Wander - Status Tecnico

Data: 2026-05-08
Branch historica: `feat/mvp-combate-fase1`  
Estado atual consolidado: `feat/combat-intent-fase4`

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
3. Feedback de hit:
   - FX local de impacto, flash de dano, popup de numero.
4. Validacao para futuro multiplayer:
   - gates de range/LOS/cooldown centralizados no host.
5. Padrao para NPCs:
   - manter BT + tasks reutilizaveis para hostis, companions e bosses.

## Arquivos-chave
- Actor base:
  - `Scripts/actors/actor_8dir_limbo.gd`
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
