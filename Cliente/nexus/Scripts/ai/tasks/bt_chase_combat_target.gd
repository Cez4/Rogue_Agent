@tool
extends BTAction
const ActorTargetingRuntimeRef = preload("res://Scripts/actors/services/actor_targeting_runtime.gd")
const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var next_reacquire_var: StringName = AIBlackboardKeys.COMBAT_NEXT_REACQUIRE_MS
@export var default_reacquire_interval_sec: float = 0.12
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY


func _generate_name() -> String:
	return "ChaseCombatTarget %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	if not blackboard.has_var(target_var):
		BTDecisionTelemetryRef.emit("ChaseCombatTarget", agent, blackboard, debug_decision_var, "FAILURE", "missing_target_var")
		return FAILURE
	var target := blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		BTDecisionTelemetryRef.emit("ChaseCombatTarget", agent, blackboard, debug_decision_var, "FAILURE", "invalid_target")
		return FAILURE
	if agent == null:
		BTDecisionTelemetryRef.emit("ChaseCombatTarget", agent, blackboard, debug_decision_var, "FAILURE", "no_agent")
		return FAILURE
	var attack_pending: bool = false
	attack_pending = bool(agent.is_attack_pending_runtime())
	if attack_pending:
		agent.stop_motor_movement()
		BTDecisionTelemetryRef.emit("ChaseCombatTarget", agent, blackboard, debug_decision_var, "RUNNING", "attack_pending")
		return RUNNING
	var attack_range: float = float(agent.get_attack_stop_distance())
	var dist_sq: float = agent.global_position.distance_squared_to(target.global_position)
	var dist: float = sqrt(dist_sq)
	var min_sep: float = float(agent.get_min_separation_distance_to(target))
	# Only force separation when deeply overlapped; otherwise let chase close naturally.
	if dist < (min_sep * 0.6):
		var detach_pos: Vector2 = agent.compute_approach_position(target, min_sep + 4.0)
		agent.request_move_runtime(detach_pos)
		agent.play_walk_toward(detach_pos)
		CombatTelemetry.emit_event(&"separation_forced", {
			"actor": agent.name,
			"target": target.name,
			"distance": dist,
			"min_separation": min_sep
		})
		BTDecisionTelemetryRef.emit("ChaseCombatTarget", agent, blackboard, debug_decision_var, "RUNNING", "force_separation")
		return RUNNING
	if dist_sq <= attack_range * attack_range:
		agent.stop_motor_movement()
		BTDecisionTelemetryRef.emit("ChaseCombatTarget", agent, blackboard, debug_decision_var, "SUCCESS", "in_attack_range")
		return SUCCESS
	if ActorTargetingRuntimeRef.should_reacquire_now(agent, blackboard, next_reacquire_var, default_reacquire_interval_sec):
		agent.request_move_runtime(target.global_position)
		var interval_sec: float = float(agent.get_combat_reacquire_interval_sec())
		CombatTelemetry.emit_event(&"reacquire", {
			"actor": agent.name,
			"target": target.name,
			"interval_sec": interval_sec
		})
	agent.play_walk_toward(target.global_position)
	BTDecisionTelemetryRef.emit("ChaseCombatTarget", agent, blackboard, debug_decision_var, "RUNNING", "chasing")
	return RUNNING
