@tool
extends BTCondition
const ActorTargetingRuntimeRef = preload("res://Scripts/actors/services/actor_targeting_runtime.gd")

@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var last_seen_time_var: StringName = AIBlackboardKeys.COMBAT_TARGET_LAST_SEEN_MS
@export var default_acquire_radius: float = 120.0
@export var default_lose_radius: float = 156.0
@export var default_memory_sec: float = 1.2


func _generate_name() -> String:
	return "ValidateCombatTargetPerception %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	var valid: bool = ActorTargetingRuntimeRef.validate_combat_target_perception(
		agent,
		blackboard,
		target_var,
		last_seen_time_var,
		default_acquire_radius,
		default_lose_radius,
		default_memory_sec
	)
	if valid:
		return SUCCESS
	return FAILURE
