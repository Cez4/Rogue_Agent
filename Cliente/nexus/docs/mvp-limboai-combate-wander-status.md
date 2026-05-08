# MVP LimboAI + Combate + Wander - Status Tecnico

Data: 2026-05-08
Branch: `feat/mvp-combate-fase1`

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
2. Prioridade de ataque:
   - Se `attack` foi pressionado, chama `request_attack()` e encerra o evento.
3. Se nao for ataque, segue para `move_click` no controller.
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

## LimboAI no projeto
- HSM para estados de locomocao/ataque no actor.
- BT para vida de NPC (look/wander com cooldown/janela de interesse).
- Emotes acionados por comportamento (ex: surpresa ao notar player, assovio ao vagar).

## Multiplayer-ready (diretriz em andamento)
- Cliente: enviar intencao (input/move/attack request).
- Host/servidor: validar alvo/nav/range/cooldown e simular estado oficial.
- Replica para clientes: posicao, velocidade, estado e eventos de combate.
- Cliente: predicao/interpolacao apenas visual.

## Proximos passos tecnicos
1. Feedback de hit:
   - FX local de impacto, flash de dano, popup de numero.
2. Telemetria de combate:
   - eventos: attack_start, attack_active, hit_confirmed, damage_applied, attack_end.
   - campos minimos: actor_id, target_id, action_id, timestamp, dir, damage.
3. Validacao para futuro multiplayer:
   - gates de range/LOS/cooldown centralizados.
4. Padrao para NPCs:
   - manter BT + tasks reutilizaveis para todos os NPCs base.

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
