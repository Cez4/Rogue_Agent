@tool
extends BTAction
const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var group: StringName = &"player"
@export var output_var: StringName = &"target_player"
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY

func _generate_name() -> String:
	return "AcquireTarget %s -> %s" % [group, LimboUtility.decorate_var(output_var)]

func _tick(_delta: float) -> Status:
	if agent == null:
		BTDecisionTelemetryRef.emit("AcquireTargetInGroup", agent, blackboard, debug_decision_var, "FAILURE", "no_agent")
		return FAILURE
	var nodes: Array[Node] = agent.get_tree().get_nodes_in_group(group)
	if nodes.is_empty():
		blackboard.erase_var(output_var)
		BTDecisionTelemetryRef.emit("AcquireTargetInGroup", agent, blackboard, debug_decision_var, "FAILURE", "no_nodes_in_group")
		return FAILURE
	blackboard.set_var(output_var, nodes[0])
	BTDecisionTelemetryRef.emit("AcquireTargetInGroup", agent, blackboard, debug_decision_var, "SUCCESS", "acquired")
	return SUCCESS
