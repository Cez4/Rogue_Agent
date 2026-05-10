@tool
extends BTAction
const CombatBlockedReasonsRef = preload("res://Scripts/combat/combat_blocked_reasons.gd")
const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var started_var: StringName = AIBlackboardKeys.ATTACK_TASK_STARTED
@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var blocked_reason_var: StringName = AIBlackboardKeys.LAST_ATTACK_BLOCKED_REASON
@export var blocked_latched_var: StringName = AIBlackboardKeys.ATTACK_BLOCKED_LATCHED
@export var blocked_active_var: StringName = AIBlackboardKeys.ATTACK_BLOCKED_ACTIVE
@export var blocked_pending_since_ms_var: StringName = AIBlackboardKeys.ATTACK_BLOCKED_PENDING_SINCE_MS
@export var low_stamina_active_var: StringName = AIBlackboardKeys.LOW_STAMINA_ACTIVE
@export var blocked_started_min_duration_sec: float = 0.25
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY


func _generate_name() -> String:
	return "RequestAttack"


func _tick(_delta: float) -> Status:
	if agent == null:
		BTDecisionTelemetryRef.emit("RequestAttack", agent, blackboard, debug_decision_var, "FAILURE", "no_agent")
		return FAILURE

	var attack_pending: bool = false
	attack_pending = bool(agent.is_attack_pending_runtime())

	# If an attack is currently executing, keep this task RUNNING until it completes.
	if attack_pending:
		_emit_low_stamina_exited_if_needed()
		_emit_blocked_ended_if_needed(CombatBlockedReasonsRef.NONE)
		blackboard.set_var(blocked_reason_var, CombatBlockedReasonsRef.NONE)
		blackboard.set_var(blocked_latched_var, false)
		blackboard.set_var(started_var, true)
		BTDecisionTelemetryRef.emit("RequestAttack", agent, blackboard, debug_decision_var, "RUNNING", "attack_pending")
		return RUNNING

	# If we already started an attack and now pending is false, the attack finished.
	var started: bool = false
	if blackboard.has_var(started_var):
		started = bool(blackboard.get_var(started_var))
	if started:
		_emit_low_stamina_exited_if_needed()
		_emit_blocked_ended_if_needed(CombatBlockedReasonsRef.NONE)
		blackboard.set_var(blocked_reason_var, CombatBlockedReasonsRef.NONE)
		blackboard.set_var(blocked_latched_var, false)
		blackboard.set_var(started_var, false)
		BTDecisionTelemetryRef.emit("RequestAttack", agent, blackboard, debug_decision_var, "SUCCESS", "attack_finished")
		return SUCCESS

	# Start a new attack and immediately switch to RUNNING if pending got set.
	var target: Node2D = null
	if blackboard.has_var(target_var):
		target = blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		CombatTelemetry.emit_event(&"attack_task_blocked", {
			"actor": agent.name,
			"reason": CombatBlockedReasonsRef.NO_VALID_TARGET
		})
		_emit_low_stamina_exited_if_needed()
		_emit_blocked_ended_if_needed(CombatBlockedReasonsRef.NO_VALID_TARGET)
		blackboard.set_var(started_var, false)
		blackboard.set_var(blocked_reason_var, CombatBlockedReasonsRef.NO_VALID_TARGET)
		BTDecisionTelemetryRef.emit("RequestAttack", agent, blackboard, debug_decision_var, "FAILURE", "no_valid_target")
		return FAILURE
	if is_instance_valid(target):
		agent.face_toward(target.global_position)
	agent.stop_motor_movement()
	if not bool(agent.has_stamina_for_attack()):
		CombatTelemetry.emit_event(&"attack_task_blocked", {
			"actor": agent.name,
			"reason": CombatBlockedReasonsRef.INSUFFICIENT_STAMINA
		})
		_emit_low_stamina_entered_if_needed()
		blackboard.set_var(blocked_reason_var, CombatBlockedReasonsRef.INSUFFICIENT_STAMINA)
		blackboard.set_var(started_var, false)
		_emit_blocked_started_if_needed(CombatBlockedReasonsRef.INSUFFICIENT_STAMINA)
		BTDecisionTelemetryRef.emit("RequestAttack", agent, blackboard, debug_decision_var, "FAILURE", CombatBlockedReasonsRef.INSUFFICIENT_STAMINA)
		return FAILURE
	_emit_low_stamina_exited_if_needed()
	agent.request_attack()
	attack_pending = false
	attack_pending = bool(agent.is_attack_pending_runtime())
	if attack_pending:
		var target_name: String = ""
		if is_instance_valid(target):
			target_name = target.name
		CombatTelemetry.emit_event(&"attack_commit", {
			"actor": agent.name,
			"target": target_name
		})
		_emit_blocked_ended_if_needed(CombatBlockedReasonsRef.NONE)
		blackboard.set_var(blocked_reason_var, CombatBlockedReasonsRef.NONE)
		blackboard.set_var(blocked_latched_var, false)
		blackboard.set_var(started_var, true)
		BTDecisionTelemetryRef.emit("RequestAttack", agent, blackboard, debug_decision_var, "RUNNING", "attack_started")
		return RUNNING
	var blocked_latched: bool = false
	if blackboard.has_var(blocked_latched_var):
		blocked_latched = bool(blackboard.get_var(blocked_latched_var))
	blackboard.set_var(blocked_reason_var, CombatBlockedReasonsRef.REQUEST_ATTACK_NOT_STARTED)
	if not blocked_latched:
		CombatTelemetry.emit_event(&"attack_task_blocked", {
			"actor": agent.name,
			"reason": CombatBlockedReasonsRef.REQUEST_ATTACK_NOT_STARTED
		})
		_emit_blocked_started_if_needed(CombatBlockedReasonsRef.REQUEST_ATTACK_NOT_STARTED)
		blackboard.set_var(blocked_latched_var, true)
	blackboard.set_var(started_var, false)
	BTDecisionTelemetryRef.emit("RequestAttack", agent, blackboard, debug_decision_var, "FAILURE", CombatBlockedReasonsRef.REQUEST_ATTACK_NOT_STARTED)
	return FAILURE


