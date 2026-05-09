@tool
extends BTAction
const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var target_var: StringName = &"target_player"
@export var hold_sec_var: StringName = &"look_hold_sec"
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY

var _elapsed: float = 0.0

func _generate_name() -> String:
	return "LookAtTarget %s" % LimboUtility.decorate_var(target_var)

func _enter() -> void:
	_elapsed = 0.0
	if agent == null:
		return
	agent.stop_movement_for_look()
	agent.play_look_emote()

func _tick(delta: float) -> Status:
	var target := blackboard.get_var(target_var, null) as Node2D
	if not is_instance_valid(target):
		BTDecisionTelemetryRef.emit("LookAtTarget", agent, blackboard, debug_decision_var, "FAILURE", "invalid_target")
		return FAILURE

	if agent == null:
		BTDecisionTelemetryRef.emit("LookAtTarget", agent, blackboard, debug_decision_var, "FAILURE", "no_agent")
		return FAILURE
	agent.look_toward(target.global_position)

	_elapsed += delta
	var hold_sec: float = float(agent.look_hold_sec)
	if _elapsed >= hold_sec:
		agent.trigger_look_cooldown()
		BTDecisionTelemetryRef.emit("LookAtTarget", agent, blackboard, debug_decision_var, "SUCCESS", "hold_complete")
		return SUCCESS
	BTDecisionTelemetryRef.emit("LookAtTarget", agent, blackboard, debug_decision_var, "RUNNING", "holding")
	return RUNNING
