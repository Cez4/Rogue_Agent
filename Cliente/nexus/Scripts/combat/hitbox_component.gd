class_name HitboxComponent
extends Area2D

@export var damage: float = 1.0
@export var knockback_enabled: bool = false
@export var knockback_strength: float = 280.0
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
	var knockback := Vector2.ZERO
	if knockback_enabled:
		knockback = Vector2.RIGHT.rotated(global_rotation) * knockback_strength
	hurtbox.take_hit(damage, knockback, self)
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
