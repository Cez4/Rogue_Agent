@tool
extends BTAction

const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY

func _generate_name() -> String:
	return "Stop & Idle"

func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	agent.stop_motor_movement()
	agent.play_idle_animation()
	BTDecisionTelemetryRef.emit("StopMovement", agent, blackboard, debug_decision_var, "SUCCESS", "stopped")
	return SUCCESS