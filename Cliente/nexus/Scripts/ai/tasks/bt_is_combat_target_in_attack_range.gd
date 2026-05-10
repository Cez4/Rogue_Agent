@tool
extends BTCondition
const CombatBlockedReasonsRef = preload("res://Scripts/combat/combat_blocked_reasons.gd")
const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var default_attack_stop_distance: float = 28.0
@export var blocked_reason_var: StringName = AIBlackboardKeys.LAST_ATTACK_BLOCKED_REASON
@export var blocked_reason_next_emit_ms_var: StringName = AIBlackboardKeys.ATTACK_BLOCKED_NEXT_EMIT_MS
@export var blocked_reason_emit_cooldown_sec: float = 0.65
@export var attack_range_hysteresis: float = 8.0
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY


func _generate_name() -> String:
	return "IsCombatTargetInAttackRange %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	if not blackboard.has_var(target_var):
		BTDecisionTelemetryRef.emit("IsCombatTargetInAttackRange", agent, blackboard, debug_decision_var, "FAILURE", "missing_target_var")
		return FAILURE
	var target := blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		blackboard.set_var(blocked_reason_var, CombatBlockedReasonsRef.INVALID_TARGET)
		BTDecisionTelemetryRef.emit("IsCombatTargetInAttackRange", agent, blackboard, debug_decision_var, "FAILURE", "invalid_target")
		return FAILURE
	if agent == null:
		blackboard.set_var(blocked_reason_var, CombatBlockedReasonsRef.MISSING_AGENT)
		BTDecisionTelemetryRef.emit("IsCombatTargetInAttackRange", agent, blackboard, debug_decision_var, "FAILURE", "missing_agent")
		return FAILURE
	var attack_range: float = float(agent.get_attack_engage_distance())
	var min_sep: float = float(agent.get_min_separation_distance_to(target))
	var effective_attack_range: float = maxf(attack_range, min_sep + 0.5)
	var dist_sq: float = agent.global_position.distance_squared_to(target.global_position)
	var settle_attack_range: float = effective_attack_range + maxf(0.0, attack_range_hysteresis)
	if dist_sq <= settle_attack_range * settle_attack_range:
		blackboard.set_var(blocked_reason_var, CombatBlockedReasonsRef.NONE)
		BTDecisionTelemetryRef.emit("IsCombatTargetInAttackRange", agent, blackboard, debug_decision_var, "SUCCESS", "in_range")
		return SUCCESS
	var previous_reason: String = ""
	if blackboard.has_var(blocked_reason_var):
		previous_reason = str(blackboard.get_var(blocked_reason_var))
	blackboard.set_var(blocked_reason_var, CombatBlockedReasonsRef.OUT_OF_RANGE)
	var now_ms: int = Time.get_ticks_msec()
	var next_emit_ms: int = 0
	if blackboard.has_var(blocked_reason_next_emit_ms_var):
		next_emit_ms = int(blackboard.get_var(blocked_reason_next_emit_ms_var))
	if previous_reason != CombatBlockedReasonsRef.OUT_OF_RANGE or now_ms >= next_emit_ms:
		CombatTelemetry.emit_event(&"attack_blocked_reason", {
			"actor": agent.name,
			"target": target.name,
			"reason": CombatBlockedReasonsRef.OUT_OF_RANGE,
			"attack_stop_distance": attack_range,
			"effective_attack_range": effective_attack_range,
			"min_separation_distance": min_sep
		})
		var cooldown_ms: int = int(maxf(0.0, blocked_reason_emit_cooldown_sec) * 1000.0)
		blackboard.set_var(blocked_reason_next_emit_ms_var, now_ms + cooldown_ms)
	BTDecisionTelemetryRef.emit("IsCombatTargetInAttackRange", agent, blackboard, debug_decision_var, "FAILURE", "out_of_range")
	return FAILURE
