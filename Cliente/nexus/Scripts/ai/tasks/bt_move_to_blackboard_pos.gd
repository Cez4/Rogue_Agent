@tool
extends BTAction

const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var target_pos_var: StringName = &"tactical_position"
@export var arrive_tolerance: float = 12.0
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY

func _generate_name() -> String:
	return "Move to BB Position"

func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	if _is_agent_hit_reacting():
		BTDecisionTelemetryRef.emit("MoveToBBPosition", agent, blackboard, debug_decision_var, "RUNNING", "hit_reaction")
		return RUNNING
	if bool(agent.is_attack_pending_runtime()):
		BTDecisionTelemetryRef.emit("MoveToBBPosition", agent, blackboard, debug_decision_var, "RUNNING", "waiting_attack_to_finish")
		return RUNNING
		
	if not blackboard.has_var(target_pos_var):
		BTDecisionTelemetryRef.emit("MoveToBBPosition", agent, blackboard, debug_decision_var, "FAILURE", "missing_pos_var")
		return FAILURE
		
	var target_pos: Vector2 = blackboard.get_var(target_pos_var) as Vector2
	var dist: float = agent.global_position.distance_to(target_pos)
	
	if dist <= arrive_tolerance:
		agent.stop_motor_movement()
		BTDecisionTelemetryRef.emit("MoveToBBPosition", agent, blackboard, debug_decision_var, "SUCCESS", "arrived")
		return SUCCESS
		
	agent.request_move_runtime(target_pos)
	agent.play_walk_toward(target_pos)
	BTDecisionTelemetryRef.emit("MoveToBBPosition", agent, blackboard, debug_decision_var, "RUNNING", "moving")
	return RUNNING

func _exit() -> void:
	if agent != null:
		agent.stop_motor_movement()


func _is_agent_hit_reacting() -> bool:
	if agent == null:
		return false
	var hit_reaction := agent.get_node_or_null(^"HitReactionComponent")
	return hit_reaction != null and hit_reaction.has_method("is_reacting") and bool(hit_reaction.call("is_reacting"))
