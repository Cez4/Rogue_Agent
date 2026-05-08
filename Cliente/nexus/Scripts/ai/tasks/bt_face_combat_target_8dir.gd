@tool
extends BTAction

@export var target_var: StringName = &"combat_target"


func _generate_name() -> String:
	return "FaceCombatTarget8Dir %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	var target := blackboard.get_var(target_var, null) as Node2D
	if not is_instance_valid(target):
		return FAILURE
	if agent != null and agent.has_method("face_toward"):
		agent.face_toward(target.global_position)
	return SUCCESS
