@tool
extends BTCondition

const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var threshold_ratio: float = 0.2
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY

func _generate_name() -> String:
	return "Is Stamina Low"

func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	var stamina := agent.get_node_or_null(^"Stamina") as StaminaComponent
	if stamina == null:
		BTDecisionTelemetryRef.emit("IsStaminaLow", agent, blackboard, debug_decision_var, "FAILURE", "no_stamina_component")
		return FAILURE
	if stamina.is_exhausted() or stamina.get_stamina_ratio() <= threshold_ratio:
		BTDecisionTelemetryRef.emit("IsStaminaLow", agent, blackboard, debug_decision_var, "SUCCESS", "stamina_low")
		return SUCCESS
	BTDecisionTelemetryRef.emit("IsStaminaLow", agent, blackboard, debug_decision_var, "FAILURE", "stamina_ok")
	return FAILURE