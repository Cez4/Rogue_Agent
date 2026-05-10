@tool
extends BTAction
const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var min_wait_ms: int = 180
@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var hold_distance_factor: float = 0.9
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY

var _waiting_since_ms: int = -1


func _generate_name() -> String:
	return "WaitStaminaRegen"


func _tick(_delta: float) -> Status:
	if agent == null:
		_waiting_since_ms = -1
		BTDecisionTelemetryRef.emit("WaitStaminaRegen", agent, blackboard, debug_decision_var, "FAILURE", "no_agent")
		return FAILURE

	if bool(agent.has_stamina_for_attack()):
		_waiting_since_ms = -1
		BTDecisionTelemetryRef.emit("WaitStaminaRegen", agent, blackboard, debug_decision_var, "SUCCESS", "has_stamina")
		return SUCCESS

	# Important for demo-style cadence:
	# never lock the selector in this node when stamina is low.
	# Let low_stamina_tactical / chase branches decide reposition and spacing.
	_waiting_since_ms = -1
	BTDecisionTelemetryRef.emit("WaitStaminaRegen", agent, blackboard, debug_decision_var, "FAILURE", "insufficient_stamina")
	return FAILURE
