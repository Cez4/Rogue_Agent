class_name ActorRuntimeBridge
extends RefCounted

const CombatTelemetryRef = preload("res://Scripts/combat/combat_telemetry.gd")
const _ALLOWED_CALLER_HINTS: Array[String] = [
	"/Scripts/actors/services/",
	"/Scripts/actors/state_",
	"/Scripts/actors/actor_8dir_limbo.gd"
]

static func _guard_bridge_call(api_name: StringName) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var settings := tree.root.get_node_or_null("DebugTelemetrySettings")
	if settings == null:
		return
	if not bool(settings.get("boundary_guard_enabled")):
		return
	var stack_info: Array = get_stack()
	if stack_info.size() < 3:
		return
	var caller: Dictionary = stack_info[2] as Dictionary
	var source: String = str(caller.get("source", ""))
	var function_name: String = str(caller.get("function", ""))
	for hint in _ALLOWED_CALLER_HINTS:
		if source.find(hint) >= 0:
			return
	CombatTelemetryRef.emit_event(&"runtime_boundary_violation", {
		"api": String(api_name),
		"caller_source": source,
		"caller_function": function_name
	})

static func set_interaction_target_internal(actor: Actor8DirLimbo, target: Node2D, stop_range: float) -> void:
	_guard_bridge_call(&"set_interaction_target_internal")
	actor._bridge_set_interaction_target_internal(target, stop_range)


static func clear_interaction_target_internal(actor: Actor8DirLimbo) -> void:
	_guard_bridge_call(&"clear_interaction_target_internal")
	actor._bridge_clear_interaction_target_internal()


static func play_directional(actor: Actor8DirLimbo, prefix: String, direction_source: Vector2) -> bool:
	return bool(actor._play_directional_animation(prefix, direction_source))


static func estimate_animation_length(actor: Actor8DirLimbo, animation_name: StringName) -> float:
	return float(actor._estimate_animation_length_sec(animation_name))


static func show_emote(actor: Actor8DirLimbo, animation_name: StringName, loop: bool, hold_sec: float, priority: int) -> void:
	_guard_bridge_call(&"show_emote")
	await actor._show_emote(animation_name, loop, hold_sec, priority)


static func hide_emote(actor: Actor8DirLimbo) -> void:
	_guard_bridge_call(&"hide_emote")
	actor._hide_emote_immediate()


static func setup_stats(actor: Actor8DirLimbo) -> void:
	_guard_bridge_call(&"setup_stats")
	actor._setup_stats()


static func setup_hsm(actor: Actor8DirLimbo) -> void:
	_guard_bridge_call(&"setup_hsm")
	actor._setup_hsm()


static func reset_wander_timer(actor: Actor8DirLimbo) -> void:
	_guard_bridge_call(&"reset_wander_timer")
	actor._reset_wander_timer()


static func on_health_death(actor: Actor8DirLimbo) -> void:
	_guard_bridge_call(&"on_health_death")
	actor.on_health_death()


static func get_idle_elapsed(actor: Actor8DirLimbo) -> float:
	return actor._bridge_get_runtime_state().idle_elapsed_sec


static func set_idle_elapsed(actor: Actor8DirLimbo, value: float) -> void:
	actor._bridge_get_runtime_state().idle_elapsed_sec = value


static func get_next_wander_delay(actor: Actor8DirLimbo) -> float:
	return actor._bridge_get_runtime_state().next_wander_delay_sec


static func set_next_wander_delay(actor: Actor8DirLimbo, value: float) -> void:
	actor._bridge_get_runtime_state().next_wander_delay_sec = value


static func get_next_look_allowed(actor: Actor8DirLimbo) -> float:
	return actor._bridge_get_runtime_state().next_look_allowed_sec


static func set_next_look_allowed(actor: Actor8DirLimbo, value: float) -> void:
	actor._bridge_get_runtime_state().next_look_allowed_sec = value


static func get_next_wander_emote_allowed(actor: Actor8DirLimbo) -> float:
	return actor._bridge_get_runtime_state().next_wander_emote_allowed_sec


static func set_next_wander_emote_allowed(actor: Actor8DirLimbo, value: float) -> void:
	actor._bridge_get_runtime_state().next_wander_emote_allowed_sec = value


static func get_next_stamina_exhausted_emote_allowed(actor: Actor8DirLimbo) -> float:
	return actor._bridge_get_runtime_state().next_stamina_exhausted_emote_allowed_sec


static func set_next_stamina_exhausted_emote_allowed(actor: Actor8DirLimbo, value: float) -> void:
	actor._bridge_get_runtime_state().next_stamina_exhausted_emote_allowed_sec = value


static func get_emote_request_id(actor: Actor8DirLimbo) -> int:
	return actor._bridge_get_runtime_state().emote_request_id


static func increment_emote_request_id(actor: Actor8DirLimbo) -> void:
	var next_id: int = get_emote_request_id(actor) + 1
	actor._bridge_get_runtime_state().emote_request_id = next_id


static func get_current_emote_priority(actor: Actor8DirLimbo) -> int:
	return actor._bridge_get_runtime_state().current_emote_priority


static func set_current_emote_priority(actor: Actor8DirLimbo, value: int) -> void:
	actor._bridge_get_runtime_state().current_emote_priority = value


static func get_emotion_bubble(actor: Actor8DirLimbo) -> AnimatedSprite2D:
	return actor._bridge_get_emotion_bubble()
