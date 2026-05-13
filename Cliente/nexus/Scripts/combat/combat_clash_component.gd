class_name CombatClashComponent
extends Node

@export var target_actor_path: NodePath = ^".."
@export var profile: Resource

static var _active_attacks: Dictionary = {}
static var _emitted_candidate_pairs: Dictionary = {}

const ATTACK_REGISTRY_TTL_MS: int = 2000
const CLASH_CANCEL_ATTACK_SEQUENCE_META := &"combat_clash_cancel_attack_sequence_id"
const CLASH_CANCEL_REASON_META := &"combat_clash_cancel_reason"
const CLASH_RECOVERY_SEC_META := &"combat_clash_recovery_sec"

var _target_actor: Node
var _attack_sequence_id: int = 0
var _attack_phase: StringName = &"idle"
var _attack_target: String = ""
var _attack_started_ms: int = 0
var _active_started_ms: int = 0
var _window_open: bool = false
var _last_interrupt_ms: int = -999999999


func _ready() -> void:
	_target_actor = get_node_or_null(target_actor_path)


func notify_attack_started(attack_sequence_id: int, target_name: String = "") -> void:
	if not _is_enabled():
		return
	_attack_sequence_id = attack_sequence_id
	_attack_target = target_name
	_attack_started_ms = Time.get_ticks_msec()
	_active_started_ms = 0
	_window_open = false
	_attack_phase = &"windup"
	CombatTelemetry.emit_event(&"combat_clash_attack_started_observed", {
		"actor": _actor_name(),
		"attack_sequence_id": _attack_sequence_id,
		"target": _attack_target,
		"emit_only_telemetry": _profile_bool(&"emit_only_telemetry", true)
	})
	_register_attack()
	_emit_temporal_candidate_if_present()


func notify_attack_phase(attack_sequence_id: int, phase: StringName, target_name: String = "") -> void:
	if not _is_enabled():
		return
	_attack_sequence_id = attack_sequence_id
	if not target_name.is_empty():
		_attack_target = target_name
	if phase == &"active":
		_active_started_ms = Time.get_ticks_msec()
	_set_phase(phase)
	if phase == &"recover":
		_clear_registered_attack()
	else:
		_update_registered_attack()


func notify_attack_window_opened(attack_sequence_id: int, hitbox_sequence_id: int) -> void:
	if not _is_enabled():
		return
	_attack_sequence_id = attack_sequence_id
	_window_open = true
	CombatTelemetry.emit_event(&"combat_clash_attack_window_observed", {
		"actor": _actor_name(),
		"attack_sequence_id": attack_sequence_id,
		"hitbox_sequence_id": hitbox_sequence_id,
		"phase": String(_attack_phase)
	})


func notify_attack_window_closed(attack_sequence_id: int, hitbox_sequence_id: int, reason: StringName, hits_count: int, parried_count: int = 0) -> void:
	if not _is_enabled():
		return
	_attack_sequence_id = attack_sequence_id
	_window_open = false
	CombatTelemetry.emit_event(&"combat_clash_attack_window_result", {
		"actor": _actor_name(),
		"attack_sequence_id": attack_sequence_id,
		"hitbox_sequence_id": hitbox_sequence_id,
		"phase": String(_attack_phase),
		"reason": String(reason),
		"hits_count": hits_count,
		"parried_count": parried_count,
		"clashed_count": parried_count,
		"result": _attack_window_result(hits_count, parried_count)
	})


func notify_hit_confirmed(attack_sequence_id: int, hitbox_sequence_id: int, target_area: String, damage: float) -> void:
	if not _is_enabled():
		return
	CombatTelemetry.emit_event(&"combat_clash_hit_observed", {
		"actor": _actor_name(),
		"attack_sequence_id": attack_sequence_id,
		"hitbox_sequence_id": hitbox_sequence_id,
		"phase": String(_attack_phase),
		"target_area": target_area,
		"damage": damage
	})


