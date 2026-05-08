@tool
extends BTAction

@export var target_var: StringName = &"combat_target"


func _generate_name() -> String:
	return "ChaseCombatTarget %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	var target := blackboard.get_var(target_var, null) as Node2D
	if not is_instance_valid(target):
		return FAILURE
	if agent == null:
		return FAILURE
	var motor_node: Variant = null
	if agent.has_method("get"):
		motor_node = agent.get("motor")
	if agent.has_method("get_attack_range"):
		var attack_range: float = float(agent.get_attack_range())
		var dist_sq: float = agent.global_position.distance_squared_to(target.global_position)
		if dist_sq <= attack_range * attack_range:
			if motor_node != null and motor_node.has_method("stop"):
				motor_node.stop()
			return SUCCESS
	if motor_node != null and motor_node.has_method("request_move"):
		motor_node.request_move(target.global_position)
	if agent.has_method("play_walk_toward"):
		agent.play_walk_toward(target.global_position)
	return RUNNING
