# Guia de Saude do Projeto (Godot + LimboAI)

Data: 2026-05-09  
Escopo: manter arquitetura saudavel, previsivel e escalavel sem regressao.

## 1) Guardrails de arquitetura (obrigatorio)
1. BT decide, HSM executa, Motor locomove.
2. Nao duplicar logica de chase/ataque fora de tasks BT quando `use_bt_brain=true`.
3. Toda regra de tuning deve ficar em dados (`.tres`), nunca hardcode em task.
4. Toda mudanca de fluxo deve preservar `intent` contextual (input nao acoplado a acao fixa).

## 2) Blackboard (LimboAI) - boas praticas
1. Declarar dependencias no BlackboardPlan (evitar depender de escopo pai implicitamente).
2. Usar mapping explicito BT <-> HSM quando compartilhar variaveis.
3. Centralizar nomes de chaves em constantes (`AIBlackboardKeys`), sem string solta.
4. Em tasks, usar `get_var(..., default)` e `has_var` para evitar erro de variavel ausente.

## 3) Navigation/Avoidance (Godot) - boas praticas
1. Chamar `get_next_path_position()` a cada frame de fisica ao perseguir.
2. Usar avoidance so onde necessario (custo cresce com muitos agentes).
3. Ajustar `neighbor_distance`/`max_neighbors` para evitar custo excessivo.
4. Lembrar: avoidance nao substitui pathfinding e nao altera navmesh.

## 4) Telemetria e observabilidade
1. Combate sempre observavel: `target_acquired`, `attack_commit`, `hit_confirmed`, `target_died`.
2. Decisao BT observavel por `task/status/reason` (com dedupe/throttle).
3. Cancelamento de chase classificado por `reason/manual_lock` para evitar falso positivo de kite.
4. Ler `reason=input_move` como cancelamento intencional do jogador.

## 5) Processo de mudanca (qualidade)
1. Um eixo de tuning por ciclo (targeting OU approach OU cadence OU survivability).
2. Gate MCP por bloco:
   - `open_scene`
   - `play_scene`
   - `get_godot_errors`
3. Registrar antes/depois em `combat-tuning-matrix-v1.md`.
4. Git serial obrigatorio:
   - `add -> commit -> status(ahead) -> push -> status(final) -> rev-list 0 0`.

## 6) Proximo nivel (fase seguinte)
1. Criar template base de inimigo hostil reutilizavel (BT/HSM + profile v1).
2. Reutilizar Wildcat como referencia de baseline.
3. Aplicar checklist de regressao em todo novo inimigo antes de integrar em mapa principal.

## Referencias oficiais usadas
1. Godot NavigationAgent2D:
   - https://docs.godotengine.org/en/4.1/classes/class_navigationagent2d.html
2. Godot Using NavigationAgents / Avoidance:
   - https://docs.godotengine.org/en/4.0/tutorials/navigation/navigation_using_navigationagents.html
   - https://docs.godotengine.org/en/4.0/tutorials/navigation/navigation_using_agent_avoidance.html
3. Godot NavigationObstacles:
   - https://docs.godotengine.org/en/4.4/tutorials/navigation/navigation_using_navigationobstacles.html
4. LimboAI Blackboard best practices:
   - https://limboai.readthedocs.io/en/stable/behavior-trees/using-blackboard.html
5. LimboAI BT core:
   - https://limboai.readthedocs.io/en/latest/classes/class_behaviortree.html
