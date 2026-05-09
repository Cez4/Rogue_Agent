class_name ActorWanderRuntime
extends RefCounted

const ActorSocialRuntimeRef = preload("res://Scripts/actors/services/actor_social_runtime.gd")
const ActorRuntimeBridgeRef = preload("res://Scripts/actors/services/actor_runtime_bridge.gd")

static func should_start_wander(actor: Actor8DirLimbo, delta: float) -> bool:
	if not actor.enable_wander or actor.player_controlled:
		return false
	if actor.is_actor_moving():
		ActorRuntimeBridgeRef.set_idle_elapsed(actor, 0.0)
		return false
	ActorRuntimeBridgeRef.set_idle_elapsed(actor, ActorRuntimeBridgeRef.get_idle_elapsed(actor) + delta)
	return ActorRuntimeBridgeRef.get_idle_elapsed(actor) >= ActorRuntimeBridgeRef.get_next_wander_delay(actor)


static func begin_wander(actor: Actor8DirLimbo) -> void:
	ActorRuntimeBridgeRef.set_idle_elapsed(actor, 0.0)
	reset_wander_timer(actor)
	var target: Vector2 = pick_random_wander_target(actor)
	if actor.motor != null:
		actor.motor.request_move(target)


static func is_wander_complete(actor: Actor8DirLimbo) -> bool:
	return not actor.is_actor_moving()


static func try_play_wander_emote(actor: Actor8DirLimbo) -> void:
	if not actor.is_actor_moving():
		return
	var now_sec: float = Time.get_ticks_msec() * 0.001
	if now_sec < ActorRuntimeBridgeRef.get_next_wander_emote_allowed(actor):
		return
	if randf() > clampf(actor.wander_emote_chance, 0.0, 1.0):
		# Retry soon on miss, do not apply full cooldown or emote becomes too rare.
		ActorRuntimeBridgeRef.set_next_wander_emote_allowed(actor, now_sec + 0.9)
		return
	await ActorSocialRuntimeRef.show_emote(
		actor,
		actor.wander_emote_name,
		true,
		maxf(0.2, actor.wander_emote_hold_sec),
		1
	)
	schedule_next_wander_emote(actor)


static func schedule_next_wander_emote(actor: Actor8DirLimbo) -> void:
	var now_sec: float = Time.get_ticks_msec() * 0.001
	var min_cd: float = maxf(0.0, actor.wander_emote_min_cooldown_sec)
	var max_cd: float = maxf(min_cd, actor.wander_emote_max_cooldown_sec)
	ActorRuntimeBridgeRef.set_next_wander_emote_allowed(actor, now_sec + randf_range(min_cd, max_cd))


static func pick_random_wander_target(actor: Actor8DirLimbo) -> Vector2:
	var nav := actor.get_node_or_null(^"NavigationAgent2D") as NavigationAgent2D
	if nav == null:
		return actor.global_position
	var nav_map: RID = nav.get_navigation_map()
	if not nav_map.is_valid():
		return actor.global_position

	for _i in range(maxi(1, actor.wander_max_attempts)):
		var angle: float = randf() * TAU
		var dist: float = randf_range(actor.wander_radius_min, actor.wander_radius_max)
		var raw: Vector2 = actor.global_position + Vector2(cos(angle), sin(angle)) * dist
		var projected: Vector2 = NavigationServer2D.map_get_closest_point(nav_map, raw)
		if projected.distance_to(actor.global_position) > 8.0:
			return projected
	return actor.global_position


static func reset_wander_timer(actor: Actor8DirLimbo) -> void:
	ActorRuntimeBridgeRef.set_next_wander_delay(actor, randf_range(actor.wander_delay_min_sec, actor.wander_delay_max_sec))
