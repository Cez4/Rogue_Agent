# Brute Tuning Session Protocol v1

Data: 2026-05-09
Status: concluido (freeze v1)

## Baseline atual (antes de ajuste)
1. Profile: `res://configs/combat/profiles/hostile_brute_profile_v1.tres`
   - acquire_radius = 100.0
   - lose_radius = 146.0
   - target_memory_sec = 0.95
   - reacquire_interval_sec = 0.20
   - attack_stop_buffer = 6.2
2. Action: `res://configs/combat/hostile_brute_attack_v1.tres`
   - attack_range = 50.0
   - windup_sec = 0.18
   - active_sec = 0.12
   - recover_sec = 0.30
   - cooldown_sec = 0.42
   - damage = 1.35
   - max_targets_per_attack = 2
3. Cena: `res://cenas/enemies/hostile_enemy_brute.tscn`

## Regra operacional
1. Um eixo por ciclo:
   - T1 Targeting
   - T2 Approach/Stop
   - T3 Cadence
   - T4 Survivability
2. Sem alterar logica core (BT/HSM/scripts).
3. Validacao obrigatoria por ciclo:
   - open_scene -> play_scene -> get_godot_errors
   - leitura de telemetria de combate.

## T1 (Targeting-only) - pronto para coleta
1. Nesta etapa, nao alterar Approach/Cadence/Survivability.
2. Coletar log isolado do Brute (30-60s) com cenarios:
   - engage perto e medio
   - kite com cancelamento por input_move
   - kill + respawn
3. Eventos chave esperados:
   - target_acquired
   - attack_blocked_reason(out_of_range)
   - reacquire
   - attack_commit / hit_confirmed
   - target_died / respawned

## Criterio para aplicar ajuste T1
1. Se houver churn alto de reacquire/target_lost precoce:
   - aumentar lose_radius ou target_memory_sec em passo pequeno.
2. Se houver perseguicao excessiva e sticky em kite:
   - subir reacquire_interval_sec em passo pequeno.
3. Se estavel, manter baseline e marcar T1 aprovado sem mudanca.

## T1 executado (Targeting-only)
1. Resultado: aprovado sem mudanca.
2. Justificativa:
   - sem churn anomalo de `target_lost` no Brute em combate ativo;
   - `reacquire_interval_sec=0.20` coerente com archetype pesado;
   - perdas de lock observadas no player ligadas a `reason=input_move/death`.

## T2 aplicado (Approach/Stop-only)
1. Mudanca:
   - `attack_stop_buffer: 6.2 -> 6.6`
2. Objetivo:
   - reduzir `attack_blocked_reason=out_of_range` em kite, aproximando um pouco mais antes do commit.
3. Escopo:
   - sem alteracao de Targeting/Cadence/Survivability.

## T3 aplicado (Cadence-only)
1. Mudanca:
   - `recover_sec: 0.30 -> 0.32`
   - `cooldown_sec: 0.42 -> 0.46`
2. Objetivo:
   - reduzir pressao continua de ataques do Brute em kite, abrindo janela maior entre commits.
3. Escopo:
   - sem alteracao de Targeting/Approach/Survivability.

## T4 aplicado (Survivability-only)
1. Mudanca:
   - `damage: 1.35 -> 1.25`
2. Objetivo:
   - reduzir letalidade por ciclo do Brute sem alterar ritmo, range ou targeting.
3. Escopo:
   - sem alteracao de Targeting/Approach/Cadence.

## Encerramento da fase (Brute v1 congelado)
1. Profile final:
   - `acquire_radius=100.0`
   - `lose_radius=146.0`
   - `target_memory_sec=0.95`
   - `reacquire_interval_sec=0.20`
   - `attack_stop_buffer=6.6`
2. Action final:
   - `attack_range=50.0`
   - `windup_sec=0.18`
   - `active_sec=0.12`
   - `recover_sec=0.32`
   - `cooldown_sec=0.46`
   - `damage=1.25`
   - `max_targets_per_attack=2`
3. Resultado:
   - comportamento de archetype pesado preservado (cadencia mais lenta, pressao controlada);
   - sem regressao de runtime/parse;
   - telemetria coerente (`attack_commit`, `hit_confirmed`, `target_died/respawned`).
