class_name ActorTargetingRuntime
extends RefCounted
const ActorRuntimeBridgeRef = preload("res://Scripts/actors/services/actor_runtime_bridge.gd")

static func acquire_combat_target_in_group(
	actor: Node,
	blackboard: Blackboard,
	group: StringName,
	output_var: StringName,
	last_seen_time_var: StringName,
	default_acquire_radius: float
) -> Node2D:
	var acquire_radius: float = maxf(8.0, default_acquire_radius)
	acquire_radius = maxf(8.0, float(actor.get_combat_acquire_radius()))
	var acquire_radius_sq: float = acquire_radius * acquire_radius

	var current_target: Node2D = actor.get_combat_target() as Node2D
	if is_instance_valid(current_target):
		if not bool(actor.is_target_alive_for_runtime(current_target)):
			actor.clear_combat_target()
		else:
			blackboard.set_var(output_var, current_target)
			blackboard.set_var(last_seen_time_var, Time.get_ticks_msec())
			return current_target

	var nodes: Array[Node] = actor.get_tree().get_nodes_in_group(group)
	if nodes.is_empty():
		blackboard.erase_var(output_var)
		return null

	var best_target: Node2D = null
	var best_dist_sq: float = INF
	for n in nodes:
		var candidate: Node2D = n as Node2D
		if not is_instance_valid(candidate):
			continue
		if candidate == actor:
			continue
		if not bool(actor.is_target_alive_for_runtime(candidate)):
			continue
		var dist_sq: float = actor.global_position.distance_squared_to(candidate.global_position)
		if dist_sq > acquire_radius_sq:
			continue
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_target = candidate

	if not is_instance_valid(best_target):
		blackboard.erase_var(output_var)
		return null

	actor.set_combat_target(best_target, false)
	blackboard.set_var(output_var, best_target)
	blackboard.set_var(last_seen_time_var, Time.get_ticks_msec())
	return best_target


static func validate_combat_target_alive(
	actor: Node,
	blackboard: Blackboard,
	target_var: StringName
) -> Node2D:
	if not blackboard.has_var(target_var):
		return null
	var target := blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		actor.clear_combat_target()
		return null
	if not bool(actor.is_target_alive_for_runtime(target)):
		actor.clear_combat_target()
		return null
	return target


static func validate_combat_target_perception(
	actor: Node,
	blackboard: Blackboard,
	target_var: StringName,
	last_seen_time_var: StringName,
	default_acquire_radius: float,
	default_lose_radius: float,
	default_memory_sec: float
) -> bool:
	var target := blackboard.get_var(target_var, null) as Node2D
	if not is_instance_valid(target):
		return false

	var acquire_radius: float = maxf(8.0, default_acquire_radius)
	var lose_radius: float = maxf(acquire_radius, default_lose_radius)
	var memory_sec: float = maxf(0.0, default_memory_sec)
	var is_manual_lock: bool = bool(actor.is_combat_target_manual_lock())
	acquire_radius = float(actor.get_combat_acquire_radius())
	lose_radius = float(actor.get_combat_lose_radius())
	memory_sec = float(actor.get_combat_target_memory_sec())
	lose_radius = maxf(lose_radius, acquire_radius)
	memory_sec = maxf(0.0, memory_sec)

	var dist_sq: float = actor.global_position.distance_squared_to(target.global_position)
	var now_ms: int = Time.get_ticks_msec()
	var has_seen: bool = blackboard.has_var(last_seen_time_var)

	if dist_sq <= lose_radius * lose_radius:
		blackboard.set_var(last_seen_time_var, now_ms)
		return true

	if is_manual_lock:
		return true

	if not has_seen and dist_sq > acquire_radius * acquire_radius:
		actor.clear_combat_target()
		return false

	var last_seen_ms: int = now_ms
	if has_seen:
		last_seen_ms = int(blackboard.get_var(last_seen_time_var))
	var elapsed_sec: float = float(now_ms - last_seen_ms) * 0.001
	if elapsed_sec <= memory_sec:
		return true

	actor.clear_combat_target()
	return false


static func should_reacquire_now(
	actor: Node,
	blackboard: Blackboard,
	next_reacquire_var: StringName,
	default_reacquire_interval_sec: float
) -> bool:
	var now_ms: int = Time.get_ticks_msec()
	var next_reacquire_ms: int = 0
	if blackboard.has_var(next_reacquire_var):
		next_reacquire_ms = int(blackboard.get_var(next_reacquire_var))
	if now_ms < next_reacquire_ms:
		return false
	var interval_sec: float = maxf(0.01, default_reacquire_interval_sec)
	interval_sec = maxf(0.01, float(actor.get_combat_reacquire_interval_sec()))
	blackboard.set_var(next_reacquire_var, now_ms + int(interval_sec * 1000.0))
	return true


static func set_interaction_target(actor: Node, target: Node2D, stop_range: float = -1.0) -> void:
	if target == null or not is_instance_valid(target) or target == actor:
		clear_interaction_target(actor)
		return
	var interaction_range: float = actor.interaction_stop_range
	if stop_range < 0.0:
		interaction_range = actor.interaction_stop_range
	else:
		interaction_range = maxf(8.0, stop_range)
	ActorRuntimeBridgeRef.set_interaction_target_internal(actor, target, interaction_range)


static func clear_interaction_target(actor: Node) -> void:
	ActorRuntimeBridgeRef.clear_interaction_target_internal(actor)


static func cancel_all_intents(actor: Node) -> void:
	clear_interaction_target(actor)
	actor.cancel_chase_attack()
