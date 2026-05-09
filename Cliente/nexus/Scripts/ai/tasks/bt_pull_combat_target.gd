@tool
extends BTAction

@export var output_var: StringName = &"combat_target"


func _generate_name() -> String:
	return "PullCombatTarget -> %s" % LimboUtility.decorate_var(output_var)


func _tick(_delta: float) -> Status:
	if agent == null or not agent.has_method("get_combat_target"):
		return FAILURE
	var target: Variant = agent.get_combat_target()
	if target == null or not is_instance_valid(target):
		blackboard.erase_var(output_var)
		return FAILURE
	blackboard.set_var(output_var, target)
	return SUCCESS
