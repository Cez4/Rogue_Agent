# Estudo: Paridade de Hitbox/Hurtbox no Combate 8dir

Data: 2026-05-09  
Escopo: auditoria completa do pipeline de dano para player e hostis.

## Pergunta investigada
Se o ataque 8 direcoes estava realmente acertando por colisao fisica em todos os atores, ou apenas no player.

## Resultado da auditoria
1. A logica 8dir de ataque esta correta no codigo:
- `ActorActionRuntime.orient_attack_hitbox()` reposiciona a `AttackHitbox` conforme `last_direction_suffix`.
- `state_attack_8dir.gd` ativa/desativa hitbox por janela (`windup/active/recover`) via `CombatActionData`.

2. O gap era de composicao de cena:
- Player tinha `AttackHitbox` + `Hurtbox`.
- Hostis (base/light/brute/wildcat) tinham apenas `Hurtbox` (sem `AttackHitbox`).

3. Correcao aplicada:
- `AttackHitbox` adicionada em:
  - `res://cenas/enemies/hostile_enemy_base.tscn`
  - `res://cenas/enemies/hostile_enemy_light.tscn`
  - `res://cenas/enemies/hostile_enemy_brute.tscn`
  - `res://cenas/wildcat_1.tscn`

4. Evidencia de validacao:
- MCP: `open_scene -> play_scene -> get_godot_errors` sem erro novo.
- Telemetria confirmou dano inimigo real:
  - `hit_confirmed` com `source_owner=\"HostileEnemyLight\"` e `damage=0.85`.

## Conclusao tecnica
1. O projeto usa combate proprio data-driven (nao o combat pronto da demo).
2. A direcao do golpe e controlada pela `AttackHitbox` do atacante (nao pela `Hurtbox` do alvo).
3. Para manter fidelidade 8dir, todo ator combatente deve ter a mesma composicao base.

## Regra de arquitetura (obrigatoria)
Todo ator que pode atacar deve possuir:
1. `Health` (componente de vida).
2. `Hurtbox` (receber dano).
3. `AttackHitbox` (causar dano).

Sem essa paridade, BT/HSM pode parecer funcional em telemetria de estado, mas sem dano fisico real.

## Referencias oficiais
1. Godot Area2D (monitoring/overlap):
https://docs.godotengine.org/en/stable/classes/class_area2d.html
2. Godot CollisionObject2D:
https://docs.godotengine.org/en/stable/classes/class_collisionobject2d.html
3. LimboAI Behavior Tree:
https://limboai.readthedocs.io/en/latest/classes/class_behaviortree.html
