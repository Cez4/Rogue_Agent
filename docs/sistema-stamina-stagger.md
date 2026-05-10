# Sistema Universal de Stamina e Stagger

## Visao geral
Sistema de recursos de combate data-driven para player e NPCs.

Objetivos:
1. Evitar spam infinito de ataques.
2. Criar janelas de vulnerabilidade com exaustao (stagger).
3. Manter fluxo de combate organico com BT/HSM.

## Arquitetura
1. `StaminaComponent` (`Scripts/stats/stamina_component.gd`)
- `max_stamina`, `regen_rate`, `regen_delay_sec`
- sinais: `stamina_changed`, `exhausted`, `recovered`

2. Custo por ataque data-driven
- definido em `CombatActionData.stamina_cost`
- sem hardcode por inimigo

3. Integracao de combate
- gate de stamina em `request_attack()`
- consumo real no `_enter()` do `state_attack_8dir.gd`
- garante 1 custo para 1 ataque realmente executado

## Stagger (exaustao)
Quando stamina chega a zero:
1. `StaminaComponent` emite `exhausted`
2. actor envia `stagger!` para o LimboHSM
3. transicao para `StaggerState`
4. movimento para, ataque interrompe, mas alvo nao e limpo

Regra de design:
- nao chamar `clear_combat_target()` no stagger
- manter aggro/memoria para a BT retomar naturalmente apos recuperacao

## Telemetria
Eventos principais:
1. `stamina_consumed`
2. `stamina_exhausted`
3. `actor_staggered`
4. `stamina_recovered`

Hardening recente:
- evitado `attack_started` no mesmo frame de `stamina_exhausted`
- implementado em `state_attack_8dir.gd` (early return quando exaustao dispara no enter)

## Criterios de validacao
1. MCP gate sem erro novo:
- `open_scene -> play_scene -> get_godot_errors`
2. Logs coerentes:
- exaustao seguida de stagger
- recuperacao apos threshold
3. Sem regressao em death/respawn/chase.
