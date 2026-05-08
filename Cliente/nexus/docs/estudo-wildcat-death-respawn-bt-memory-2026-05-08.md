# Estudo Tecnico - Wildcat Death/Respawn e Memoria de Combate

Data: 2026-05-08  
Cena validada: `res://cenas/mundo.tscn`  
Branch: `feat/bt-perception-fase6`

## Problemas reportados
1. Ao morrer, o Wildcat nao tocava `Die_*` e podia ficar visualmente travado em `Walk_*` ou `Attack_*`.
2. Em alguns testes de BT, apareceu erro:
   - `Blackboard: Variable "combat_target" not found` em `bt_request_attack.gd`.
3. Antes do ajuste de reset, no respawn o inimigo podia nascer com memoria de alvo.

## Causas raiz
1. Morte sem isolamento completo de estado:
   - BT e/ou HSM ainda podiam atualizar animacao no mesmo ciclo.
2. `bt_request_attack` lia `combat_target` sem checar `has_var`.
3. Respawn sem reset total da memoria de combate no blackboard.

## Correcoes aplicadas

### 1) Morte com estado visual explicito e travamento de logica
Arquivo: `Scripts/actors/actor_8dir_limbo.gd`

- Adicionado `die_prefix = "Die"`.
- No `death`:
  - `_is_dead = true`
  - `hsm.set_active(false)`
  - `BTPlayer.active = false`
  - `cancel_all_intents()`
  - `_play_die_animation()` com `Die_<dir>` nao-loop.
- Em `_physics_process`, retorno imediato quando `_is_dead` para evitar sobrescrita de animacao.

### 2) Respawn com reset de memoria de combate
Arquivo: `Scripts/actors/actor_8dir_limbo.gd`

- Em `_respawn_after_delay()`:
  - `reset_health()`
  - `global_position = _spawn_position`
  - `velocity = Vector2.ZERO`
  - `_reset_combat_memory()` apagando vars:
    - `combat_target`
    - `combat_target_last_seen_ms`
    - `combat_next_reacquire_ms`
    - `attack_task_started`
    - `last_attack_blocked_reason`
  - `motor.stop()`
  - `play_idle_animation()`
  - reativacao controlada:
    - `hsm.set_active(true)`
    - `BTPlayer.active = true` apos `respawn_brain_delay_sec`

### 3) Guard de blackboard no request attack
Arquivo: `Scripts/ai/tasks/bt_request_attack.gd`

- `combat_target` agora e lido apenas quando `blackboard.has_var(target_var)`.

### 4) Telemetria de bloqueio com menos ruido
Arquivo: `Scripts/ai/tasks/bt_is_combat_target_in_attack_range.gd`

- `attack_blocked_reason` agora so emite evento quando o motivo muda.
- Corrigido acesso seguro de var ausente no blackboard.

## Evolucao do Wildcat BT
Arquivo: `ai/trees/npc/wildcat_look_wander_bt.tres`

- Migrado para pipeline de combate completo com fallback:
  - acquire combat target (raio data-driven)
  - validate alive
  - validate perception
  - chase
  - in-range -> face -> attack
  - fallback idle/wander

## Validacao MCP
Ferramentas usadas:
- `open_scene`
- `play_scene`
- `get_scene_tree`
- `get_godot_errors`

Resultado:
- Sem novo erro critico de runtime apos os fixes.
- Ciclo de morte/respawn estabilizado.
- Reset de memoria no respawn confirmado.

