class_name HurtboxComponent
extends Area2D

@export var health_component_path: NodePath = ^"../Health"

var _health: HealthComponent


func _ready() -> void:
	_health = get_node_or_null(health_component_path) as HealthComponent


func take_hit(amount: float, knockback: Vector2, _source: Node = null) -> void:
	if _health == null:
		return
	_health.take_damage(amount, knockback)
