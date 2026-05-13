class_name HitReactionComponent
extends Node

@export var target_actor_path: NodePath = ^".."
@export var health_component_path: NodePath = ^"../Health"
@export var hsm_path: NodePath = ^"../LimboHSM"
@export var profile: Resource

const LAST_DAMAGE_SOURCE_ACTOR_NAME_META := &"last_damage_source_actor_name"
const LAST_DAMAGE_SOURCE_ACTOR_PATH_META := &"last_damage_source_actor_path"
const LAST_DAMAGE_SOURCE_ATTACK_SEQUENCE_META := &"last_damage_source_attack_sequence_id"
const LAST_DAMAGE_SOURCE_HITBOX_SEQUENCE_META := &"last_damage_source_hitbox_sequence_id"
const HITBREAK_SOURCE_ACTOR_NAME_META := &"hitbreak_source_actor_name"
const HITBREAK_SOURCE_ACTOR_PATH_META := &"hitbreak_source_actor_path"
const HITBREAK_SOURCE_ATTACK_SEQUENCE_META := &"hitbreak_source_attack_sequence_id"
const HITBREAK_SOURCE_HITBOX_SEQUENCE_META := &"hitbreak_source_hitbox_sequence_id"

var _target_actor: Node
var _health: HealthComponent
var _hsm: LimboHSM
var _is_reacting: bool = false
var _pending_request: Dictionary = {}
var _last_reaction_ms: int = -999999999


func _ready() -> void:
	_target_actor = get_node_or_null(target_actor_path)
	_health = get_node_or_null(health_component_path) as HealthComponent
	_hsm = get_node_or_null(hsm_path) as LimboHSM
	if _health != null and not _health.damaged.is_connected(_on_health_damaged):
		_health.damaged.connect(_on_health_damaged)


func is_reacting() -> bool:
	return _is_reacting


func request_hit_reaction(amount: float, knockback: Vector2) -> bool:
	if profile == null or not bool(profile.get("enabled")):
		_emit_skipped("disabled_or_missing_profile", amount)
		return false
	if bool(profile.get("require_alive")) and _health != null and not _health.is_alive():
		_emit_skipped("dead", amount)
		return false
	var now_ms: int = Time.get_ticks_msec()
	var cooldown_ms: int = int(maxf(0.0, float(profile.get("reaction_cooldown_sec"))) * 1000.0)
	if _is_reacting or now_ms - _last_reaction_ms < cooldown_ms:
		_emit_skipped("cooldown_or_active", amount)
		return false
	if _hsm == null:
		_emit_skipped("missing_hsm", amount)
		return false

	if _target_actor != null and bool(profile.get("interrupt_attack")):
		_target_actor.set_meta(&"attack_interrupt_reason", &"hit_reaction")
		if _is_target_attack_pending():
			_mark_hitbreak_source_from_last_damage()
		else:
			_clear_hitbreak_source()
	_pending_request = {
		"profile": profile,
		"damage": amount,
		"knockback": knockback,
		"direction": _resolve_direction(knockback)
	}
	_last_reaction_ms = now_ms
	CombatTelemetry.emit_event(&"hit_reaction_requested", {
		"actor": _actor_name(),
		"damage": amount,
		"duration": _resolve_duration(profile)
	})
	var consumed: bool = bool(_hsm.dispatch(&"hit_reaction!"))
	if not consumed:
		_pending_request.clear()
		_clear_attack_interrupt_reason()
		_clear_hitbreak_source()
		_emit_skipped("hsm_event_not_consumed", amount)
		return false
	return true


func begin_reaction_state() -> Dictionary:
	if _pending_request.is_empty():
		return {}
	_is_reacting = true
	var request: Dictionary = _pending_request.duplicate()
	_pending_request.clear()
	var reaction_profile: Resource = request.get("profile") as Resource
	request["duration"] = _resolve_duration(reaction_profile)
	CombatTelemetry.emit_event(&"hit_reaction_started", {
		"actor": _actor_name(),
		"duration": request["duration"],
		"animation_prefix": String(reaction_profile.get("animation_prefix")) if reaction_profile != null else ""
	})
	return request


func finish_reaction_state() -> void:
	if not _is_reacting:
		return
	_is_reacting = false
	CombatTelemetry.emit_event(&"hit_reaction_finished", {
		"actor": _actor_name()
	})


func _on_health_damaged(amount: float, knockback: Vector2) -> void:
	request_hit_reaction(amount, knockback)


