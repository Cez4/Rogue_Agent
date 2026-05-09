@tool
extends BTAction
const ActorTargetingRuntimeRef = preload("res://Scripts/actors/services/actor_targeting_runtime.gd")
const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var group: StringName = &"player"
@export var output_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var last_seen_time_var: StringName = AIBlackboardKeys.COMBAT_TARGET_LAST_SEEN_MS
@export var default_acquire_radius: float = 120.0
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY


func _generate_name() -> String:
	return "AcquireCombatTarget %s -> %s" % [group, LimboUtility.decorate_var(output_var)]


func _tick(_delta: float) -> Status:
	if agent == null:
		BTDecisionTelemetryRef.emit("AcquireCombatTargetInGroup", agent, blackboard, debug_decision_var, "FAILURE", "no_agent")
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
		BTDecisionTelemetryRef.emit("AcquireCombatTargetInGroup", agent, blackboard, debug_decision_var, "FAILURE", "no_target")
		return FAILURE
	BTDecisionTelemetryRef.emit("AcquireCombatTargetInGroup", agent, blackboard, debug_decision_var, "SUCCESS", "acquired")
	return SUCCESS
