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
	var attacker: Node2D = _resolve_attacker_actor(source)
	if attacker == null:
		return
	if attacker == owner_actor:
		return
	# Keep retaliation stable after taking damage.
	owner_actor.set_combat_target(attacker, true)


func _resolve_attacker_actor(source: Node) -> Node2D:
	if source == null:
		return null
	var source_owner: Node = source.owner
	if source_owner is Actor8DirLimbo:
		return source_owner as Node2D
	var n: Node = source
	while n != null:
		if n is Actor8DirLimbo:
			return n as Node2D
		n = n.get_parent()
	return null
