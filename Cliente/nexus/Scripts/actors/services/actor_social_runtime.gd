class_name ActorSocialRuntime
extends RefCounted
const ActorRuntimeBridgeRef = preload("res://Scripts/actors/services/actor_runtime_bridge.gd")

static func should_start_wander(actor: Node, delta: float) -> bool:
	if not actor.enable_wander or actor.player_controlled:
		return false
	if actor.is_actor_moving():
		ActorRuntimeBridgeRef.set_idle_elapsed(actor, 0.0)
		return false
	ActorRuntimeBridgeRef.set_idle_elapsed(actor, ActorRuntimeBridgeRef.get_idle_elapsed(actor) + delta)
	return ActorRuntimeBridgeRef.get_idle_elapsed(actor) >= ActorRuntimeBridgeRef.get_next_wander_delay(actor)


static func reset_wander_timer(actor: Node) -> void:
	ActorRuntimeBridgeRef.set_next_wander_delay(actor, randf_range(actor.wander_delay_min_sec, actor.wander_delay_max_sec))


static func schedule_next_wander_emote(actor: Node) -> void:
	var now_sec: float = Time.get_ticks_msec() * 0.001
	var min_cd: float = maxf(0.0, actor.wander_emote_min_cooldown_sec)
	var max_cd: float = maxf(min_cd, actor.wander_emote_max_cooldown_sec)
	ActorRuntimeBridgeRef.set_next_wander_emote_allowed(actor, now_sec + randf_range(min_cd, max_cd))


static func trigger_look_cooldown(actor: Node) -> void:
	var now_sec: float = Time.get_ticks_msec() * 0.001
	var cooldown: float = maxf(0.0, actor.look_cooldown_sec + randf_range(0.0, maxf(0.0, actor.look_cooldown_jitter_sec)))
	ActorRuntimeBridgeRef.set_next_look_allowed(actor, now_sec + cooldown)


static func can_look_target(actor: Node, target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if actor.is_actor_moving():
		return false
	var now_sec: float = Time.get_ticks_msec() * 0.001
	if now_sec < ActorRuntimeBridgeRef.get_next_look_allowed(actor):
		return false
	var min_dist: float = actor.get_perception_min_distance()
	var max_dist: float = maxf(actor.get_perception_max_distance(), actor.get_stat_value(&"perception_radius", actor.base_perception_radius))
	if max_dist < min_dist:
		max_dist = min_dist
	var dist_sq: float = actor.global_position.distance_squared_to(target.global_position)
	return dist_sq >= min_dist * min_dist and dist_sq <= max_dist * max_dist


static func show_emote(actor: Node, animation_name: StringName, loop: bool, hold_sec: float, priority: int) -> void:
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


static func hide_emote_immediate(actor: Node) -> void:
	var bubble: AnimatedSprite2D = ActorRuntimeBridgeRef.get_emotion_bubble(actor)
	if bubble == null:
		return
	bubble.stop()
	bubble.visible = false
	ActorRuntimeBridgeRef.set_current_emote_priority(actor, -1)