func try_resolve_incoming_hit(source: Node, source_attack_sequence_id: int, source_hitbox_sequence_id: int, amount: float) -> Dictionary:
	if not _is_enabled():
		return {"resolved": false}
	var source_actor_name: String = _source_actor_name(source)
	var matching_attack: Dictionary = _matching_attack_for_source(source_actor_name)
	var classification: String = _incoming_hit_classification(matching_attack)
	var resolved: bool = classification == "mutual_clash_resolved" and not _profile_bool(&"emit_only_telemetry", true)
	CombatTelemetry.emit_event(&"combat_clash_incoming_hit_classified", {
		"actor": _actor_name(),
		"attack_sequence_id": _attack_sequence_id,
		"phase": String(_attack_phase),
		"source_actor": source_actor_name,
		"source_attack_sequence_id": source_attack_sequence_id,
		"source_hitbox_sequence_id": source_hitbox_sequence_id,
		"started_delta_ms": _attack_delta_ms(matching_attack),
		"classification": classification,
		"resolved": resolved,
		"damage": amount,
		"emit_only_telemetry": _profile_bool(&"emit_only_telemetry", true),
		"resolution_mode": _profile_string(&"resolution_mode", "observer")
	})
	if resolved:
		_request_local_attack_cancel(source_actor_name, source_attack_sequence_id)
		CombatTelemetry.emit_event(&"combat_clash_mutual_resolved", {
			"actor": _actor_name(),
			"attack_sequence_id": _attack_sequence_id,
			"phase": String(_attack_phase),
			"source_actor": source_actor_name,
			"source_attack_sequence_id": source_attack_sequence_id,
			"source_hitbox_sequence_id": source_hitbox_sequence_id,
			"started_delta_ms": _attack_delta_ms(matching_attack),
			"cancelled_damage": amount
		})
	return {
		"resolved": resolved,
		"classification": classification,
		"cancel_event": "hit_cancelled_by_clash" if resolved else ""
	}


func notify_attack_interrupted(attack_sequence_id: int, phase: StringName, reason: StringName) -> void:
	if not _is_enabled():
		return
	var now_ms: int = Time.get_ticks_msec()
	var cooldown_ms: int = int(maxf(0.0, _profile_float(&"interrupt_cooldown_sec", 0.0)) * 1000.0)
	if cooldown_ms > 0 and now_ms - _last_interrupt_ms < cooldown_ms:
		return
	_last_interrupt_ms = now_ms
	_attack_sequence_id = attack_sequence_id
	_attack_phase = phase
	CombatTelemetry.emit_event(&"combat_clash_interrupt_observed", {
		"actor": _actor_name(),
		"attack_sequence_id": attack_sequence_id,
		"phase": String(phase),
		"reason": String(reason),
		"emit_only_telemetry": _profile_bool(&"emit_only_telemetry", true)
	})
	var matching_attack: Dictionary = _matching_target_attack()
	var classification: String = _interrupt_classification(reason, matching_attack)
	CombatTelemetry.emit_event(&"combat_clash_interrupt_classified", {
		"actor": _actor_name(),
		"attack_sequence_id": attack_sequence_id,
		"phase": String(phase),
		"reason": String(reason),
		"classification": classification,
		"target": _attack_target,
		"target_attack_sequence_id": int(matching_attack.get("attack_sequence_id", 0)),
		"started_delta_ms": _attack_delta_ms(matching_attack),
		"emit_only_telemetry": _profile_bool(&"emit_only_telemetry", true)
	})
	if classification == "valid_hit_reaction_candidate" and _profile_bool(&"can_parry", false):
		CombatTelemetry.emit_event(&"parry_candidate", {
			"actor": _actor_name(),
			"attack_sequence_id": attack_sequence_id,
			"phase": String(phase),
			"reason": String(reason)
		})
	_clear_registered_attack()
	_reset_local_attack_runtime()


func _set_phase(phase: StringName) -> void:
	_attack_phase = phase
	CombatTelemetry.emit_event(&"combat_clash_phase_observed", {
		"actor": _actor_name(),
		"attack_sequence_id": _attack_sequence_id,
		"phase": String(phase),
		"target": _attack_target,
		"window_open": _window_open
	})


func _is_enabled() -> bool:
	return profile != null and _profile_bool(&"enabled", true)


func _profile_bool(property_name: StringName, fallback: bool) -> bool:
	if profile == null:
		return fallback
	var value: Variant = profile.get(property_name)
	if value == null:
		return fallback
	return bool(value)


