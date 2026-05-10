@tool
extends BTAction
const ActorTargetingRuntimeRef = preload("res://Scripts/actors/services/actor_targeting_runtime.gd")
const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var next_reacquire_var: StringName = AIBlackboardKeys.COMBAT_NEXT_REACQUIRE_MS
@export var default_reacquire_interval_sec: float = 0.12
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY
@export var move_repath_interval_sec: float = 0.2
@export var move_retarget_threshold: float = 16.0
@export var attack_range_hysteresis: float = 1.5
@export var stuck_speed_threshold_px: float = 2.0
@export var stuck_timeout_ms: int = 220
@export var telemetry_emit_cooldown_sec: float = 0.35
@export var telemetry_success_emit_cooldown_sec: float = 0.9

var _next_move_request_ms: int = 0
var _last_move_target: Vector2 = Vector2.INF
var _last_actor_pos: Vector2 = Vector2.INF
var _stuck_since_ms: int = 0
var _last_telemetry_signature: String = ""
var _next_telemetry_emit_ms: int = 0


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
	var attack_range: float = float(agent.get_attack_engage_distance())
	var dist_sq: float = agent.global_position.distance_squared_to(target.global_position)
	var dist: float = sqrt(dist_sq)
	var min_sep: float = float(agent.get_min_separation_distance_to(target))
	var now_ms: int = Time.get_ticks_msec()
	# Attack gating must respect physical separation floor; otherwise some archetypes can never enter attack range.
	var effective_attack_range: float = maxf(attack_range, min_sep + 2.0)
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
		_emit_chase_state(now_ms, {
			"actor": agent.name,
			"target": target.name,
			"status": "running",
			"reason": "force_separation",
			"distance": dist,
			"effective_attack_range": effective_attack_range,
			"min_separation_distance": min_sep
		})
		BTDecisionTelemetryRef.emit("ChaseCombatTarget", agent, blackboard, debug_decision_var, "RUNNING", "force_separation")
		return RUNNING
	var chase_check_range: float = effective_attack_range + maxf(0.0, attack_range_hysteresis)
	if dist_sq <= chase_check_range * chase_check_range:
		agent.stop_motor_movement()
		_emit_chase_state(now_ms, {
			"actor": agent.name,
			"target": target.name,
			"status": "success",
			"reason": "in_attack_range",
			"distance": dist,
			"effective_attack_range": effective_attack_range,
			"chase_check_range": chase_check_range,
			"min_separation_distance": min_sep
		})
		BTDecisionTelemetryRef.emit("ChaseCombatTarget", agent, blackboard, debug_decision_var, "SUCCESS", "in_attack_range")
		return SUCCESS

	# Chase to a ring near real attack engage range to avoid early stop/flip.
	var approach_dist: float = maxf(4.0, chase_check_range - 0.75)
	var approach_pos: Vector2 = agent.compute_approach_position(target, approach_dist)
	var should_refresh_move: bool = false
	var stuck_refresh: bool = false
	if _last_actor_pos == Vector2.INF:
		_last_actor_pos = agent.global_position
		_stuck_since_ms = now_ms
	else:
		var moved_px: float = _last_actor_pos.distance_to(agent.global_position)
		if moved_px <= maxf(0.1, stuck_speed_threshold_px) and dist > (chase_check_range + 1.0):
			if _stuck_since_ms == 0:
				_stuck_since_ms = now_ms
			elif (now_ms - _stuck_since_ms) >= max(50, stuck_timeout_ms):
				stuck_refresh = true
		else:
			_stuck_since_ms = now_ms
		_last_actor_pos = agent.global_position
	if _last_move_target == Vector2.INF:
		should_refresh_move = true
	elif _last_move_target.distance_to(approach_pos) >= maxf(1.0, move_retarget_threshold):
		should_refresh_move = true
	elif now_ms >= _next_move_request_ms:
		should_refresh_move = true
	if stuck_refresh:
		should_refresh_move = true
	# Guard rail: if we're still out of range but locomotion is effectively idle,
	# force a repath refresh to avoid limbo loops near threshold distances.
	if not should_refresh_move and dist > (chase_check_range + 0.5) and not bool(agent.is_actor_moving()):
		should_refresh_move = true
		stuck_refresh = true
	if should_refresh_move:
		if stuck_refresh:
			agent.request_move_runtime(target.global_position)
		else:
			agent.request_move_runtime(approach_pos)
		_last_move_target = approach_pos
		var repath_ms: int = int(maxf(0.05, move_repath_interval_sec) * 1000.0)
		_next_move_request_ms = now_ms + repath_ms
	if ActorTargetingRuntimeRef.should_reacquire_now(agent, blackboard, next_reacquire_var, default_reacquire_interval_sec):
		var interval_sec: float = float(agent.get_combat_reacquire_interval_sec())
		CombatTelemetry.emit_event(&"reacquire", {
			"actor": agent.name,
			"target": target.name,
			"interval_sec": interval_sec,
			"distance": dist,
			"attack_stop_distance": attack_range,
			"effective_attack_range": effective_attack_range,
			"min_separation_distance": min_sep
		})
	agent.play_walk_toward(target.global_position)
	_emit_chase_state(now_ms, {
		"actor": agent.name,
		"target": target.name,
		"status": "running",
		"reason": "chasing",
		"distance": dist,
		"effective_attack_range": effective_attack_range,
		"chase_check_range": chase_check_range,
		"approach_distance": approach_dist,
		"move_refresh": should_refresh_move,
		"stuck_refresh": stuck_refresh,
		"min_separation_distance": min_sep
	})
	BTDecisionTelemetryRef.emit("ChaseCombatTarget", agent, blackboard, debug_decision_var, "RUNNING", "chasing")
	return RUNNING


func _exit() -> void:
	_next_move_request_ms = 0
	_last_move_target = Vector2.INF
	_last_actor_pos = Vector2.INF
	_stuck_since_ms = 0


func _emit_chase_state(now_ms: int, payload: Dictionary) -> void:
	var status_label: String = str(payload.get("status", ""))
	var reason: String = str(payload.get("reason", ""))
	var actor_name: String = str(payload.get("actor", ""))
	var target_name: String = str(payload.get("target", ""))
	var signature: String = "%s|%s|%s|%s" % [actor_name, target_name, status_label, reason]
	var cooldown_sec: float = telemetry_emit_cooldown_sec
	if status_label == "success":
		cooldown_sec = telemetry_success_emit_cooldown_sec
	var emit_now: bool = signature != _last_telemetry_signature or now_ms >= _next_telemetry_emit_ms
	if not emit_now:
		return
	CombatTelemetry.emit_event(&"bt_chase_state", payload)
	_last_telemetry_signature = signature
	_next_telemetry_emit_ms = now_ms + int(maxf(0.05, cooldown_sec) * 1000.0)
