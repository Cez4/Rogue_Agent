# Avoidance Entre Player e NPCs (Godot + LimboAI)

## Contexto
No mapa `mundo.tscn`, o `Player`, `Villager` e `Wildcat` podiam ficar "agarrando" entre si ao cruzar rotas.

## Causa Raiz
1. Pathfinding sem evitação dinâmica efetiva entre agentes móveis.
2. Colisão física direta entre `CharacterBody2D` de personagens.

Resultado: impasse local (engavetamento), mesmo com caminho válido na navmesh.

## Solução Aplicada
### 1) Evitação dinâmica no `NavigationAgent2D`
Foi aplicado no motor compartilhado:
- Arquivo: `Scripts/player/player_motor.gd`
- Uso de:
  - `NavigationAgent2D.set_velocity(desired_velocity)`
  - sinal `velocity_computed(safe_velocity)`
  - movimento final baseado em `safe_velocity` (quando avoidance ativo)

Isso faz os agentes negociarem espaço em tempo real.

### 2) Config data-driven de movimento/avoidance
Foi expandido:
- Arquivo: `Scripts/player/player_movement_config.gd`

Campos adicionados:
- `avoidance_enabled`
- `avoidance_radius`
- `avoidance_neighbor_distance`
- `avoidance_max_neighbors`
- `avoidance_time_horizon`
- `avoidance_layers`
- `avoidance_mask`

Objetivo: ajustar comportamento por tipo de agente sem hardcode.

### 3) Separação de colisão de personagens
Para evitar travamento físico entre personagens:
- `collision_layer = 2`
- `collision_mask = 1`

Aplicado em:
- `cenas/player.tscn`
- `cenas/villager_1.tscn`
- `cenas/wildcat_1.tscn`

Interpretação:
- Personagens colidem com mundo (layer 1).
- Personagens não se bloqueiam rigidamente entre si.
- O desvio entre eles fica sob responsabilidade do avoidance.

## Validação
Validado via Godot MCP com `play` da cena `res://cenas/mundo.tscn`:
- Sem erro crítico de runtime.
- Comportamento de crossing melhorado (menos sticky/lock).

## Ajuste Fino Recomendado
Para tuning por escala/densidade de NPC:
1. `avoidance_neighbor_distance` (ex.: 48 a 96)
2. `avoidance_time_horizon` (ex.: 0.8 a 1.8)
3. `avoidance_radius` (combinar com `CollisionShape2D`)
4. `acceleration`/`deceleration` para suavidade visual
5. `stop_epsilon` para reduzir micro-oscilação no destino

## Diretriz Multiplayer (coop autoritativo)
- Cliente envia intenção de movimento.
- Host/servidor valida e simula.
- Host replica estado (posição/velocidade/estado).
- Avoidance oficial deve rodar no lado autoritativo para evitar divergência.

