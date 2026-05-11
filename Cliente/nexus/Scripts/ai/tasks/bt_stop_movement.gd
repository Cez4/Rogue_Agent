@tool
extends BTAction

func _generate_name() -> String:
	return "Stop & Idle"

func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	agent.stop_motor_movement()
	agent.play_idle_animation()
	return SUCCESS