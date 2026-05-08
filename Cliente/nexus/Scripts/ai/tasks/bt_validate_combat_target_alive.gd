@tool
extends BTCondition

@export var target_var: StringName = &"combat_target"


func _generate_name() -> String:
	return "ValidateCombatTargetAlive %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	if not blackboard.has_var(target_var):
		return FAILURE
	var target := blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		if agent != null and agent.has_method("clear_combat_target"):
			agent.clear_combat_target()
		return FAILURE
	if agent != null and agent.has_method("_is_target_alive"):
		if agent._is_target_alive(target):
			return SUCCESS
		if agent.has_method("clear_combat_target"):
			agent.clear_combat_target()
		return FAILURE
	return SUCCESS