func _resolve_duration(reaction_profile: Resource) -> float:
	if reaction_profile == null:
		return 0.0
	var fhr_value: float = 0.0
	if _target_actor != null and _target_actor.has_method("get_stat_value"):
		fhr_value = float(_target_actor.call("get_stat_value", reaction_profile.get("fhr_stat_id"), 0.0))
	if reaction_profile.has_method("get_clamped_duration"):
		return float(reaction_profile.call("get_clamped_duration", fhr_value))
	return clampf(float(reaction_profile.get("base_hit_stun_sec")) - fhr_value * float(reaction_profile.get("fhr_reduction_per_point")), float(reaction_profile.get("min_hit_stun_sec")), float(reaction_profile.get("max_hit_stun_sec")))


func _resolve_direction(knockback: Vector2) -> Vector2:
	if not knockback.is_zero_approx():
		return knockback.normalized()
	if _target_actor is Node2D:
		var actor := _target_actor as Node2D
		if actor.get("velocity") is Vector2:
			var velocity: Vector2 = actor.get("velocity")
			if not velocity.is_zero_approx():
				return velocity.normalized()
	return Vector2.ZERO


func _emit_skipped(reason: String, amount: float) -> void:
	CombatTelemetry.emit_event(&"hit_reaction_skipped", {
		"actor": _actor_name(),
		"reason": reason,
		"damage": amount
	})


func _is_target_attack_pending() -> bool:
	if _target_actor == null:
		return false
	if not _target_actor.has_method("is_attack_pending_runtime"):
		return true
	return bool(_target_actor.call("is_attack_pending_runtime"))


func _mark_hitbreak_source_from_last_damage() -> void:
	if _target_actor == null:
		return
	_clear_hitbreak_source()
	if not _target_actor.has_meta(LAST_DAMAGE_SOURCE_ACTOR_NAME_META):
		return
	_target_actor.set_meta(HITBREAK_SOURCE_ACTOR_NAME_META, str(_target_actor.get_meta(LAST_DAMAGE_SOURCE_ACTOR_NAME_META)))
	if _target_actor.has_meta(LAST_DAMAGE_SOURCE_ACTOR_PATH_META):
		_target_actor.set_meta(HITBREAK_SOURCE_ACTOR_PATH_META, str(_target_actor.get_meta(LAST_DAMAGE_SOURCE_ACTOR_PATH_META)))
	if _target_actor.has_meta(LAST_DAMAGE_SOURCE_ATTACK_SEQUENCE_META):
		_target_actor.set_meta(HITBREAK_SOURCE_ATTACK_SEQUENCE_META, int(_target_actor.get_meta(LAST_DAMAGE_SOURCE_ATTACK_SEQUENCE_META)))
	if _target_actor.has_meta(LAST_DAMAGE_SOURCE_HITBOX_SEQUENCE_META):
		_target_actor.set_meta(HITBREAK_SOURCE_HITBOX_SEQUENCE_META, int(_target_actor.get_meta(LAST_DAMAGE_SOURCE_HITBOX_SEQUENCE_META)))


func _clear_hitbreak_source() -> void:
	if _target_actor == null:
		return
	if _target_actor.has_meta(HITBREAK_SOURCE_ACTOR_NAME_META):
		_target_actor.remove_meta(HITBREAK_SOURCE_ACTOR_NAME_META)
	if _target_actor.has_meta(HITBREAK_SOURCE_ACTOR_PATH_META):
		_target_actor.remove_meta(HITBREAK_SOURCE_ACTOR_PATH_META)
	if _target_actor.has_meta(HITBREAK_SOURCE_ATTACK_SEQUENCE_META):
		_target_actor.remove_meta(HITBREAK_SOURCE_ATTACK_SEQUENCE_META)
	if _target_actor.has_meta(HITBREAK_SOURCE_HITBOX_SEQUENCE_META):
		_target_actor.remove_meta(HITBREAK_SOURCE_HITBOX_SEQUENCE_META)


func _clear_attack_interrupt_reason() -> void:
	if _target_actor == null:
		return
	if _target_actor.has_meta(&"attack_interrupt_reason"):
		_target_actor.remove_meta(&"attack_interrupt_reason")


func _actor_name() -> String:
	if _target_actor != null:
		return str(_target_actor.name)
	if owner != null:
		return str(owner.name)
	return str(get_parent().name) if get_parent() != null else ""
