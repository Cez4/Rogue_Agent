class_name HurtboxComponent
extends Area2D

@export var health_component_path: NodePath = ^"../Health"

var _health: Node


func _ready() -> void:
	_health = get_node_or_null(health_component_path)


func take_hit(amount: float, knockback: Vector2, _source: Node = null) -> void:
	if _health == null:
		return
	if _health.has_method("take_damage"):
		_health.take_damage(amount, knockback)
