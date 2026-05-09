@tool
extends BTCondition
const ActorTargetingRuntimeRef = preload("res://Scripts/actors/services/actor_targeting_runtime.gd")
const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY


func _generate_name() -> String:
	return "ValidateCombatTargetAlive %s" % LimboUtility.decorate_var(target_var)


func _tick(_delta: float) -> Status:
	if agent == null:
		BTDecisionTelemetryRef.emit("ValidateCombatTargetAlive", agent, blackboard, debug_decision_var, "FAILURE", "no_agent")
		return FAILURE
	var target: Node2D = ActorTargetingRuntimeRef.validate_combat_target_alive(agent, blackboard, target_var)
	if not is_instance_valid(target):
		BTDecisionTelemetryRef.emit("ValidateCombatTargetAlive", agent, blackboard, debug_decision_var, "FAILURE", "dead_or_invalid")
		return FAILURE
	BTDecisionTelemetryRef.emit("ValidateCombatTargetAlive", agent, blackboard, debug_decision_var, "SUCCESS", "alive")
	return SUCCESS
