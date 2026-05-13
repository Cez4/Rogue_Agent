class_name HitboxComponent
extends Area2D

@export var damage: float = 1.0
@export var knockback_force: float = 0.0
@export var knockback_duration_sec: float = 0.1
@export var one_hit_per_target_per_attack: bool = true
@export var max_targets_per_attack: int = 0

var attack_sequence_id: int = 0
var _attack_seq: int = 0
var _hit_target_ids: Dictionary = {}
var _hits_count: int = 0
var _parried_count: int = 0
var _window_open: bool = false


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func set_hitbox_enabled(enabled: bool, reason: StringName = &"manual") -> void:
	# Physics-safe toggling: this can be called during in/out signals.
	set_deferred("monitoring", enabled)
	set_deferred("monitorable", enabled)
	if enabled:
		_begin_attack_window()
	elif _window_open:
		_close_attack_window(reason)


func _begin_attack_window() -> void:
	_attack_seq += 1
	_hit_target_ids.clear()
	_hits_count = 0
	_parried_count = 0
	_window_open = true
	CombatTelemetry.emit_event(&"attack_window_opened", {
		"actor": _owner_name(),
		"attack_sequence_id": attack_sequence_id,
		"hitbox_sequence_id": _attack_seq
	})
	var clash := _clash_component()
	if clash != null:
		clash.notify_attack_window_opened(attack_sequence_id, _attack_seq)


func _close_attack_window(reason: StringName) -> void:
	_window_open = false
	CombatTelemetry.emit_event(&"attack_window_closed", {
		"actor": _owner_name(),
		"attack_sequence_id": attack_sequence_id,
		"hitbox_sequence_id": _attack_seq,
		"reason": String(reason),
		"hits_count": _hits_count,
		"parried_count": _parried_count,
		"clashed_count": _parried_count
	})
	var clash := _clash_component()
	if clash != null:
		clash.notify_attack_window_closed(attack_sequence_id, _attack_seq, reason, _hits_count, _parried_count)


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
		
	if hurtbox.has_method("try_resolve_incoming_hit"):
		var resolution: Dictionary = hurtbox.try_resolve_incoming_hit(damage, knockback_vector, knockback_duration_sec, self, attack_sequence_id, _attack_seq)
		if bool(resolution.get("resolved", false)):
			_hit_target_ids[target_id] = true
			_parried_count += 1
			var cancel_event: StringName = StringName(str(resolution.get("cancel_event", "hit_cancelled_by_parry")))
			CombatTelemetry.emit_event(cancel_event, {
				"source_owner": _owner_name(),
				"attack_sequence_id": attack_sequence_id,
				"hitbox_sequence_id": _attack_seq,
				"target_area": area.name,
				"classification": str(resolution.get("classification", "")),
				"cancel_type": "mutual_clash"
			})
			return

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
		"attack_sequence_id": attack_sequence_id,
		"hitbox_sequence_id": _attack_seq,
		"target_area": area.name,
		"damage": damage
	})
	var clash := _clash_component()
	if clash != null:
		clash.notify_hit_confirmed(attack_sequence_id, _attack_seq, str(area.name), damage)


func _owner_name() -> String:
	if owner == null:
		return ""
	return str(owner.name)


func _clash_component() -> Node:
	if owner == null:
		return null
	return owner.get_node_or_null(^"CombatClashComponent")
