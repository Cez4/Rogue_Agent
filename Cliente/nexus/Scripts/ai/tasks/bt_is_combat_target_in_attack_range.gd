@tool
extends BTCondition

@export var target_var: StringName = &"combat_target"
@export var default_attack_stop_distance: float = 28.0
@export var blocked_reason_var: StringName = &"last_attack_blocked_reason"
@export var blocked_reason_next_emit_ms_var: StringName = &"attack_blocked_next_emit_ms"
@export var blocked_reason_emit_cooldown_sec: float = 0.65


func _generate_name() -> String:
	return "IsCombatTargetInAttackRange %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	if not blackboard.has_var(target_var):
		return FAILURE
	var target := blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		blackboard.set_var(blocked_reason_var, "invalid_target")
		return FAILURE
	if agent == null:
		blackboard.set_var(blocked_reason_var, "missing_agent")
		return FAILURE
	var attack_range: float = default_attack_stop_distance
	if agent.has_method("get_attack_stop_distance"):
		attack_range = float(agent.get_attack_stop_distance())
	elif agent.has_method("get_attack_range"):
		attack_range = float(agent.get_attack_range())
	var dist_sq: float = agent.global_position.distance_squared_to(target.global_position)
	if dist_sq <= attack_range * attack_range:
		blackboard.set_var(blocked_reason_var, "")
		return SUCCESS
	var previous_reason: String = ""
	if blackboard.has_var(blocked_reason_var):
		previous_reason = str(blackboard.get_var(blocked_reason_var))
	blackboard.set_var(blocked_reason_var, "out_of_range")
	var now_ms: int = Time.get_ticks_msec()
	var next_emit_ms: int = 0
	if blackboard.has_var(blocked_reason_next_emit_ms_var):
		next_emit_ms = int(blackboard.get_var(blocked_reason_next_emit_ms_var))
	if previous_reason != "out_of_range" or now_ms >= next_emit_ms:
		CombatTelemetry.emit_event(&"attack_blocked_reason", {
			"actor": agent.name,
			"target": target.name,
			"reason": "out_of_range",
			"attack_stop_distance": attack_range
		})
		var cooldown_ms: int = int(maxf(0.0, blocked_reason_emit_cooldown_sec) * 1000.0)
		blackboard.set_var(blocked_reason_next_emit_ms_var, now_ms + cooldown_ms)
	return FAILURE
