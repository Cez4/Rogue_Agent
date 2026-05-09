@tool
extends BTAction

@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var next_reacquire_var: StringName = AIBlackboardKeys.COMBAT_NEXT_REACQUIRE_MS
@export var default_reacquire_interval_sec: float = 0.12


func _generate_name() -> String:
	return "ChaseCombatTarget %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	if not blackboard.has_var(target_var):
		return FAILURE
	var target := blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		return FAILURE
	if agent == null:
		return FAILURE
	var attack_pending: bool = false
	attack_pending = bool(agent.is_attack_pending_runtime())
	if attack_pending:
		agent.stop_motor_movement()
		return RUNNING
	var attack_range: float = float(agent.get_attack_stop_distance())
	var dist_sq: float = agent.global_position.distance_squared_to(target.global_position)
	if dist_sq <= attack_range * attack_range:
		agent.stop_motor_movement()
		return SUCCESS
	var now_ms: int = Time.get_ticks_msec()
	var next_reacquire_ms: int = 0
	if blackboard.has_var(next_reacquire_var):
		next_reacquire_ms = int(blackboard.get_var(next_reacquire_var))
	if now_ms >= next_reacquire_ms:
		agent.request_move_runtime(target.global_position)
		var interval_sec: float = float(agent.get_combat_reacquire_interval_sec())
		blackboard.set_var(next_reacquire_var, now_ms + int(interval_sec * 1000.0))
		CombatTelemetry.emit_event(&"reacquire", {
			"actor": agent.name,
			"target": target.name,
			"interval_sec": interval_sec
		})
	agent.play_walk_toward(target.global_position)
	return RUNNING
