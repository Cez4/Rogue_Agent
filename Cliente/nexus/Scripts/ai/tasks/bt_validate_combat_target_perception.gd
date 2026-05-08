@tool
extends BTCondition

@export var target_var: StringName = &"combat_target"
@export var last_seen_time_var: StringName = &"combat_target_last_seen_ms"


func _generate_name() -> String:
	return "ValidateCombatTargetPerception %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	var target := blackboard.get_var(target_var, null) as Node2D
	if not is_instance_valid(target):
		return FAILURE
	if agent == null:
		return FAILURE

	var lose_radius: float = 160.0
	var memory_sec: float = 1.2
	if agent.has_method("get_combat_lose_radius"):
		lose_radius = float(agent.get_combat_lose_radius())
	if agent.has_method("get_combat_target_memory_sec"):
		memory_sec = float(agent.get_combat_target_memory_sec())

	var dist_sq: float = agent.global_position.distance_squared_to(target.global_position)
	var now_ms: int = Time.get_ticks_msec()

	if dist_sq <= lose_radius * lose_radius:
		blackboard.set_var(last_seen_time_var, now_ms)
		return SUCCESS

	var last_seen_ms: int = now_ms
	if blackboard.has_var(last_seen_time_var):
		last_seen_ms = int(blackboard.get_var(last_seen_time_var))
	var elapsed_sec: float = float(now_ms - last_seen_ms) * 0.001
	if elapsed_sec <= memory_sec:
		return SUCCESS

	if agent.has_method("clear_combat_target"):
		agent.clear_combat_target()
	return FAILURE
