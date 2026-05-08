@tool
extends BTCondition

@export var target_var: StringName = &"combat_target"
@export var default_attack_stop_distance: float = 28.0
@export var blocked_reason_var: StringName = &"last_attack_blocked_reason"


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
	blackboard.set_var(blocked_reason_var, "out_of_range")
	CombatTelemetry.emit_event(&"attack_blocked_reason", {
		"actor": agent.name,
		"target": target.name,
		"reason": "out_of_range",
		"attack_stop_distance": attack_range
	})
	return FAILURE
