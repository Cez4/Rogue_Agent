@tool
extends BTAction

const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var output_pos_var: StringName = &"tactical_position"
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY

func _generate_name() -> String:
	return "Get Approach Position"

func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	var target: Node2D = null
	if blackboard.has_var(target_var):
		target = blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		BTDecisionTelemetryRef.emit("GetApproachPosition", agent, blackboard, debug_decision_var, "FAILURE", "no_target")
		return FAILURE

	blackboard.set_var(output_pos_var, target.global_position)
	BTDecisionTelemetryRef.emit("GetApproachPosition", agent, blackboard, debug_decision_var, "SUCCESS", "calculated_approach_pos")
	return SUCCESS