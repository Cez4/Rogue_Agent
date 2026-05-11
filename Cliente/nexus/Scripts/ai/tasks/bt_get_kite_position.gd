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

	# Fuga massiva garantida de 160 pixels a partir do ator para um respiro tático real
	var destination: Vector2 = agent.global_position + away_dir * 160.0
	
	# Clamp to valid NavMesh to prevent wall-stucking
	var nav_agent := agent.get_node_or_null(^"NavigationAgent2D") as NavigationAgent2D
	if nav_agent != null:
		var nav_map: RID = nav_agent.get_navigation_map()
		if nav_map.is_valid():
			destination = NavigationServer2D.map_get_closest_point(nav_map, destination)
	
	blackboard.set_var(output_pos_var, destination)
	BTDecisionTelemetryRef.emit("GetKitePosition", agent, blackboard, debug_decision_var, "SUCCESS", "calculated_kite_pos")
	return SUCCESS