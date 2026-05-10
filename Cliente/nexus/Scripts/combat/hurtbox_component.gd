class_name HurtboxComponent
extends Area2D

@export var health_component_path: NodePath = ^"../Health"
@export var aggro_on_hit: bool = true

var _health: HealthComponent


func _ready() -> void:
	_health = get_node_or_null(health_component_path) as HealthComponent


func take_hit(amount: float, knockback: Vector2, _source: Node = null) -> void:
	if _health == null:
		return
	_try_set_aggro_target(_source)
	_health.take_damage(amount, knockback)


func _try_set_aggro_target(source: Node) -> void:
	if not aggro_on_hit:
		return
	if source == null:
		return
	var owner_actor: Actor8DirLimbo = owner as Actor8DirLimbo
	if owner_actor == null:
		return
	var source_owner: Node = source.owner
	if source_owner == null:
		return
	if source_owner == owner_actor:
		return
	var attacker: Node2D = source_owner as Node2D
	if attacker == null:
		return
	# Keep retaliation stable after taking damage.
	owner_actor.set_combat_target(attacker, true)
	_try_immediate_retaliation(owner_actor, attacker)


func _try_immediate_retaliation(owner_actor: Actor8DirLimbo, attacker: Node2D) -> void:
	# Hardening: if BT/decision cadence misses a frame, hostile still retaliates
	# when already in melee range after receiving a hit.
	if owner_actor == null or attacker == null:
		return
	if owner_actor.player_controlled:
		return
	if owner_actor.is_attack_pending_runtime():
		return
	if not owner_actor.has_stamina_for_attack():
		return
	var engage_dist: float = maxf(4.0, owner_actor.get_attack_engage_distance())
	var dist: float = owner_actor.global_position.distance_to(attacker.global_position)
	if dist > engage_dist:
		return
	owner_actor.face_toward(attacker.global_position)
	owner_actor.request_attack()
