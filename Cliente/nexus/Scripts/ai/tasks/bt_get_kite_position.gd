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

	var nav_agent := agent.get_node_or_null(^"NavigationAgent2D") as NavigationAgent2D
	var destination: Vector2 = agent.global_position + away_dir * 160.0
	var final_destination: Vector2 = destination
	var found_good_spot: bool = false
	
	if nav_agent != null:
		var nav_map: RID = nav_agent.get_navigation_map()
		if nav_map.is_valid():
			# Try angles: Straight back, then left 45, right 45, left 90, right 90
			var angles = [0.0, PI/4.0, -PI/4.0, PI/2.0, -PI/2.0]
			for angle in angles:
				var test_dir = away_dir.rotated(angle)
				var test_dest = agent.global_position + test_dir * 160.0
				var clamped_dest = NavigationServer2D.map_get_closest_point(nav_map, test_dest)
				
				# If the clamped point is at least 40 pixels away, it's a good escape route!
				if agent.global_position.distance_to(clamped_dest) >= 40.0:
					final_destination = clamped_dest
					found_good_spot = true
					break
					
			if not found_good_spot:
				# If completely cornered in all directions, just use the best we can
				final_destination = NavigationServer2D.map_get_closest_point(nav_map, destination)

	blackboard.set_var(output_pos_var, final_destination)
	BTDecisionTelemetryRef.emit("GetKitePosition", agent, blackboard, debug_decision_var, "SUCCESS", "calculated_kite_pos")
	return SUCCESS