# Brute Tuning Session Protocol v1

Data: 2026-05-09
Status: em execucao (freeze v1)

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