func _profile_float(property_name: StringName, fallback: float) -> float:
	if profile == null:
		return fallback
	var value: Variant = profile.get(property_name)
	if value == null:
		return fallback
	return float(value)


func _profile_string(property_name: StringName, fallback: String) -> String:
	if profile == null:
		return fallback
	var value: Variant = profile.get(property_name)
	if value == null:
		return fallback
	return str(value)


func _attack_window_result(hits_count: int, parried_count: int) -> String:
	if hits_count > 0 and parried_count > 0:
		return "mixed"
	if hits_count > 0:
		return "hit"
	if parried_count > 0:
		return "clashed"
	return "whiff"


func _register_attack() -> void:
	var now_ms: int = Time.get_ticks_msec()
	_cleanup_attack_registry(now_ms)
	_active_attacks[_actor_name()] = {
		"actor": _actor_name(),
		"target": _attack_target,
		"attack_sequence_id": _attack_sequence_id,
		"phase": String(_attack_phase),
		"started_ms": _attack_started_ms,
		"window_open": _window_open,
		"clash_window_ms": int(maxf(0.0, _profile_float(&"clash_window_sec", 0.10)) * 1000.0)
	}


func _update_registered_attack() -> void:
	var actor_name: String = _actor_name()
	if not _active_attacks.has(actor_name):
		return
	var attack: Dictionary = _active_attacks[actor_name]
	if int(attack.get("attack_sequence_id", 0)) != _attack_sequence_id:
		return
	attack["target"] = _attack_target
	attack["phase"] = String(_attack_phase)
	attack["window_open"] = _window_open
	_active_attacks[actor_name] = attack


func _clear_registered_attack() -> void:
	var actor_name: String = _actor_name()
	if _active_attacks.has(actor_name):
		var attack: Dictionary = _active_attacks[actor_name]
		if int(attack.get("attack_sequence_id", 0)) == _attack_sequence_id:
			_active_attacks.erase(actor_name)


func _reset_local_attack_runtime() -> void:
	_attack_phase = &"idle"
	_attack_target = ""
	_active_started_ms = 0
	_window_open = false


func _cleanup_attack_registry(now_ms: int) -> void:
	var stale_actors: Array[String] = []
	for actor_name in _active_attacks.keys():
		var attack: Dictionary = _active_attacks[actor_name]
		if now_ms - int(attack.get("started_ms", 0)) > ATTACK_REGISTRY_TTL_MS:
			stale_actors.append(str(actor_name))
	for actor_name in stale_actors:
		_active_attacks.erase(actor_name)

	var stale_pairs: Array[String] = []
	for pair_key in _emitted_candidate_pairs.keys():
		if now_ms - int(_emitted_candidate_pairs[pair_key]) > ATTACK_REGISTRY_TTL_MS:
			stale_pairs.append(str(pair_key))
	for pair_key in stale_pairs:
		_emitted_candidate_pairs.erase(pair_key)


func _emit_temporal_candidate_if_present() -> void:
	var matching_attack: Dictionary = _matching_target_attack()
	if matching_attack.is_empty():
		return
	var delta_ms: int = _attack_delta_ms(matching_attack)
	var window_ms: int = mini(int(maxf(0.0, _profile_float(&"clash_window_sec", 0.10)) * 1000.0), int(matching_attack.get("clash_window_ms", 100)))
	if delta_ms > window_ms:
		return
	var pair_key: String = _candidate_pair_key(matching_attack)
	if _emitted_candidate_pairs.has(pair_key):
		return
	_emitted_candidate_pairs[pair_key] = Time.get_ticks_msec()
	CombatTelemetry.emit_event(&"combat_clash_candidate", {
		"actor": _actor_name(),
		"attack_sequence_id": _attack_sequence_id,
		"phase": String(_attack_phase),
		"target": _attack_target,
		"target_attack_sequence_id": int(matching_attack.get("attack_sequence_id", 0)),
		"target_phase": str(matching_attack.get("phase", "")),
		"started_delta_ms": delta_ms,
		"clash_window_ms": window_ms,
		"classification": "temporal_candidate",
		"emit_only_telemetry": _profile_bool(&"emit_only_telemetry", true)
	})


