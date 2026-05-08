@tool
extends BTCondition

@export var target_var: StringName = &"combat_target"


func _generate_name() -> String:
	return "ValidateCombatTargetAlive %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	var target := blackboard.get_var(target_var, null) as Node2D
	if not is_instance_valid(target):
		return FAILURE
	if agent != null and agent.has_method("_is_target_alive"):
		return SUCCESS if agent._is_target_alive(target) else FAILURE
	return SUCCESS