func _emit_low_stamina_entered_if_needed() -> void:
	var active: bool = false
	if blackboard.has_var(low_stamina_active_var):
		active = bool(blackboard.get_var(low_stamina_active_var))
	if active:
		return
	CombatTelemetry.emit_event(&"low_stamina_entered", {
		"actor": agent.name
	})
	blackboard.set_var(low_stamina_active_var, true)


func _emit_low_stamina_exited_if_needed() -> void:
	var active: bool = false
	if blackboard.has_var(low_stamina_active_var):
		active = bool(blackboard.get_var(low_stamina_active_var))
	if not active:
		return
	CombatTelemetry.emit_event(&"low_stamina_exited", {
		"actor": agent.name
	})
	blackboard.set_var(low_stamina_active_var, false)


func _emit_blocked_started_if_needed(reason: String) -> void:
	var active: bool = false
	if blackboard.has_var(blocked_active_var):
		active = bool(blackboard.get_var(blocked_active_var))
	if active:
		return
	var now_ms: int = Time.get_ticks_msec()
	var pending_since_ms: int = -1
	if blackboard.has_var(blocked_pending_since_ms_var):
		pending_since_ms = int(blackboard.get_var(blocked_pending_since_ms_var))
	if pending_since_ms < 0:
		blackboard.set_var(blocked_pending_since_ms_var, now_ms)
		return
	var min_duration_ms: int = int(maxf(0.0, blocked_started_min_duration_sec) * 1000.0)
	if now_ms - pending_since_ms < min_duration_ms:
		return
	CombatTelemetry.emit_event(&"attack_blocked_started", {
		"actor": agent.name,
		"reason": reason
	})
	blackboard.set_var(blocked_active_var, true)
	blackboard.set_var(blocked_pending_since_ms_var, -1)


func _emit_blocked_ended_if_needed(next_reason: String) -> void:
	var active: bool = false
	if blackboard.has_var(blocked_active_var):
		active = bool(blackboard.get_var(blocked_active_var))
	if not active:
		blackboard.set_var(blocked_pending_since_ms_var, -1)
		return
	CombatTelemetry.emit_event(&"attack_blocked_ended", {
		"actor": agent.name,
		"next_reason": next_reason
	})
	blackboard.set_var(blocked_active_var, false)
	blackboard.set_var(blocked_pending_since_ms_var, -1)
