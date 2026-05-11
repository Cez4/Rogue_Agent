@tool
extends BTAction

const BTDecisionTelemetryRef = preload("res://Scripts/ai/bt_decision_telemetry.gd")

@export var target_var: StringName = AIBlackboardKeys.COMBAT_TARGET
@export var output_pos_var: StringName = &"tactical_position"
@export var debug_decision_var: StringName = AIBlackboardKeys.DEBUG_BT_DECISION_TELEMETRY

func _generate_name() -> String:
	return "Get Kite Position"

func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	var target: Node2D = null
	if blackboard.has_var(target_var):
		target = blackboard.get_var(target_var) as Node2D
	if not is_instance_valid(target):
		BTDecisionTelemetryRef.emit("GetKitePosition", agent, blackboard, debug_decision_var, "FAILURE", "no_target")
		return FAILURE

	var away_dir: Vector2 = (agent.global_position - target.global_position).normalized()
	if away_dir.is_zero_approx():
		away_dir = Vector2.RIGHT.rotated(randf() * TAU)

	var kite_distance: float = maxf(0.0, agent.get_low_stamina_kite_distance())
	var destination: Vector2 = agent.global_position + away_dir * kite_distance
	
	blackboard.set_var(output_pos_var, destination)
	BTDecisionTelemetryRef.emit("GetKitePosition", agent, blackboard, debug_decision_var, "SUCCESS", "calculated_kite_pos")
	return SUCCESS
