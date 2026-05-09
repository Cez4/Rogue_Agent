@tool
extends BTAction
const ActorTargetingRuntimeRef = preload("res://Scripts/actors/services/actor_targeting_runtime.gd")

@export var group: StringName = &"player"
@export var output_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var last_seen_time_var: StringName = AIBlackboardKeys.COMBAT_TARGET_LAST_SEEN_MS
@export var default_acquire_radius: float = 120.0


func _generate_name() -> String:
	return "AcquireCombatTarget %s -> %s" % [group, LimboUtility.decorate_var(output_var)]


func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	var target: Node2D = ActorTargetingRuntimeRef.acquire_combat_target_in_group(
		agent,
		blackboard,
		group,
		output_var,
		last_seen_time_var,
		default_acquire_radius
	)
	if not is_instance_valid(target):
		return FAILURE
	return SUCCESS
