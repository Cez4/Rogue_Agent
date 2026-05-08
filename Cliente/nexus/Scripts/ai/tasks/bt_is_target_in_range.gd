@tool
extends BTCondition

@export var target_var: StringName = &"target_player"
@export var distance_var: StringName = &"look_interest_radius"

func _generate_name() -> String:
	return "IsTargetInRange %s" % LimboUtility.decorate_var(target_var)

func _tick(_delta: float) -> Status:
	var target := blackboard.get_var(target_var, null) as Node2D
	if not is_instance_valid(target):
		return FAILURE

	if agent != null and agent.has_method("can_look_target"):
		return SUCCESS if agent.can_look_target(target) else FAILURE

	var max_distance: float = 120.0
	if agent != null and agent.has_method("get"):
		max_distance = float(agent.get(StringName(distance_var)))
	var dist_sq: float = agent.global_position.distance_squared_to(target.global_position)
	return SUCCESS if dist_sq <= max_distance * max_distance else FAILURE
