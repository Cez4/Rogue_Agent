class_name ActorNavigationRuntime
extends RefCounted

static func update_interaction_approach(actor: Actor8DirLimbo) -> void:
	if not actor.player_controlled:
		return
	var target: Node2D = actor._bridge_get_interaction_target()
	if target == null:
		return
	if not is_instance_valid(target):
		actor.clear_interaction_target()
		return
	var dist: float = actor.global_position.distance_to(target.global_position)
	if dist <= maxf(8.0, actor._bridge_get_interaction_target_range()):
		actor._bridge_stop_motor_movement()
		actor.clear_interaction_target()
		return
	if actor.motor != null:
		var approach_pos: Vector2 = actor.compute_approach_position(target, actor._bridge_get_interaction_target_range())
		actor.motor.request_move(approach_pos)
