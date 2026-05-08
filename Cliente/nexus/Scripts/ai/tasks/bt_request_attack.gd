@tool
extends BTAction

@export var started_var: StringName = &"attack_task_started"
@export var target_var: StringName = &"combat_target"


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
		blackboard.set_var(started_var, true)
		return RUNNING

	# If we already started an attack and now pending is false, the attack finished.
	var started: bool = false
	if blackboard.has_var(started_var):
		started = bool(blackboard.get_var(started_var))
	if started:
		blackboard.set_var(started_var, false)
		return SUCCESS

	# Start a new attack and immediately switch to RUNNING if pending got set.
	var target := blackboard.get_var(target_var, null) as Node2D
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
		blackboard.set_var(started_var, true)
		return RUNNING
	CombatTelemetry.emit_event(&"attack_blocked_reason", {
		"actor": agent.name,
		"reason": "request_attack_not_started"
	})
	blackboard.set_var(started_var, false)
	return FAILURE
