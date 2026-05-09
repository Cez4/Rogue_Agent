@tool
extends BTAction

@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET


func _generate_name() -> String:
	return "FaceCombatTarget8Dir %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	if not blackboard.has_var(target_var):
		return FAILURE
	var target := blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		return FAILURE
	if agent == null:
		return FAILURE
	agent.face_toward(target.global_position)
	return SUCCESS
