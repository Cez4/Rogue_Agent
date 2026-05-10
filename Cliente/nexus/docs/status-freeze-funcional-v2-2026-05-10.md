# Status Freeze Funcional v2 (Orb V3 + Stamina)

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

4. Stamina de combate (consolidado)
- `StaminaComponent` ativo em player e hostis principais.
- Custo de stamina data-driven via `CombatActionData.stamina_cost`.
- Dreno de stamina no `_enter()` do estado de ataque (nao no request).
- Sem hard-lock por exaustao: ataque falha limpo quando stamina insuficiente.
- BT mantem chase/comportamento ativo em baixa stamina.

5. Orb de Stamina (gamefeel) consolidada
- `CombatOrbPresenter` operando em modo de recurso (`HEALTH`/`STAMINA`).
- Reacao por consumo real de stamina (`stamina_changed` com delta negativo).
- Telemetria de stamina orb ativa:
  - `orb_stamina_react`
  - `orb_stamina_exhausted_pulse`
- Preset data-driven oficial:
  - `configs/ui/orbs/stamina_orb_profile_v1.tres`
- Orb aplicada em player e hostis principais.
6. Hardening recente confirmado
- Gate de stamina no `BTRequestAttack` para reduzir ruído e manter decisao explicita:
  - motivo de bloqueio: `insufficient_stamina`.
  - eventos: `low_stamina_entered` / `low_stamina_exited`.
  - arquivo: `Scripts/ai/tasks/bt_request_attack.gd`.

## Validacao operacional
Gate MCP usado para fechamento:
1. `open_scene(res://cenas/mundo.tscn)`
2. `play_scene(current)`
3. `get_godot_errors` sem erro novo de parse/runtime
4. Telemetria confirmando:
- `orb_visibility`
- `stamina_consumed`, `stamina_exhausted`, `stamina_recovered`
- `low_stamina_entered`, `low_stamina_exited`, `stamina_exhausted_emote`
- `orb_stamina_react`, `orb_stamina_exhausted_pulse`
- `target_died`, `chase_canceled(reason=death)`, `respawned`

## Ajustes de higiene concluidos nesta etapa
1. Removido arquivo indevido `cenas/player.rar` (quando presente).
2. Corrigido path case-sensitive em:
- `configs/player/player_movement_config.tres`
- de `res://scripts/...` para `res://Scripts/...`.

## Fonte oficial a partir deste ponto
Este arquivo vira a fonte oficial de status funcional congelado da fase atual.

Docs de consolidacao oficial:
1. `docs/README.md` (mapa de leitura)
2. `docs/arquitetura-contratos-estado-atual-2026-05-10.md` (contratos, decisoes, exemplos)

## Proximo passo (apos freeze)
Somente tuning de game feel (sem mudar arquitetura):
1. manter `stamina_orb_profile_v1.tres` como visual unico global (sem perfil de orb por archetype);
2. calibrar diferenca por dados de combate (`stamina_cost` e cadencia em `CombatActionData`);
3. validar por telemetria (`orb_stamina_react` / `orb_stamina_exhausted_pulse`);
4. manter gate MCP por microciclo.

Plano estrategico da proxima fase:
1. `docs/plano-estrategico-gamefeel-stamina-actions-v1-2026-05-10.md`

## Baseline stamina v1 (fechado)
1. Regra oficial:
- orb visual unica global (`stamina_orb_profile_v1.tres`);
- variacao entre archetypes por `CombatActionData.stamina_cost`.
2. Valores aprovados por telemetria isolada:
- `HostileEnemyLight`: `stamina_cost = 14.0` (`orb_stamina_react.spent_ratio = 0.14`)
- `Wildcat`: `stamina_cost = 20.0` (`orb_stamina_react.spent_ratio = 0.20`)
- `HostileEnemyBrute`: `stamina_cost = 28.0` (`orb_stamina_react.spent_ratio = 0.28`)
3. Fluxo validado:
- `stamina_consumed -> stamina_exhausted -> low_stamina_entered -> stamina_recovered -> low_stamina_exited`.
