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
