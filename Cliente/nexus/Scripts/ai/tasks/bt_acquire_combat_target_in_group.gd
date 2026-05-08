@tool
extends BTAction

@export var group: StringName = &"player"
@export var output_var: StringName = &"combat_target"
@export var last_seen_time_var: StringName = &"combat_target_last_seen_ms"
@export var default_acquire_radius: float = 120.0


func _generate_name() -> String:
	return "AcquireCombatTarget %s -> %s" % [group, LimboUtility.decorate_var(output_var)]


func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE

	var acquire_radius: float = default_acquire_radius
	if agent.has_method("get_combat_acquire_radius"):
		acquire_radius = float(agent.get_combat_acquire_radius())
	acquire_radius = maxf(8.0, acquire_radius)
	var acquire_radius_sq: float = acquire_radius * acquire_radius

	var current_target: Node2D = null
	if agent.has_method("get"):
		current_target = agent.get("_combat_target") as Node2D
	if is_instance_valid(current_target):
		if agent.has_method("_is_target_alive") and not bool(agent._is_target_alive(current_target)):
			if agent.has_method("clear_combat_target"):
				agent.clear_combat_target()
		else:
			blackboard.set_var(output_var, current_target)
			blackboard.set_var(last_seen_time_var, Time.get_ticks_msec())
			return SUCCESS

	var nodes: Array[Node] = agent.get_tree().get_nodes_in_group(group)
	if nodes.is_empty():
		blackboard.erase_var(output_var)
		return FAILURE

	var best_target: Node2D = null
	var best_dist_sq: float = INF
	for n in nodes:
		var candidate: Node2D = n as Node2D
		if not is_instance_valid(candidate):
			continue
		if candidate == agent:
			continue
		if agent.has_method("_is_target_alive") and not bool(agent._is_target_alive(candidate)):
			continue
		var dist_sq: float = agent.global_position.distance_squared_to(candidate.global_position)
		if dist_sq > acquire_radius_sq:
			continue
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_target = candidate

	if not is_instance_valid(best_target):
		blackboard.erase_var(output_var)
		return FAILURE

	if agent.has_method("set_combat_target"):
		agent.set_combat_target(best_target, false)
	blackboard.set_var(output_var, best_target)
	blackboard.set_var(last_seen_time_var, Time.get_ticks_msec())
	return SUCCESS
