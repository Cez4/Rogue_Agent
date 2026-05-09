@tool
extends BTAction
const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY

func _generate_name() -> String:
	return "IdleWanderLoop"

func _tick(delta: float) -> Status:
	if agent == null:
		BTDecisionTelemetryRef.emit("IdleWanderLoop", agent, blackboard, debug_decision_var, "FAILURE", "no_agent")
		return FAILURE

	if agent.is_actor_moving():
		agent.update_walk_animation()
		agent.try_play_wander_emote()
		BTDecisionTelemetryRef.emit("IdleWanderLoop", agent, blackboard, debug_decision_var, "RUNNING", "moving")
		return RUNNING

	agent.play_idle_animation()

	if agent.should_start_wander(delta):
		agent.begin_wander()
		BTDecisionTelemetryRef.emit("IdleWanderLoop", agent, blackboard, debug_decision_var, "RUNNING", "begin_wander")
		return RUNNING

	BTDecisionTelemetryRef.emit("IdleWanderLoop", agent, blackboard, debug_decision_var, "RUNNING", "idling")
	return RUNNING
