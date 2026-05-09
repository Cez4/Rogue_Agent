@tool
extends BTCondition

@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var last_seen_time_var: StringName = AIBlackboardKeys.COMBAT_TARGET_LAST_SEEN_MS
@export var default_acquire_radius: float = 120.0
@export var default_lose_radius: float = 156.0
@export var default_memory_sec: float = 1.2


func _generate_name() -> String:
	return "ValidateCombatTargetPerception %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	var target := blackboard.get_var(target_var, null) as Node2D
	if not is_instance_valid(target):
		return FAILURE
	if agent == null:
		return FAILURE

	var acquire_radius: float = default_acquire_radius
	var lose_radius: float = default_lose_radius
	var memory_sec: float = default_memory_sec
	var is_manual_lock: bool = bool(agent.is_combat_target_manual_lock())
	acquire_radius = float(agent.get_combat_acquire_radius())
	lose_radius = float(agent.get_combat_lose_radius())
	memory_sec = float(agent.get_combat_target_memory_sec())
	lose_radius = maxf(lose_radius, acquire_radius)
	memory_sec = maxf(0.0, memory_sec)

	var dist_sq: float = agent.global_position.distance_squared_to(target.global_position)
	var now_ms: int = Time.get_ticks_msec()
	var has_seen: bool = blackboard.has_var(last_seen_time_var)

	if dist_sq <= lose_radius * lose_radius:
		blackboard.set_var(last_seen_time_var, now_ms)
		return SUCCESS

	# Manual lock from player intent must not be dropped by perception checks.
	if is_manual_lock:
		return SUCCESS

	# If target started outside acquire radius and was never seen, reject immediately.
	if not has_seen and dist_sq > acquire_radius * acquire_radius:
		agent.clear_combat_target()
		return FAILURE

	var last_seen_ms: int = now_ms
	if has_seen:
		last_seen_ms = int(blackboard.get_var(last_seen_time_var))
	var elapsed_sec: float = float(now_ms - last_seen_ms) * 0.001
	if elapsed_sec <= memory_sec:
		return SUCCESS

	agent.clear_combat_target()
	return FAILURE
