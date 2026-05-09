class_name ActorNavigationRuntime
extends RefCounted

static func update_interaction_approach(actor: Actor8DirLimbo) -> void:
	if not actor.player_controlled:
		return
	var target: Node2D = actor.get_interaction_target()
	if target == null:
		return
	if not is_instance_valid(target):
		actor.clear_interaction_target()
		return
	var dist: float = actor.global_position.distance_to(target.global_position)
	if dist <= maxf(8.0, actor.get_interaction_target_range()):
		actor.stop_motor_movement()
		actor.clear_interaction_target()
		return
	if actor.motor != null:
		actor.motor.request_move(target.global_position)


static func update_chase_attack(actor: Actor8DirLimbo) -> void:
	if not actor.player_controlled:
		return
	var target: Node2D = actor.get_combat_target()
	if target == null or not is_instance_valid(target):
		actor.reset_combat_target_runtime()
		return
	if target == actor:
		actor.clear_combat_target()
		return
	if not actor.is_target_alive_for_runtime(target):
		actor.cancel_chase_attack()
		return

	var dist: float = actor.global_position.distance_to(target.global_position)
	if dist <= actor.get_attack_range():
		actor.stop_motor_movement()
		actor.face_toward(target.global_position)
		actor.request_attack()
		return

	var now_sec: float = Time.get_ticks_msec() * 0.001
	if now_sec < actor.get_next_chase_repath_sec():
		if not actor.is_attack_pending_runtime():
			actor.play_walk_toward(target.global_position)
		return
	actor.set_next_chase_repath_sec(now_sec + maxf(0.05, actor.chase_repath_interval_sec))
	actor.request_move_runtime(target.global_position)
	if not actor.is_attack_pending_runtime():
		actor.play_walk_toward(target.global_position)
