# Status Freeze Funcional v2 (Orb V3 + Stamina)

Data: 2026-05-10  
Branch de referencia: `feat/combat-orb-ui-contextual`

## Objetivo
Congelar o estado funcional atual do projeto para evitar drift entre docs antigos e implementacao real.

## Regra de precedencia documental
1. Este arquivo define o baseline funcional estavel.
2. Ajustes em curso ficam no plano da sprint ativa:
- `docs/plano-sprint-port-limbo-demo-tatico-v1-2026-05-10.md`
3. Em divergencia com docs antigos, considerar:
- este arquivo + plano da sprint ativa como fonte de verdade.

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
- Custo data-driven via `CombatActionData.stamina_cost`.
- Dreno no `_enter()` do estado de ataque (nao no request).
- Sem hard-lock por exaustao: ataque falha limpo quando stamina insuficiente.
- BT mantem chase/comportamento ativo em baixa stamina.

5. Orb de stamina (gamefeel) consolidada
- `CombatOrbPresenter` em modo de recurso (`HEALTH`/`STAMINA`).
- Reacao por consumo real de stamina (`stamina_changed` com delta negativo).
- Telemetria ativa: `orb_stamina_react`, `orb_stamina_exhausted_pulse`.
- Preset oficial: `configs/ui/orbs/stamina_orb_profile_v1.tres`.

6. Hardening recente confirmado
- Gate de stamina no `BTRequestAttack` com bloqueio explicito `insufficient_stamina`.
- Eventos: `low_stamina_entered` / `low_stamina_exited`.
- Ajuste para remover falso positivo recorrente `request_attack_not_started`.
- Dedupe de telemetria por assinatura `actor+target+status+reason` em:
  - `bt_chase_state`
  - `bt_inrange_check`

## Validacao operacional
Gate MCP usado:
1. `open_scene(res://cenas/mundo.tscn)`
2. `play_scene(current)`
3. `get_godot_errors` sem erro novo de parse/runtime

Telemetria observada:
- `target_acquired`, `attack_started`, `attack_commit`, `hit_confirmed`
- `attack_blocked_reason` (out_of_range/insufficient_stamina)
- `orb_stamina_react`, `orb_stamina_exhausted_pulse`
- `target_died`, `chase_canceled`, `respawned`

## Fonte oficial a partir deste ponto
1. `docs/README.md` (mapa de leitura)
2. `docs/arquitetura-contratos-estado-atual-2026-05-10.md` (contratos e decisoes)
3. `docs/plano-sprint-port-limbo-demo-tatico-v1-2026-05-10.md` (sprint ativa)

## Sprint aberta (estado atual real)
1. Sprint ativa: portar padrao tatico da demo LimboAI (`arrive/back_away/pursue/in_range`).
2. Progresso atual:
- hostil e player perseguem/atacam com ciclo completo;
- removido ruido critico de `request_attack_not_started`.
3. Restante:
- acabamento de fluidez tatico (reposition/hold);
- limpeza final de ruido de sucesso em combate colado.
4. Regra de execucao:
- primeiro estabilizar BT tatico 100%;
- depois retomar evolucao de features.
