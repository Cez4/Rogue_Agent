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
	if agent.has_method("set_combat_target"):
		agent.set_combat_target(target)
	return RUNNING
