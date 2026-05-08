class_name HitboxComponent
extends Area2D

@export var damage: float = 1.0
@export var knockback_enabled: bool = false
@export var knockback_strength: float = 280.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func set_hitbox_enabled(enabled: bool) -> void:
	monitoring = enabled
	monitorable = enabled


func _on_area_entered(area: Area2D) -> void:
	if area == null:
		return
	if area.owner == owner:
		return
	if not area.has_method("take_hit"):
		return
	var knockback := Vector2.ZERO
	if knockback_enabled:
		knockback = Vector2.RIGHT.rotated(global_rotation) * knockback_strength
	area.take_hit(damage, knockback, self)
