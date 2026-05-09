# Estudo de Desacoplamento BT/HSM - 2026-05-09

Data: 2026-05-09  
Branch de execucao: `feat/decoupling-audit-pass-v2`

## Objetivo
Reduzir acoplamento dinamico (`has_method`/`.call`) na trilha critica de combate, mantendo comportamento funcional no Godot + LimboAI.

## O que foi aplicado
1. Tipagem explicita de componentes core:
- `Actor8DirLimbo`
- `PlayerController`
- `PlayerMotor`

2. Contrato direto no fluxo de input/combate:
- `PlayerController` chama API direta do actor (`set_combat_target`, `request_attack`, `cancel_all_intents`).
- `actor_8dir_limbo` chama `motor/controller` diretamente (`setup`, `physics_update`, `request_move`, `stop`).

3. Tasks BT com contrato direto:
- `bt_pull_combat_target`
- `bt_acquire_combat_target_in_group`
- `bt_chase_combat_target`
- `bt_request_attack`
- `bt_validate_combat_target_alive`
- `bt_validate_combat_target_perception`
- `bt_face_combat_target_8dir`
- `bt_is_combat_target_in_attack_range`

4. HSM states com menos reflexao:
- `state_idle_8dir`
- `state_walk_8dir`
- `state_wander_8dir`
- `state_attack_8dir`

5. Blackboard keys centralizadas:
- `Scripts/ai/blackboard_keys.gd`
- eliminacao de string literals repetidas nas tasks principais.

6. Runtimes desacoplados:
- `actor_navigation_runtime` sem `has_method/call` no caminho principal de mover/chase.
- `actor_combat_runtime` com tipagem de `HealthComponent` e `Blackboard`.

## Resultado pratico
1. Menor risco de regressao silenciosa por renome de metodo/variavel.
2. Melhor legibilidade de responsabilidades (BT decide, HSM executa, Motor locomove).
3. Menos pontos de reflexao dinamica em runtime na parte critica.

## Validacao realizada
Fluxo de validacao repetido em MCP:
1. `play_scene`
2. `get_godot_errors`

Resultado:
- sem erro novo de parse/runtime.
- combate, morte e respawn funcionais nos logs.
- ruido remanescente de `out_of_range/reacquire` coerente com kite.

## Linhas atuais dos componentes-chave
- `actor_8dir_limbo.gd`: 670
- `actor_combat_runtime.gd`: 109
- `actor_navigation_runtime.gd`: 51
- `actor_animation_runtime.gd`: 42
- `player_controller.gd`: 106
- `player_motor.gd`: 103
- `ai/blackboard_keys.gd`: 12

## Pendencias pequenas (nao criticas)
Restam dois usos defensivos de `has_method`:
1. `player_motor.gd` (`face_dir` opcional)
2. `actor_stats_runtime.gd` (itens heterogeneos)

## Referencias
- LimboAI Blackboard best practices:  
https://limboai.readthedocs.io/en/latest/behavior-trees/using-blackboard.html
- LimboAI BT create/setup:  
https://limboai.readthedocs.io/en/v1.5.0/behavior-trees/create-tree.html
- Godot 4.6 / LimboAI 1.7:  
https://godotengine.org/asset-library/asset/4852
