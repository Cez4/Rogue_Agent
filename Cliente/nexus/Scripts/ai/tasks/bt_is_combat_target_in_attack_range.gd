@tool
extends BTCondition

@export var target_var: StringName = &"combat_target"


func _generate_name() -> String:
	return "IsCombatTargetInAttackRange %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	var target := blackboard.get_var(target_var, null) as Node2D
	if not is_instance_valid(target):
		return FAILURE
	if agent == null:
		return FAILURE
	var attack_range: float = 28.0
	if agent.has_method("get_attack_range"):
		attack_range = float(agent.get_attack_range())
	var dist_sq: float = agent.global_position.distance_squared_to(target.global_position)
	return SUCCESS if dist_sq <= attack_range * attack_range else FAILURE
