class_name ActorCombatRuntime
extends RefCounted

static func set_combat_target(actor: Node, target: Node2D, manual_lock: bool = true) -> void:
	if target == null or not is_instance_valid(target):
		actor.reset_combat_target_runtime()
		return
	var current_target: Node2D = actor.get_combat_target()
	var changed_target: bool = current_target != target
	actor.set_combat_target_internal(target, manual_lock)
	actor.clear_interaction_target()
	actor.face_toward(target.global_position)
	if changed_target:
		CombatTelemetry.emit_event(&"target_acquired", {
			"actor": actor.name,
			"target": target.name,
			"manual_lock": manual_lock
		})


static func clear_combat_target(actor: Node) -> void:
	var current_target: Node2D = actor.get_combat_target()
	var had_target: bool = current_target != null and is_instance_valid(current_target)
	var old_target_name: String = ""
	if had_target:
		old_target_name = current_target.name
	actor.reset_combat_target_runtime()
	if had_target:
		CombatTelemetry.emit_event(&"target_lost", {
			"actor": actor.name,
			"target": old_target_name
		})


static func cancel_chase_attack(actor: Node) -> void:
	var current_target: Node2D = actor.get_combat_target()
	var had_target: bool = current_target != null and is_instance_valid(current_target)
	clear_combat_target(actor)
	actor.stop_motor_movement()
	if had_target:
		CombatTelemetry.emit_event(&"chase_canceled", {"actor": actor.name})


static func is_target_alive(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var health := target.get_node_or_null(^"Health")
	if health != null and health.has_method("is_alive"):
		return bool(health.call("is_alive"))
	return true


static func on_health_death(actor: Node) -> void:
	actor.set_actor_dead(true)
	actor.clear_attack_pending()
	disable_brain_runtime(actor)
	if actor.hsm != null:
		actor.hsm.set_active(false)
	actor.cancel_all_intents()
	actor._play_die_animation()
	disable_combat_collision(actor)
	CombatTelemetry.emit_event(&"target_died", {"actor": actor.name})
	if not actor.enable_respawn:
		return
	if not actor.player_controlled:
		actor._respawn_after_delay()


static func disable_combat_collision(actor: Node) -> void:
	var hurtbox := actor.get_node_or_null(^"Hurtbox") as Area2D
	if hurtbox != null:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	var body_collision := actor.get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if body_collision != null:
		body_collision.set_deferred("disabled", true)


static func enable_combat_collision(actor: Node) -> void:
	var hurtbox := actor.get_node_or_null(^"Hurtbox") as Area2D
	if hurtbox != null:
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
	var body_collision := actor.get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if body_collision != null:
		body_collision.set_deferred("disabled", false)


static func disable_brain_runtime(actor: Node) -> void:
	actor.set_brain_active(false)


static func enable_brain_runtime(actor: Node) -> void:
	actor.set_brain_active(true)


static func reset_combat_memory(actor: Node) -> void:
	clear_combat_target(actor)
	actor.clear_interaction_target()
	var bb: Variant = null
	var bt_player: Node = actor.get_bt_player()
	if bt_player != null and bt_player.has_method("get"):
		bb = bt_player.get("blackboard")
	if bb != null and bb.has_method("erase_var"):
		bb.erase_var(&"combat_target")
		bb.erase_var(&"combat_target_last_seen_ms")
		bb.erase_var(&"combat_next_reacquire_ms")
		bb.erase_var(&"attack_task_started")
		bb.erase_var(&"last_attack_blocked_reason")
