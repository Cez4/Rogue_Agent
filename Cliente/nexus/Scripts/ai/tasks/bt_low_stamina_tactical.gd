@tool
extends BTAction

const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY
@export var reposition_probability: float = 0.45
@export var min_reposition_interval_ms: int = 240
@export var telemetry_dedupe_ms: int = 300

var _next_reposition_ms: int = 0
var _last_event_key: String = ""
var _last_event_ms: int = -1
var _low_stamina_active: bool = false


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
		BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "FAILURE", "has_stamina")
		return FAILURE

	_low_stamina_active = true

	var target: Node2D = null
	if blackboard.has_var(target_var):
		target = blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		agent.stop_motor_movement()
		_emit_tactical_event("low_stamina_tactical_hold", {
			"actor": agent.name,
			"reason": "no_target"
		}, "hold_no_target")
		BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "RUNNING", "low_stamina_hold_no_target")
		return RUNNING

	var dist: float = agent.global_position.distance_to(target.global_position)
	var stop_dist: float = maxf(4.0, float(agent.get_attack_stop_distance()))
	var now_ms: int = Time.get_ticks_msec()
	var dyn_prob: float = clampf(float(agent.get_low_stamina_kite_probability()), 0.0, 1.0)
	var dyn_dist: float = maxf(0.0, float(agent.get_low_stamina_kite_distance()))
	var dyn_cd_ms: int = max(0, int(agent.get_low_stamina_kite_cooldown_ms()))
	var effective_prob: float = clampf(maxf(reposition_probability, dyn_prob), 0.0, 1.0)
	var effective_cd_ms: int = max(min_reposition_interval_ms, dyn_cd_ms)
	var separation_dist: float = _get_min_separation_distance(agent, target)

	# If physically overlapped/too close, force a stronger disengage to prevent body glue.
	if dist < separation_dist:
		if now_ms >= _next_reposition_ms:
			var away_dir_sep: Vector2 = (agent.global_position - target.global_position).normalized()
			if away_dir_sep.is_zero_approx():
				away_dir_sep = Vector2.RIGHT.rotated(randf() * TAU)
			var forced_kite: float = maxf(dyn_dist, separation_dist * 1.35)
			var forced_pos: Vector2 = agent.global_position + away_dir_sep * forced_kite
			agent.request_move_runtime(forced_pos)
			agent.play_walk_toward(forced_pos)
			_next_reposition_ms = now_ms + effective_cd_ms
			_emit_tactical_event("low_stamina_tactical_reposition", {
				"actor": agent.name,
				"reason": "force_separation",
				"distance": dist,
				"separation_distance": separation_dist,
				"forced_kite_distance": forced_kite
			}, "reposition_force_separation")
			BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "RUNNING", "low_stamina_force_separation")
			return RUNNING

	# In range: probabilistic micro-kite for emergent "back off -> think -> re-engage".
	if dist <= stop_dist:
		if now_ms >= _next_reposition_ms and dyn_dist > 0.0 and randf() <= effective_prob:
			var away_dir: Vector2 = (agent.global_position - target.global_position).normalized()
			if away_dir.is_zero_approx():
				away_dir = Vector2.RIGHT.rotated(randf() * TAU)
			var kite_pos: Vector2 = agent.global_position + away_dir * dyn_dist
			agent.request_move_runtime(kite_pos)
			agent.play_walk_toward(kite_pos)
			_next_reposition_ms = now_ms + effective_cd_ms
			_emit_tactical_event("low_stamina_tactical_reposition", {
				"actor": agent.name,
				"reason": "in_range_micro_kite",
				"distance": dist,
				"stop_distance": stop_dist,
				"kite_distance": dyn_dist
			}, "reposition_in_range")
			BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "RUNNING", "low_stamina_reposition_in_range")
			return RUNNING
		agent.stop_motor_movement()
		_emit_tactical_event("low_stamina_tactical_hold", {
			"actor": agent.name,
			"reason": "in_range",
			"distance": dist,
			"stop_distance": stop_dist
		}, "hold_in_range")
		BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "RUNNING", "low_stamina_hold_in_range")
		return RUNNING

	# Out of range: either hold or reposition/chase lightly based on probability.
	if now_ms < _next_reposition_ms:
		agent.stop_motor_movement()
		_emit_tactical_event("low_stamina_tactical_hold", {
			"actor": agent.name,
			"reason": "reposition_cooldown"
		}, "hold_reposition_cooldown")
		BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "RUNNING", "low_stamina_hold_cooldown")
		return RUNNING

	if randf() <= effective_prob:
		agent.request_move_runtime(target.global_position)
		agent.play_walk_toward(target.global_position)
		_next_reposition_ms = now_ms + effective_cd_ms
		_emit_tactical_event("low_stamina_tactical_reposition", {
			"actor": agent.name,
			"distance": dist,
			"stop_distance": stop_dist,
			"roll_threshold": effective_prob
		}, "reposition_out_of_range")
		BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "RUNNING", "low_stamina_reposition")
		return RUNNING

	agent.stop_motor_movement()
	_next_reposition_ms = now_ms + effective_cd_ms
	_emit_tactical_event("low_stamina_tactical_hold", {
		"actor": agent.name,
		"reason": "hold_roll",
		"roll_threshold": effective_prob
	}, "hold_roll")
	BTDecisionTelemetryRef.emit("LowStaminaTactical", agent, blackboard, debug_decision_var, "RUNNING", "low_stamina_hold_roll")
	return RUNNING


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