func _matching_target_attack() -> Dictionary:
	if _attack_target.is_empty() or not _active_attacks.has(_attack_target):
		return {}
	return _matching_attack_for_source(_attack_target)


func _matching_attack_for_source(source_actor_name: String) -> Dictionary:
	var actor_name: String = _actor_name()
	if source_actor_name.is_empty() or not _active_attacks.has(source_actor_name):
		return {}
	var target_attack: Dictionary = _active_attacks[source_actor_name]
	if str(target_attack.get("target", "")) != actor_name:
		return {}
	return target_attack


func _attack_delta_ms(matching_attack: Dictionary) -> int:
	if matching_attack.is_empty():
		return -1
	return absi(_attack_started_ms - int(matching_attack.get("started_ms", 0)))


func _candidate_pair_key(matching_attack: Dictionary) -> String:
	var actor_a: String = _actor_name()
	var actor_b: String = str(matching_attack.get("actor", ""))
	var seq_a: int = _attack_sequence_id
	var seq_b: int = int(matching_attack.get("attack_sequence_id", 0))
	if actor_a < actor_b:
		return "%s:%s|%s:%s" % [actor_a, seq_a, actor_b, seq_b]
	return "%s:%s|%s:%s" % [actor_b, seq_b, actor_a, seq_a]


func _interrupt_classification(reason: StringName, matching_attack: Dictionary) -> String:
	if String(reason) == "death":
		return "death_filtered"
	if matching_attack.is_empty():
		return "interrupt_without_temporal_match"
	var delta_ms: int = _attack_delta_ms(matching_attack)
	var window_ms: int = mini(int(maxf(0.0, _profile_float(&"clash_window_sec", 0.10)) * 1000.0), int(matching_attack.get("clash_window_ms", 100)))
	if delta_ms > window_ms:
		return "interrupt_outside_clash_window"
	if String(reason) == "hit_reaction":
		return "valid_hit_reaction_candidate"
	return "ignored_interrupt_reason"


func _incoming_hit_classification(matching_attack: Dictionary) -> String:
	var resolution_mode: String = _profile_string(&"resolution_mode", "observer")
	if resolution_mode == "observer":
		return "observer_only"
	if resolution_mode != "mutual_clash":
		return "unsupported_resolution_mode"
	if not _profile_bool(&"can_parry", false):
		return "parry_disabled"
	if String(_attack_phase) != "windup":
		return "not_in_parry_phase"
	if matching_attack.is_empty():
		return "incoming_without_temporal_match"
	var delta_ms: int = _attack_delta_ms(matching_attack)
	var window_ms: int = mini(int(maxf(0.0, _profile_float(&"clash_window_sec", 0.10)) * 1000.0), int(matching_attack.get("clash_window_ms", 100)))
	if delta_ms > window_ms:
		return "incoming_outside_clash_window"
	return "mutual_clash_resolved"


func _request_local_attack_cancel(source_actor_name: String, source_attack_sequence_id: int) -> void:
	if _target_actor == null:
		return
	_target_actor.set_meta(CLASH_CANCEL_ATTACK_SEQUENCE_META, _attack_sequence_id)
	_target_actor.set_meta(CLASH_CANCEL_REASON_META, &"mutual_clash")
	var recovery_sec: float = maxf(0.0, _profile_float(&"post_clash_lockout_sec", 0.50))
	_target_actor.set_meta(CLASH_RECOVERY_SEC_META, recovery_sec)
	CombatTelemetry.emit_event(&"combat_clash_attack_cancel_requested", {
		"actor": _actor_name(),
		"attack_sequence_id": _attack_sequence_id,
		"phase": String(_attack_phase),
		"source_actor": source_actor_name,
		"source_attack_sequence_id": source_attack_sequence_id,
		"reason": "mutual_clash",
		"post_clash_lockout_sec": recovery_sec
	})


func _source_actor_name(source: Node) -> String:
	if source == null:
		return ""
	if source.owner != null:
		return str(source.owner.name)
	var node: Node = source
	while node != null:
		if node is Actor8DirLimbo:
			return str(node.name)
		node = node.get_parent()
	return ""


func _actor_name() -> String:
	if _target_actor != null:
		return str(_target_actor.name)
	if owner != null:
		return str(owner.name)
	return str(get_parent().name) if get_parent() != null else ""
