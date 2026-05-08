class_name HealthComponent
extends Node

signal damaged(amount: float, knockback: Vector2)
signal death

@export var max_health: float = 10.0

var _current_health: float = 0.0


func _ready() -> void:
	_current_health = max_health


func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if _current_health <= 0.0:
		return
	_current_health = maxf(0.0, _current_health - maxf(0.0, amount))
	if _current_health <= 0.0:
		death.emit()
	else:
		damaged.emit(amount, knockback)


func reset_health() -> void:
	_current_health = maxf(0.0, max_health)


func get_current_health() -> float:
	return _current_health


func is_alive() -> bool:
	return _current_health > 0.0
