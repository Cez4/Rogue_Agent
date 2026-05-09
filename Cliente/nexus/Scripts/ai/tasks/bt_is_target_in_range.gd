@tool
extends BTCondition
const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var target_var: StringName = &"target_player"
@export var distance_var: StringName = &"look_interest_radius"
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY

func _generate_name() -> String:
	return "IsTargetInRange %s" % LimboUtility.decorate_var(target_var)

func _tick(_delta: float) -> Status:
	var target := blackboard.get_var(target_var, null) as Node2D
	if not is_instance_valid(target):
		BTDecisionTelemetryRef.emit("IsTargetInRange", agent, blackboard, debug_decision_var, "FAILURE", "invalid_target")
		return FAILURE

	if agent == null:
		BTDecisionTelemetryRef.emit("IsTargetInRange", agent, blackboard, debug_decision_var, "FAILURE", "no_agent")
		return FAILURE
	if agent.can_look_target(target):
		BTDecisionTelemetryRef.emit("IsTargetInRange", agent, blackboard, debug_decision_var, "SUCCESS", "in_range")
		return SUCCESS
	BTDecisionTelemetryRef.emit("IsTargetInRange", agent, blackboard, debug_decision_var, "FAILURE", "out_of_range")
	return FAILURE
