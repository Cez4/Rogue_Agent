class_name HealthComponent
extends Node

signal damaged(amount: float, knockback: Vector2)
signal health_changed(current: float, max_health: float)
signal healed(amount: float)
signal death

@export var max_health: float = 10.0

var _current_health: float = 0.0


func _ready() -> void:
	_current_health = max_health
	health_changed.emit(_current_health, max_health)


func take_damage(amount: float, knockback: Vector2 = Vector2.ZERO) -> void:
	if _current_health <= 0.0:
		return
	var damage_amount: float = maxf(0.0, amount)
	if damage_amount <= 0.0:
		return
	_current_health = maxf(0.0, _current_health - damage_amount)
	health_changed.emit(_current_health, max_health)
	if _current_health <= 0.0:
		death.emit()
	else:
		damaged.emit(damage_amount, knockback)


func reset_health() -> void:
	_current_health = maxf(0.0, max_health)
	health_changed.emit(_current_health, max_health)


func heal(amount: float) -> void:
	if _current_health <= 0.0:
		return
	var heal_amount: float = maxf(0.0, amount)
	if heal_amount <= 0.0:
		return
	var previous_health: float = _current_health
	_current_health = minf(max_health, _current_health + heal_amount)
	var applied: float = _current_health - previous_health
	if applied <= 0.0:
		return
	healed.emit(applied)
	health_changed.emit(_current_health, max_health)


func get_current_health() -> float:
	return _current_health


func get_health_ratio() -> float:
	return clampf(_current_health / maxf(1.0, max_health), 0.0, 1.0)


func is_alive() -> bool:
	return _current_health > 0.0
