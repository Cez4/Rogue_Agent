@tool
extends BTAction

@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var output_pos_var: StringName = &"tactical_position"

func _generate_name() -> String:
	return "Get Approach Position"

func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	var target: Node2D = null
	if blackboard.has_var(target_var):
		target = blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		return FAILURE

	blackboard.set_var(output_pos_var, target.global_position)
	return SUCCESS