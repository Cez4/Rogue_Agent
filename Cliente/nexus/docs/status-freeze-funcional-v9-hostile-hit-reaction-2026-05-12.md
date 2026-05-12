# Status Freeze V9: Hostile Hit Reaction Coverage

Data: 2026-05-12
Status: aprovado em QA jogavel e congelado.
Branch: `feat/universal-hit-reaction-component-v1`
Base obrigatoria:
1. `status-freeze-funcional-v7-hit-reaction-2026-05-12.md`
2. `status-freeze-funcional-v8-wildcat-hit-reaction-2026-05-12.md`

## Resumo Executivo
A cobertura visual de Hit Reaction foi propagada para os hostis principais:

1. `HostileEnemyBase`
2. `HostileEnemyLight`
3. `HostileEnemyBrute`

Os tres agora seguem o mesmo contrato modular aprovado no Player e no Wildcat: `HitReactionComponent` plug-and-play, `HitReactionState` na HSM, `HitReactionProfile` data-driven e animacoes direcionais `TakeDamage_*` tocando com `played=true`.

## Escopo Congelado
Cenas incluidas neste freeze:

1. `res://cenas/enemies/hostile_enemy_base.tscn`
2. `res://cenas/enemies/hostile_enemy_light.tscn`
3. `res://cenas/enemies/hostile_enemy_brute.tscn`

Arquitetura reutilizada:

1. `res://Scripts/combat/hit_reaction_component.gd`
2. `res://Scripts/actors/states/hit_reaction_state.gd`
3. `res://configs/combat/hit_reaction/hostile_light_hit_reaction_profile_v1.tres`
4. `res://configs/combat/hit_reaction/hostile_brute_hit_reaction_profile_v1.tres`

## Implementacao
Cada cena hostile recebeu via Godot/editor API:

1. 8 animacoes `TakeDamage_*`;
2. `loop = false`;
3. 15 frames;
4. 15 FPS;
5. duracao real de 1.0s;
6. `HitReactionComponent` no root;
7. `LimboHSM/HitReactionState`;
8. paths equivalentes ao contrato do Player/Wildcat.

Profiles:

1. `HostileEnemyBase` usa `hostile_light_hit_reaction_profile_v1.tres`.
2. `HostileEnemyLight` usa `hostile_light_hit_reaction_profile_v1.tres`.
3. `HostileEnemyBrute` usa `hostile_brute_hit_reaction_profile_v1.tres`.

## Evidencia De QA
Logs gerados pelo diretor e analisados confirmaram o ciclo completo em cada hostile.

### HostileEnemyBrute
Confirmado:

1. `hit_confirmed` com `source_owner: Player`;
2. `knockback_applied`;
3. `hit_reaction_requested`;
4. `hit_reaction_started`;
5. `hit_reaction_animation played=true`;
6. animacoes reais como `TakeDamage_NE`, `TakeDamage_O`, `TakeDamage_NO`, `TakeDamage_N`, `TakeDamage_L`;
7. `duration: 1.0`;
8. `hit_reaction_finished`;
9. morte final sem nova hit reaction, correto.

### HostileEnemyLight
Confirmado:

1. `hit_confirmed` com `source_owner: Player`;
2. `knockback_applied`;
3. `hit_reaction_requested`;
4. `hit_reaction_started`;
5. `hit_reaction_animation played=true`;
6. animacoes reais como `TakeDamage_NO`, `TakeDamage_O`, `TakeDamage_SO`, `TakeDamage_L`;
7. `duration: 1.0`;
8. `hit_reaction_finished`;
9. morte final sem nova hit reaction, correto.

### HostileEnemyBase
Confirmado:

1. `hit_confirmed` com `source_owner: Player`;
2. `knockback_applied`;
3. `hit_reaction_requested`;
4. `hit_reaction_started`;
5. `hit_reaction_animation played=true`;
6. animacoes reais como `TakeDamage_N`, `TakeDamage_L`, `TakeDamage_S`, `TakeDamage_NE`;
7. `duration: 1.0`;
8. `hit_reaction_finished`;
9. morte final sem nova hit reaction, correto.

## Regressao Conferida
Durante QA dos tres hostis, os logs tambem confirmaram continuidade de:

1. ataque;
2. range check;
3. stamina consume/recover;
4. kiting;
5. orb visibility/stamina reaction;
6. health regen fora de combate;
7. target lost;
8. death/respawn.

Nao houve parse/runtime error novo observado no MCP.

## Contrato Congelado
1. Hit Reaction segue modular e copiavel para qualquer ator com `Health`, `Hurtbox`, `AttackHitbox` e `LimboHSM`.
2. Nao adicionar tuning/export de Hit Reaction no `Actor8DirLimbo`.
3. Profiles `.tres` continuam sendo a fonte de comportamento.
4. BT continua apenas respeitando `is_reacting()`, sem assumir regra de dano.
5. Cenas `.tscn` estruturais devem continuar sendo alteradas via Godot/editor API.
6. Entidade morta nao deve iniciar nova hit reaction; deve seguir fluxo de morte/target lost/respawn.

## Estado Atual Apos V9
Cenas com Hit Reaction visual aprovado:

1. `res://cenas/player.tscn` via V7.
2. `res://cenas/wildcat_1.tscn` via V8.
3. `res://cenas/enemies/hostile_enemy_base.tscn` via V9.
4. `res://cenas/enemies/hostile_enemy_light.tscn` via V9.
5. `res://cenas/enemies/hostile_enemy_brute.tscn` via V9.

## Proximo Passo Recomendado
Com a cobertura visual dos hostis congelada, o proximo trabalho deve ser escolhido como nova sprint:

1. consolidar um template visual compartilhado para reduzir duplicacao de `SpriteFrames`;
2. voltar ao slimming do `Actor8DirLimbo`;
3. ou iniciar nova camada de game feel, mantendo V7/V8/V9 como baseline.
