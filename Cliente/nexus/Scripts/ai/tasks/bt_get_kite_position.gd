@tool
extends BTAction

@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var output_pos_var: StringName = &"tactical_position"

func _generate_name() -> String:
	return "Get Kite Position"

func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	var target: Node2D = null
	if blackboard.has_var(target_var):
		target = blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		return FAILURE

	var away_dir: Vector2 = (agent.global_position - target.global_position).normalized()
	if away_dir.is_zero_approx():
		away_dir = Vector2.RIGHT.rotated(randf() * TAU)

	# Fuga massiva garantida de 60 pixels + raio
	var destination: Vector2 = target.global_position + away_dir * 85.0
	
	blackboard.set_var(output_pos_var, destination)
	return SUCCESS