@tool
extends BTCondition
const ActorTargetingRuntimeRef = preload("res://Scripts/actors/services/actor_targeting_runtime.gd")

@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET


func _generate_name() -> String:
	return "ValidateCombatTargetAlive %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	var target: Node2D = ActorTargetingRuntimeRef.validate_combat_target_alive(agent, blackboard, target_var)
	if not is_instance_valid(target):
		return FAILURE
	return SUCCESS
