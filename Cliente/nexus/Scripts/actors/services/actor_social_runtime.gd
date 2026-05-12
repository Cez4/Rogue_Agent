class_name ActorSocialRuntime
extends RefCounted
const ActorRuntimeBridgeRef = preload("res://Scripts/actors/services/actor_runtime_bridge.gd")
const CombatTelemetryRef = preload("res://Scripts/combat/combat_telemetry.gd")


static func trigger_look_cooldown(actor: Actor8DirLimbo) -> void:
	var now_sec: float = Time.get_ticks_msec() * 0.001
	var cooldown_sec: float = ActorSocialProfileRuntime.look_cooldown_sec(actor)
	var jitter_sec: float = ActorSocialProfileRuntime.look_cooldown_jitter_sec(actor)
	var cooldown: float = maxf(0.0, cooldown_sec + randf_range(0.0, maxf(0.0, jitter_sec)))
	ActorRuntimeBridgeRef.set_next_look_allowed(actor, now_sec + cooldown)


static func can_look_target(actor: Actor8DirLimbo, target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if actor.is_actor_moving():
		return false
	var now_sec: float = Time.get_ticks_msec() * 0.001
	if now_sec < ActorRuntimeBridgeRef.get_next_look_allowed(actor):
		return false
	var min_dist: float = ActorSocialProfileRuntime.look_interest_min_distance(actor)
	var max_dist: float = ActorSocialProfileRuntime.look_interest_max_distance(actor)
	if max_dist < min_dist:
		max_dist = min_dist
	var dist_sq: float = actor.global_position.distance_squared_to(target.global_position)
	return dist_sq >= min_dist * min_dist and dist_sq <= max_dist * max_dist


static func show_emote(actor: Actor8DirLimbo, animation_name: StringName, loop: bool, hold_sec: float, priority: int) -> void:
	var bubble: AnimatedSprite2D = ActorRuntimeBridgeRef.get_emotion_bubble(actor)
	if bubble == null or bubble.sprite_frames == null:
		return
	if not bubble.sprite_frames.has_animation(animation_name):
		return
	if priority < ActorRuntimeBridgeRef.get_current_emote_priority(actor):
		return

	ActorRuntimeBridgeRef.set_current_emote_priority(actor, priority)
	ActorRuntimeBridgeRef.increment_emote_request_id(actor)
	var request_id: int = ActorRuntimeBridgeRef.get_emote_request_id(actor)

	bubble.visible = true
	bubble.animation = animation_name
	bubble.sprite_frames.set_animation_loop(animation_name, loop)
	bubble.play(animation_name)

	await actor.get_tree().create_timer(maxf(0.05, hold_sec)).timeout
	if request_id != ActorRuntimeBridgeRef.get_emote_request_id(actor):
		return
	hide_emote_immediate(actor)


static func hide_emote_immediate(actor: Actor8DirLimbo) -> void:
	var bubble: AnimatedSprite2D = ActorRuntimeBridgeRef.get_emotion_bubble(actor)
	if bubble == null:
		return
	bubble.stop()
	bubble.visible = false
	ActorRuntimeBridgeRef.set_current_emote_priority(actor, -1)


static func try_play_stamina_exhausted_emote(actor: Actor8DirLimbo) -> void:
	var emote_name: StringName = ActorSocialProfileRuntime.stamina_exhausted_emote_name(actor)
	if emote_name == &"":
		return
	var now_sec: float = Time.get_ticks_msec() * 0.001
	if now_sec < ActorRuntimeBridgeRef.get_next_stamina_exhausted_emote_allowed(actor):
		return
	var cooldown_sec: float = maxf(0.0, ActorSocialProfileRuntime.stamina_exhausted_emote_cooldown_sec(actor))
	ActorRuntimeBridgeRef.set_next_stamina_exhausted_emote_allowed(actor, now_sec + cooldown_sec)
	await show_emote(
		actor,
		emote_name,
		false,
		maxf(0.2, ActorSocialProfileRuntime.stamina_exhausted_emote_hold_sec(actor)),
		3
	)
	CombatTelemetryRef.emit_event(&"stamina_exhausted_emote", {
		"actor": actor.name
	})
