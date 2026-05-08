@tool
extends BTCondition

@export var target_var: StringName = &"combat_target"


func _generate_name() -> String:
	return "IsCombatTargetInAttackRange %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	if not blackboard.has_var(target_var):
		return FAILURE
	var target := blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		return FAILURE
	if agent == null:
		return FAILURE
	var attack_range: float = 28.0
	if agent.has_method("get_attack_stop_distance"):
		attack_range = float(agent.get_attack_stop_distance())
	elif agent.has_method("get_attack_range"):
		attack_range = float(agent.get_attack_range())
	var dist_sq: float = agent.global_position.distance_squared_to(target.global_position)
	return SUCCESS if dist_sq <= attack_range * attack_range else FAILURE
