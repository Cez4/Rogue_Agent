@tool
extends BTAction

@export var started_var: StringName = &"attack_task_started"


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
	agent.request_attack()
	attack_pending = false
	if agent.has_method("get"):
		attack_pending = bool(agent.get("_attack_pending"))
	if attack_pending:
		blackboard.set_var(started_var, true)
		return RUNNING
	blackboard.set_var(started_var, false)
	return FAILURE
