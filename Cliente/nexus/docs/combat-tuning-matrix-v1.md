# Combat Tuning Matrix v1 (Archetype/Weapon/Status)

Data: 2026-05-08  
Escopo: tuning de combate (sem nova arquitetura)  
Base técnica: Godot + LimboAI + BT/HSM já implementados

## 1) Objetivo
Padronizar tuning de combate por dados para evitar regressão e acelerar balanceamento.

Regras:
1. Não criar sistema novo nesta fase.
2. Não alterar contrato BT/HSM.
3. Alterar somente parâmetros de archetype, arma e status.

## 2) Fonte única de tuning
Toda calibração deve usar apenas 3 camadas:

1. ArchetypeProfile
- `acquire_radius`
- `lose_radius`
- `target_memory_sec`
- `reacquire_interval_sec`
- `attack_stop_buffer`

2. WeaponProfile
- `attack_range`
- `windup_sec`
- `active_sec`
- `recover_sec`
- `cooldown_sec`
- `damage`
- `knockback_enabled`
- `knockback_strength`

3. StatBlock
- `hp`
- `move_speed` (quando entrar no motor por stat)
- `attack_speed` (quando aplicado na cadência)
- `perception` derivados:
  - `combat_acquire_radius`
  - `combat_lose_radius`
  - `combat_target_memory_sec`
  - `combat_reacquire_interval_sec`
- `attack_range_bonus`
- `attack_range_multiplier`
- `attack_stop_buffer`

## 3) Fórmulas oficiais (v1)
Implementação alvo para tuning (compatível com código atual):

1. Alcance final:
`final_attack_range = (weapon.attack_range + attack_range_bonus) * (1.0 + attack_range_multiplier)`

2. Distância de parada:
`attack_stop_distance = max(2.0, final_attack_range - attack_stop_buffer)`

3. Percepção final:
- `final_acquire = max(8.0, combat_acquire_radius)`
- `final_lose = max(final_acquire, combat_lose_radius)`
- `final_memory = max(0.0, combat_target_memory_sec)`
- `final_reacquire = max(0.01, combat_reacquire_interval_sec)`

4. Cadência de ataque (fase futura de stat attack_speed):
`phase_time = clamp(base_phase_time / attack_speed_factor, min_phase, max_phase)`

## 4) Pipeline de tuning (ordem obrigatória)
Aplicar em ciclos curtos na ordem:

1. Targeting
- calibrar `acquire/lose/memory/reacquire`

2. Approach/Stop
- calibrar `attack_range` + `attack_stop_buffer`

3. Attack Cadence
- calibrar `windup/active/recover/cooldown`

4. Survivability
- calibrar `damage`, `hp`, `knockback`, TTK

Não pular ordem para evitar falso positivo.

## 5) Métricas e telemetria (v1)
Eventos obrigatórios:
1. `target_acquired`
2. `target_lost`
3. `reacquire`
4. `attack_commit`
5. `attack_blocked_reason`
6. `target_died`
7. `respawned`

Sinais de problema:
1. `attack_blocked_reason=out_of_range` excessivo durante chase.
2. `target_lost` frequente em curta distância.
3. `reacquire` muito alto com pouco `attack_commit`.

## 6) Tabela de archetypes (preencher por ciclo)
| Archetype | Acquire | Lose | Memory | Reacquire | Stop Buffer | HP | Notes |
|---|---:|---:|---:|---:|---:|---:|---|
| melee_light_v1 | TBD | TBD | TBD | TBD | TBD | TBD | baseline |
| melee_tank_v1 | TBD | TBD | TBD | TBD | TBD | TBD | baseline |
| ranged_skirmisher_v1 | TBD | TBD | TBD | TBD | TBD | TBD | futuro |

## 7) Tabela de armas (preencher por ciclo)
| Weapon | Range | Windup | Active | Recover | Cooldown | Damage | Knockback |
|---|---:|---:|---:|---:|---:|---:|---|
| dagger_v1 | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| claw_v1 | TBD | TBD | TBD | TBD | TBD | TBD | TBD |
| sword_v1 | TBD | TBD | TBD | TBD | TBD | TBD | TBD |

## 8) Checklist de regressão MCP
Cena padrão: `res://cenas/mundo.tscn`

1. `open_scene`
2. `play_scene`
3. Teste de distância curta/média/longa
4. Teste de chase + cancel + reacquire
5. Teste de ataque sequencial e commit
6. Teste de morte + respawn + reset de memória
7. `get_godot_errors` sem erro novo

Critério de aprovação:
1. 0 erro runtime/blackboard.
2. Fluxo BT/HSM estável.
3. Telemetria coerente com o tuning aplicado.

## 9) Guardrails de não regressão
1. BT decide, HSM executa, Motor locomove.
2. Não duplicar chase fora de tasks BT quando `use_bt_brain=true`.
3. Não reintroduzir hardcode de percepção nas tasks.
4. Não alterar input-intent durante tuning.

## 10) Referências
1. Godot NavigationAgent2D:
https://docs.godotengine.org/en/4.5/classes/class_navigationagent2d.html
2. Godot NavigationAgents:
https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html
3. LimboAI BehaviorTree:
https://limboai.readthedocs.io/en/latest/classes/class_behaviortree.html
4. LimboAI BTAction:
https://limboai.readthedocs.io/en/latest/classes/class_btaction.html
5. LimboAI Blackboard:
https://limboai.readthedocs.io/en/latest/behavior-trees/using-blackboard.html
