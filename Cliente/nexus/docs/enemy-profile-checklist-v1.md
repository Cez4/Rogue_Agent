# Enemy Profile Checklist v1 (Data-Driven)

Data: 2026-05-09  
Escopo: criar novos inimigos hostis sem alterar logica core.

## Objetivo
Padronizar onboarding de novos inimigos usando somente dados (`.tres` + cena template), preservando BT/HSM e evitando drift de script.

## Checklist de criacao (obrigatorio)
1. Derivar cena do template:
- base: `res://cenas/enemies/hostile_enemy_base.tscn`
- nova cena em `res://cenas/enemies/`.

2. Criar profile de percepcao:
- pasta: `res://configs/combat/profiles/`
- campos minimos:
  - `acquire_radius`
  - `lose_radius`
  - `target_memory_sec`
  - `reacquire_interval_sec`
  - `attack_stop_buffer`

3. Criar action de ataque:
- pasta: `res://configs/combat/`
- campos minimos:
  - `attack_range`
  - `windup_sec`
  - `active_sec`
  - `recover_sec`
  - `cooldown_sec`
  - `damage`
  - `one_hit_per_target_per_attack`
  - `max_targets_per_attack`

4. Conectar dados na cena:
- `combat_perception_profile` -> profile do inimigo.
- `combat_action_data` -> action do inimigo.
- confirmar grupos (`hostile`, `npc`) conforme contrato atual.
 - confirmar paridade de componentes de combate:
   - `Health`
   - `Hurtbox`
   - `AttackHitbox`

5. Nao alterar logica:
- proibido editar BT task/script para balancear um inimigo.
- variacao deve ser somente em profile/action/stats.

## Checklist de validacao MCP
1. `open_scene(res://cenas/mundo.tscn)`
2. `play_scene(current)`
3. `get_godot_errors` sem erro novo.
4. Telemetria minima esperada no inimigo novo:
- `target_acquired`
- `attack_started`
- `attack_commit`
- `hit_confirmed` (quando receber/acertar)
- `target_died` + `respawned` (se aplicavel)

## Protocolo de tuning (um eixo por vez)
1. Targeting: `acquire/lose/memory/reacquire`.
2. Approach/Stop: `attack_stop_buffer` + `attack_range`.
3. Cadence: `windup/active/recover/cooldown`.
4. Survivability: `hp/damage/TTK`.

## Fontes oficiais
1. Godot NavigationAgents:
https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html
2. Godot NavigationAgent2D:
https://docs.godotengine.org/en/4.1/classes/class_navigationagent2d.html
3. LimboAI Blackboard:
https://limboai.readthedocs.io/en/latest/behavior-trees/using-blackboard.html
