@tool
extends BTAction

const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY
@export var min_reposition_interval_ms: int = 260
@export var telemetry_dedupe_ms: int = 300
@export var arrive_tolerance: float = 10.0
@export var post_move_hold_ms: int = 300
@export var disengage_distance_factor: float = 1.8

var _next_reposition_ms: int = 0
var _last_event_key: String = ""
var _last_event_ms: int = -1
var _low_stamina_active: bool = false
var _is_committed_move: bool = false
var _committed_destination: Vector2 = Vector2.ZERO
var _hold_until_ms: int = 0


func _generate_name() -> String:
	return "LowStaminaTactical"


func _tick(_delta: float) -> Status:
	if agent == null:
		BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "FAILURE", "no_agent")
		return FAILURE

	if bool(agent.has_stamina_for_attack()):
		if _low_stamina_active:
			_emit_tactical_event("low_stamina_tactical_exit", {
				"actor": agent.name,
				"reason": "has_stamina"
			}, "exit_has_stamina")
			_low_stamina_active = false
		_is_committed_move = false
		_hold_until_ms = 0
		BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "FAILURE", "has_stamina")
		return FAILURE

	_low_stamina_active = true

	# Never issue tactical movement while an attack is committed/running.
	if bool(agent.is_attack_pending_runtime()):
		_is_committed_move = false
		_hold_until_ms = 0
		agent.stop_motor_movement()
		BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "FAILURE", "attack_pending")
		return FAILURE

	var target: Node2D = null
	if blackboard.has_var(target_var):
		target = blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		agent.stop_motor_movement()
		_emit_tactical_event("low_stamina_tactical_hold", {
			"actor": agent.name,
			"reason": "no_target"
		}, "hold_no_target")
		BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "RUNNING", "hold_no_target")
		return RUNNING

	var now_ms: int = Time.get_ticks_msec()

	# Demo-style commit movement: once chosen, finish it before rethinking.
	if _is_committed_move:
		var remaining: float = agent.global_position.distance_to(_committed_destination)
		if remaining <= maxf(2.0, arrive_tolerance):
			agent.stop_motor_movement()
			_is_committed_move = false
			_hold_until_ms = now_ms + max(0, post_move_hold_ms)
			_emit_tactical_event("low_stamina_tactical_hold", {
				"actor": agent.name,
				"reason": "arrived_commit_point",
				"remaining": remaining
			}, "hold_after_arrive")
			BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "RUNNING", "arrived_commit_point")
			return RUNNING
		agent.request_move_runtime(_committed_destination)
		agent.play_walk_toward(_committed_destination)
		BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "RUNNING", "committed_move")
		return RUNNING

	if now_ms < _hold_until_ms:
		agent.stop_motor_movement()
		# Do not hard-block tree while briefly holding; allow chase/face reevaluation.
		BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "FAILURE", "post_move_hold")
		return FAILURE

	var dist: float = agent.global_position.distance_to(target.global_position)
	var stop_dist: float = maxf(4.0, float(agent.get_attack_stop_distance()))
	var dyn_dist: float = maxf(0.0, float(agent.get_low_stamina_kite_distance()))
	var dyn_cd_ms: int = max(0, int(agent.get_low_stamina_kite_cooldown_ms()))
	var effective_cd_ms: int = max(min_reposition_interval_ms, dyn_cd_ms)
	var separation_dist: float = _get_min_separation_distance(agent, target)
	# Prevent giant stop distances (e.g. player=44) from triggering early micro-kite loops.
	# Demo-like cadence: evaluate disengage using real stop distance so actors don't wait
	# until body contact to reposition.
	var tactical_stop_dist: float = maxf(4.0, maxf(stop_dist, separation_dist + 4.0))

	if now_ms < _next_reposition_ms:
		# Do not block chase while out of tactical zone; keep cooldown only for in-range micro-reposition.
		if dist > (tactical_stop_dist + 1.5):
			BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "FAILURE", "cooldown_outside_tactical_zone")
			return FAILURE
		agent.stop_motor_movement()
		_emit_tactical_event("low_stamina_tactical_hold", {
			"actor": agent.name,
			"reason": "reposition_cooldown"
		}, "hold_reposition_cooldown")
		BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "RUNNING", "hold_reposition_cooldown")
		return RUNNING

	var should_reposition: bool = false
	var reason: String = "hold_regen"
	var destination: Vector2 = agent.global_position
	var away_dir: Vector2 = (agent.global_position - target.global_position).normalized()
	if away_dir.is_zero_approx():
		away_dir = Vector2.RIGHT.rotated(randf() * TAU)

	# Forced separation only when deeply overlapped.
	if dist < (separation_dist * 0.8):
		should_reposition = true
		reason = "force_separation"
		var forced_kite: float = maxf(dyn_dist, separation_dist * 1.2)
		destination = target.global_position + away_dir * maxf(separation_dist + 2.0, forced_kite)
	elif dist <= tactical_stop_dist:
		should_reposition = true
		reason = "in_range_reposition"
		var kite_dist: float = maxf(dyn_dist, separation_dist * 1.2)
		destination = target.global_position + away_dir * maxf(separation_dist + 6.0, kite_dist)

	if should_reposition:
		_committed_destination = destination
		_is_committed_move = true
		_next_reposition_ms = now_ms + effective_cd_ms
		agent.request_move_runtime(_committed_destination)
		agent.play_walk_toward(_committed_destination)
		_emit_tactical_event("low_stamina_tactical_reposition", {
			"actor": agent.name,
			"reason": reason,
			"distance": dist,
			"stop_distance": tactical_stop_dist,
			"separation_distance": separation_dist
		}, "reposition_%s" % reason)
		BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "RUNNING", "reposition_commit")
		return RUNNING

	# Outside close tactical zone, hold the tree in RUNNING to allow breathing room
	if dist > separation_dist * disengage_distance_factor:
		agent.stop_motor_movement()
		_hold_until_ms = now_ms + post_move_hold_ms
		BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "RUNNING", "outside_disengage_zone_hold")
		return RUNNING

	agent.stop_motor_movement()
	_next_reposition_ms = now_ms + effective_cd_ms
	_emit_tactical_event("low_stamina_tactical_hold", {
		"actor": agent.name,
		"reason": "hold_regen"
	}, "hold_regen")
	BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "RUNNING", "hold_regen")
	return RUNNING


func _exit() -> void:
	_is_committed_move = false
	_hold_until_ms = 0
	if agent != null:
		agent.stop_motor_movement()


func _emit_tactical_event(event_name: String, data: Dictionary, event_key: String) -> void:
	var now_ms: int = Time.get_ticks_msec()
	if _last_event_key == event_key and _last_event_ms >= 0 and now_ms - _last_event_ms < max(0, telemetry_dedupe_ms):
		return
	_last_event_key = event_key
	_last_event_ms = now_ms
	CombatTelemetry.emit_event(StringName(event_name), data)


func _get_min_separation_distance(self_actor: Node2D, target_actor: Node2D) -> float:
	var self_nav := self_actor.get_node_or_null(^"NavigationAgent2D") as NavigationAgent2D
	var target_nav := target_actor.get_node_or_null(^"NavigationAgent2D") as NavigationAgent2D
	var self_r: float = 10.0
	var target_r: float = 10.0
	if self_nav != null:
		self_r = maxf(2.0, self_nav.radius)
	if target_nav != null:
		target_r = maxf(2.0, target_nav.radius)
	return self_r + target_r + 4.0
