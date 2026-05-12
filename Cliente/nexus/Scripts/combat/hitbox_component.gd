class_name HitboxComponent
extends Area2D

@export var damage: float = 1.0
@export var knockback_force: float = 0.0
@export var knockback_duration_sec: float = 0.1
@export var one_hit_per_target_per_attack: bool = true
@export var max_targets_per_attack: int = 0

var _attack_seq: int = 0
var _hit_target_ids: Dictionary = {}
var _hits_count: int = 0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func set_hitbox_enabled(enabled: bool) -> void:
	# Physics-safe toggling: this can be called during in/out signals.
	set_deferred("monitoring", enabled)
	set_deferred("monitorable", enabled)
	if enabled:
		_begin_attack_window()


func _begin_attack_window() -> void:
	_attack_seq += 1
	_hit_target_ids.clear()
	_hits_count = 0


func _on_area_entered(area: Area2D) -> void:
	if area == null:
		return
	if area.owner == owner:
		return
	var hurtbox: HurtboxComponent = area as HurtboxComponent
	if hurtbox == null:
		return
	var target_id: int = area.get_instance_id()
	if one_hit_per_target_per_attack and _hit_target_ids.has(target_id):
		return
	if max_targets_per_attack > 0 and _hits_count >= max_targets_per_attack:
		return
		
	var knockback_vector := Vector2.ZERO
	if knockback_force > 0.0:
		var dir: Vector2 = (hurtbox.global_position - global_position).normalized()
		if dir.is_zero_approx():
			dir = Vector2.RIGHT.rotated(global_rotation)
		knockback_vector = dir * knockback_force
		
	# Call apply_knockback directly if the hurtbox supports it
	if hurtbox.has_method("take_hit_with_knockback_duration"):
		hurtbox.take_hit_with_knockback_duration(damage, knockback_vector, knockback_duration_sec, self)
	else:
		hurtbox.take_hit(damage, knockback_vector, self)
		
	_hit_target_ids[target_id] = true
	_hits_count += 1
	var source_owner: String = ""
	if owner != null:
		source_owner = str(owner.name)
	CombatTelemetry.emit_event(&"hit_confirmed", {
		"source_owner": source_owner,
		"target_area": area.name,
		"damage": damage
	})
