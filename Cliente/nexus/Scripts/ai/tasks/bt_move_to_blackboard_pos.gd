@tool
extends BTAction

@export var target_pos_var: StringName = &"tactical_position"
@export var arrive_tolerance: float = 12.0

func _generate_name() -> String:
	return "Move to BB Position"

func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	if not blackboard.has_var(target_pos_var):
		return FAILURE
		
	var target_pos: Vector2 = blackboard.get_var(target_pos_var) as Vector2
	var dist: float = agent.global_position.distance_to(target_pos)
	
	if dist <= arrive_tolerance:
		agent.stop_motor_movement()
		return SUCCESS
		
	agent.request_move_runtime(target_pos)
	agent.play_walk_toward(target_pos)
	return RUNNING

func _exit() -> void:
	if agent != null:
		agent.stop_motor_movement()