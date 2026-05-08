@tool
extends BTAction

@export var started_var: StringName = &"attack_task_started"
@export var target_var: StringName = &"combat_target"
@export var blocked_reason_var: StringName = &"last_attack_blocked_reason"
@export var blocked_latched_var: StringName = &"attack_blocked_latched"
@export var blocked_active_var: StringName = &"attack_blocked_active"


func _generate_name() -> String:
	return "RequestAttack"


func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	if not agent.has_method("request_attack"):
		return FAILURE

	var attack_pending: bool = false
	if agent.has_method("get"):
		attack_pending = bool(agent.get("_attack_pending"))

	# If an attack is currently executing, keep this task RUNNING until it completes.
	if attack_pending:
		_emit_blocked_ended_if_needed("")
		blackboard.set_var(blocked_reason_var, "")
		blackboard.set_var(blocked_latched_var, false)
		blackboard.set_var(started_var, true)
		return RUNNING

	# If we already started an attack and now pending is false, the attack finished.
	var started: bool = false
	if blackboard.has_var(started_var):
		started = bool(blackboard.get_var(started_var))
	if started:
		_emit_blocked_ended_if_needed("")
		blackboard.set_var(blocked_reason_var, "")
		blackboard.set_var(blocked_latched_var, false)
		blackboard.set_var(started_var, false)
		return SUCCESS

	# Start a new attack and immediately switch to RUNNING if pending got set.
	var target: Node2D = null
	if blackboard.has_var(target_var):
		target = blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		_emit_blocked_ended_if_needed("no_valid_target")
		blackboard.set_var(started_var, false)
		blackboard.set_var(blocked_reason_var, "no_valid_target")
		return FAILURE
	if is_instance_valid(target) and agent.has_method("face_toward"):
		agent.face_toward(target.global_position)
	if agent.has_method("get"):
		var motor_node: Variant = agent.get("motor")
		if motor_node != null and motor_node.has_method("stop"):
			motor_node.stop()
	agent.request_attack()
	attack_pending = false
	if agent.has_method("get"):
		attack_pending = bool(agent.get("_attack_pending"))
	if attack_pending:
		var target_name: String = ""
		if is_instance_valid(target):
			target_name = target.name
		CombatTelemetry.emit_event(&"attack_commit", {
			"actor": agent.name,
			"target": target_name
		})
		_emit_blocked_ended_if_needed("")
		blackboard.set_var(blocked_reason_var, "")
		blackboard.set_var(blocked_latched_var, false)
		blackboard.set_var(started_var, true)
		return RUNNING
	var blocked_latched: bool = false
	if blackboard.has_var(blocked_latched_var):
		blocked_latched = bool(blackboard.get_var(blocked_latched_var))
	blackboard.set_var(blocked_reason_var, "request_attack_not_started")
	if not blocked_latched:
		_emit_blocked_started_if_needed("request_attack_not_started")
		blackboard.set_var(blocked_latched_var, true)
	blackboard.set_var(started_var, false)
	return FAILURE


func _emit_blocked_started_if_needed(reason: String) -> void:
	var active: bool = false
	if blackboard.has_var(blocked_active_var):
		active = bool(blackboard.get_var(blocked_active_var))
	if active:
		return
	CombatTelemetry.emit_event(&"attack_blocked_started", {
		"actor": agent.name,
		"reason": reason
	})
	blackboard.set_var(blocked_active_var, true)


func _emit_blocked_ended_if_needed(next_reason: String) -> void:
	var active: bool = false
	if blackboard.has_var(blocked_active_var):
		active = bool(blackboard.get_var(blocked_active_var))
	if not active:
		return
	CombatTelemetry.emit_event(&"attack_blocked_ended", {
		"actor": agent.name,
		"next_reason": next_reason
	})
	blackboard.set_var(blocked_active_var, false)
