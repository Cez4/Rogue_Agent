# Wildcat Tuning Session Protocol v1

Data: 2026-05-09
Escopo: tuning data-driven do Wildcat (sem alterar arquitetura BT/HSM).

## Objetivo
Executar ciclos curtos de tuning com evidencia de telemetria, alterando um eixo por vez.

## Pré-condições
1. Cena: `res://cenas/mundo.tscn`.
2. Wildcat com profile: `res://configs/combat/profiles/hostile_melee_baseline_v1.tres`.
3. Telemetria:
   - combat: ON
   - thought (bt_decision): ON
   - dedupe/throttle ativos no painel debug
4. Seguir runbook:
   - `Docs/godotmcp/runbook-edicao-segura-cenas.md`

## Sequência de teste por sessão (30-60s)
1. Distância longa:
   - clique direito no Wildcat e observar `target_acquired`, `reacquire`, `attack_blocked_reason`.
2. Distância média:
   - repetir chase/ataque e validar stop sem empurrar.
3. Distância curta:
   - validar cadência de ataque e commit completo da animação.
4. Kite curto:
   - bater/correr para forçar `out_of_range` e validar retorno de chase.
5. Morte/respawn:
   - matar Wildcat, verificar `target_died`/`respawned` e reset de memória.

## Métricas mínimas a coletar
1. `attack_commit` por janela de 30s.
2. frequência de `attack_blocked_reason=out_of_range`.
3. frequência de `target_lost`.
4. frequência de `reacquire` durante chase.
5. presença/ausência de erro runtime em `get_godot_errors`.

## Regras de tuning (obrigatórias)
1. Alterar apenas 1 eixo por ciclo:
   - Targeting (`acquire/lose/memory/reacquire`)
   - Approach/Stop (`attack_stop_buffer`)
   - Cadence (`windup/active/recover/cooldown`)
   - Survivability (`hp/damage`)
2. Não alterar input, arquitetura BT/HSM nem bridge neste ciclo.
3. Sempre validar MCP após ajuste:
   - `open_scene -> play_scene -> get_godot_errors`.
4. Registrar antes/depois na matriz:
   - `docs/combat-tuning-matrix-v1.md`.

## Referências oficiais (pesquisa)
1. Godot `NavigationAgent2D`:
   - https://docs.godotengine.org/en/4.1/classes/class_navigationagent2d.html
2. LimboAI Blackboard:
   - https://limboai.readthedocs.io/en/stable/behavior-trees/using-blackboard.html
3. LimboAI BT debugging:
   - https://limboai.readthedocs.io/en/v1.5.0/behavior-trees/create-tree.html
