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

	var target: Node2D = null
	if blackboard.has_var(target_var):
		target = blackboard.get_var(target_var) as Node2D
	if is_instance_valid(target):
		var engage_distance: float = maxf(4.0, float(agent.get_attack_engage_distance()))
		var distance_to_target: float = agent.global_position.distance_to(target.global_position)
		if distance_to_target > engage_distance * maxf(0.5, hold_distance_factor):
			_waiting_since_ms = -1
			BTDecisionTelemetryRef.emit("WaitStaminaRegen", agent, blackboard, debug_decision_var, "FAILURE", "no_stamina_reposition")
			return FAILURE

	agent.stop_motor_movement()
	var now_ms: int = Time.get_ticks_msec()
	if _waiting_since_ms < 0:
		_waiting_since_ms = now_ms
		BTDecisionTelemetryRef.emit("WaitStaminaRegen", agent, blackboard, debug_decision_var, "RUNNING", "wait_start")
		return RUNNING
	if now_ms - _waiting_since_ms < max(0, min_wait_ms):
		BTDecisionTelemetryRef.emit("WaitStaminaRegen", agent, blackboard, debug_decision_var, "RUNNING", "waiting")
		return RUNNING
	_waiting_since_ms = now_ms
	BTDecisionTelemetryRef.emit("WaitStaminaRegen", agent, blackboard, debug_decision_var, "RUNNING", "retry_window")
	return RUNNING
