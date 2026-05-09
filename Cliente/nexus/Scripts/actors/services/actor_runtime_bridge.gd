class_name ActorRuntimeBridge
extends RefCounted

static func set_interaction_target_internal(actor: Actor8DirLimbo, target: Node2D, stop_range: float) -> void:
	actor._bridge_set_interaction_target_internal(target, stop_range)


static func clear_interaction_target_internal(actor: Actor8DirLimbo) -> void:
	actor._bridge_clear_interaction_target_internal()


static func play_directional(actor: Actor8DirLimbo, prefix: String, direction_source: Vector2) -> bool:
	return bool(actor._play_directional_animation(prefix, direction_source))


static func estimate_animation_length(actor: Actor8DirLimbo, animation_name: StringName) -> float:
	return float(actor._estimate_animation_length_sec(animation_name))


static func show_emote(actor: Actor8DirLimbo, animation_name: StringName, loop: bool, hold_sec: float, priority: int) -> void:
	await actor._show_emote(animation_name, loop, hold_sec, priority)


static func hide_emote(actor: Actor8DirLimbo) -> void:
	actor._hide_emote_immediate()


static func setup_stats(actor: Actor8DirLimbo) -> void:
	actor._setup_stats()


static func setup_hsm(actor: Actor8DirLimbo) -> void:
	actor._setup_hsm()


static func reset_wander_timer(actor: Actor8DirLimbo) -> void:
	actor._reset_wander_timer()


static func on_health_death(actor: Actor8DirLimbo) -> void:
	actor.on_health_death()


static func get_idle_elapsed(actor: Actor8DirLimbo) -> float:
	return float(actor._bridge_get_float_state(&"idle_elapsed"))


static func set_idle_elapsed(actor: Actor8DirLimbo, value: float) -> void:
	actor._bridge_set_float_state(&"idle_elapsed", value)


static func get_next_wander_delay(actor: Actor8DirLimbo) -> float:
	return float(actor._bridge_get_float_state(&"next_wander_delay"))


static func set_next_wander_delay(actor: Actor8DirLimbo, value: float) -> void:
	actor._bridge_set_float_state(&"next_wander_delay", value)


static func get_next_look_allowed(actor: Actor8DirLimbo) -> float:
	return float(actor._bridge_get_float_state(&"next_look_allowed"))


static func set_next_look_allowed(actor: Actor8DirLimbo, value: float) -> void:
	actor._bridge_set_float_state(&"next_look_allowed", value)


static func get_next_wander_emote_allowed(actor: Actor8DirLimbo) -> float:
	return float(actor._bridge_get_float_state(&"next_wander_emote_allowed"))


static func set_next_wander_emote_allowed(actor: Actor8DirLimbo, value: float) -> void:
	actor._bridge_set_float_state(&"next_wander_emote_allowed", value)


static func get_emote_request_id(actor: Actor8DirLimbo) -> int:
	return int(actor._bridge_get_int_state(&"emote_request_id"))


static func increment_emote_request_id(actor: Actor8DirLimbo) -> void:
	var next_id: int = get_emote_request_id(actor) + 1
	actor._bridge_set_int_state(&"emote_request_id", next_id)


static func get_current_emote_priority(actor: Actor8DirLimbo) -> int:
	return int(actor._bridge_get_int_state(&"current_emote_priority"))


static func set_current_emote_priority(actor: Actor8DirLimbo, value: int) -> void:
	actor._bridge_set_int_state(&"current_emote_priority", value)


static func get_emotion_bubble(actor: Actor8DirLimbo) -> AnimatedSprite2D:
	return actor._bridge_get_emotion_bubble()
