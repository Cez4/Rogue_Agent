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

	if agent == null:
		return FAILURE
	return SUCCESS if agent.can_look_target(target) else FAILURE
