# Status Freeze Funcional v2 (Orb V3 + Stamina/Stagger)

Data: 2026-05-10  
Branch de referencia: `feat/combat-orb-ui-contextual`

## Objetivo
Congelar o estado funcional atual do projeto para evitar drift entre docs antigos e implementacao real.

## Fechado e congelado
1. Combate base BT/HSM/Motor
- BT decide.
- HSM executa ataque/estados.
- Motor locomove.
- Fluxo de intencao contextual em producao.

2. Data-driven de hostis
- Wildcat, Light e Brute validados.
- Variacao por dados (`combat_perception_profile` e `combat_action_data`), sem script dedicado por inimigo.

3. Orb UI contextual V3 (congelada)
- Orb do player: visivel apenas em combate.
- Orb de hostil: visivel apenas se selecionado e em combate.
- Shader com liquido, trail de dano, alerta de vida baixa, anel de selecao.
- Correcao de sync em respawn/heal aplicada (snap do trail).

4. Stamina + Stagger (consolidado)
- `StaminaComponent` ativo em player e hostis principais.
- Custo de stamina data-driven via `CombatActionData.stamina_cost`.
- Dreno de stamina no `_enter()` do estado de ataque (nao no request).
- `StaggerState` ativo e sem limpar alvo de combate (mantem aggro/memoria de combate).

5. Hardening recente confirmado
- Correcao do race de telemetria no frame de exaustao:
  - evita `attack_started` no mesmo frame de `stamina_exhausted`/`actor_staggered`.
  - arquivo: `Scripts/actors/state_attack_8dir.gd`.

## Validacao operacional
Gate MCP usado para fechamento:
1. `open_scene(res://cenas/mundo.tscn)`
2. `play_scene(current)`
3. `get_godot_errors` sem erro novo de parse/runtime
4. Telemetria confirmando:
- `orb_visibility`
- `stamina_consumed`, `stamina_exhausted`, `actor_staggered`, `stamina_recovered`
- `target_died`, `chase_canceled(reason=death)`, `respawned`

## Ajustes de higiene concluidos nesta etapa
1. Removido arquivo indevido `cenas/player.rar` (quando presente).
2. Corrigido path case-sensitive em:
- `configs/player/player_movement_config.tres`
- de `res://scripts/...` para `res://Scripts/...`.

## Fonte oficial a partir deste ponto
Este arquivo vira a fonte oficial de status funcional congelado da fase atual.

## Proximo passo (apos freeze)
Somente tuning de game feel (sem mudar arquitetura):
1. calibrar stamina cadence por archetype;
2. calibrar impacto visual/ritmo de combate por telemetria;
3. manter gate MCP por microciclo.

