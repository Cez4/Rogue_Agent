# Status Freeze V11: Hitbreak Combat Feedback

Data: 2026-05-13
Status: aprovado em QA visual/log e congelado.
Branch: `feat/hitbreak-combat-feedback-v1`
Base obrigatoria:
1. `status-freeze-operacional-v10-combat-core-restored-2026-05-13.md`
2. `status-freeze-funcional-v9-hostile-hit-reaction-2026-05-12.md`
3. `status-freeze-funcional-v6-knockback-2026-05-12.md`

## Resumo Executivo
Esta sprint congelou o feedback visual data-driven para **Hitbreak**.

Hitbreak, neste projeto, significa: um ator confirma hit real, o alvo recebe dano/knockback, entra em Hit Reaction e, se estava atacando, tem o ataque interrompido por `reason = hit_reaction`.

O feedback aprovado e um brilho/flash curto no atacante que causou a interrupcao, executado por `CombatFeedbackComponent` em `mode = shader`.

## Escopo Congelado
Cenas com feedback aprovado:

1. `res://cenas/player.tscn`
2. `res://cenas/wildcat_1.tscn`
3. `res://cenas/enemies/hostile_enemy_base.tscn`
4. `res://cenas/enemies/hostile_enemy_light.tscn`
5. `res://cenas/enemies/hostile_enemy_brute.tscn`

Arquitetura congelada:

1. `res://Scripts/combat/feedback/combat_feedback_component.gd`
2. `res://Scripts/combat/feedback/combat_feedback_profile.gd`
3. `res://Scripts/combat/feedback/hitbreak_flash.gdshader`
4. `res://configs/combat/feedback/default_hitbreak_feedback_profile_v1.tres`
5. Telemetria `hitbreak_success`
6. Telemetria `combat_feedback_hitbreak_started`
7. Telemetria `combat_feedback_hitbreak_finished`

## Implementacao
O componente foi integrado como node plug-and-play em Player, Wildcat e hostis principais.

Contrato de integracao:

1. `CombatFeedbackComponent` fica no root do ator.
2. `actor_path` aponta para `..`.
3. `sprite_path` aponta para `../AnimatedSprite2D`.
4. `profile` aponta para `default_hitbreak_feedback_profile_v1.tres`.
5. O shader/material e instanciado por ator em runtime para evitar flash global por material compartilhado.
6. O tuning visual vive no `.tres`, nao em cena, BT, HSM ou `Actor8DirLimbo`.

## Evidencia De QA
Logs gerados pelo diretor e analisados confirmaram o ciclo completo em cada cobertura.

### Player
Confirmado:

1. Player causou `hitbreak_success`.
2. `combat_feedback_hitbreak_started` rodou em `mode = shader`.
3. `combat_feedback_hitbreak_finished` rodou no Player.
4. O alvo continuou tocando `TakeDamage_*` normalmente.

### Wildcat
Confirmado:

1. Wildcat causou `hitbreak_success`.
2. `combat_feedback_hitbreak_started` rodou em `mode = shader`.
3. `combat_feedback_hitbreak_finished` rodou no Wildcat.
4. Player tocou `Dagger01_TakeDamage_*` com `played = true`.

### HostileEnemyBrute
Confirmado:

1. `HostileEnemyBrute` causou `hitbreak_success` contra Player.
2. `combat_feedback_hitbreak_started` rodou no Brute em `mode = shader`, `duration = 0.12`, `intensity = 1.0`.
3. `combat_feedback_hitbreak_finished` rodou no Brute.
4. Player tocou `Dagger01_TakeDamage_*` com `played = true`.

### HostileEnemyBase
Confirmado:

1. `HostileEnemyBase` causou `hitbreak_success` contra Player.
2. `combat_feedback_hitbreak_started` rodou no Base em `mode = shader`, `duration = 0.12`, `intensity = 1.0`.
3. `combat_feedback_hitbreak_finished` rodou no Base.
4. Player tocou `Dagger01_TakeDamage_*` com `played = true`.

### HostileEnemyLight
Confirmado:

1. `HostileEnemyLight` causou `hitbreak_success` contra Player.
2. `combat_feedback_hitbreak_started` rodou no Light em `mode = shader`, `duration = 0.12`, `intensity = 1.0`.
3. `combat_feedback_hitbreak_finished` rodou no Light.
4. Player tocou `Dagger01_TakeDamage_*` com `played = true`.
5. O inverso tambem foi observado: Player causou hitbreak no Light e o feedback do Player continuou funcional.

## Regressao Conferida
Durante QA de Player, Wildcat e hostis, os logs confirmaram continuidade de:

1. consumo de stamina por ataque;
2. `attack_started`, `attack_phase_started`, `attack_window_opened` e `attack_window_closed`;
3. `hit_confirmed`;
4. `knockback_applied`;
5. `hit_reaction_requested`, `hit_reaction_started`, `hit_reaction_animation played=true` e `hit_reaction_finished`;
6. kiting e reposicionamento por stamina;
7. Orb visibility/stamina reaction;
8. separacao correta entre hitbreak por `hit_reaction` e fluxo normal de hit;
9. sem parse/runtime error novo observado no MCP.

## Fora Do Escopo: Parry
Parry nao foi implementado nesta sprint.

A decisao congelada e manter Parry para sprint futura, separada e mais simples:

1. componente modular proprio, como `DefenseComponent` ou `ParryComponent`;
2. profile data-driven proprio, como `DefenseProfile.tres` ou `ParryProfile.tres`;
3. regra por chance/atributo/cooldown/custo, consultada antes do dano;
4. sem `mutual_clash` global;
5. sem reativar Combat Clash temporal;
6. sem adicionar exports de Parry/Defense no `Actor8DirLimbo`.

## Contrato Congelado
1. Hitbreak Feedback e apenas game feel visual; nao altera dano, stamina, Hit Reaction, Knockback, BT ou HSM.
2. O atacante recebe o brilho; o alvo continua executando Hit Reaction normalmente.
3. Interrupcao por `death` nao deve gerar falso Hitbreak.
4. `CombatFeedbackComponent` deve continuar plug-and-play e copiavel para novos atores.
5. `CombatFeedbackProfile` continua sendo a fonte de tuning visual.
6. Cenas `.tscn` estruturais devem continuar sendo alteradas via Godot/editor API.
7. `Actor8DirLimbo` nao deve receber shader, cor, duracao ou tuning de feedback.

## Estado Atual Apos V11
Cobertura aprovada:

1. Player: aprovado.
2. Wildcat: aprovado.
3. HostileEnemyBase: aprovado.
4. HostileEnemyLight: aprovado.
5. HostileEnemyBrute: aprovado.

Proximo trabalho deve abrir sprint nova, sem misturar com V11. Candidatos:

1. `DefenseComponent` / `ParryComponent` data-driven por chance;
2. consolidacao de templates visuais para reduzir duplicacao;
3. continuidade do slimming do `Actor8DirLimbo`;
4. nova camada de game feel visual, usando V11 como baseline.
