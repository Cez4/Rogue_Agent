class_name ActorCombatRuntime
extends RefCounted

static func set_combat_target(actor: Actor8DirLimbo, target: Node2D, manual_lock: bool = true) -> void:
	if target == null or not is_instance_valid(target):
		actor._bridge_reset_combat_target_runtime()
		_sync_blackboard_target(actor, null)
		return
	var current_target: Node2D = actor.get_combat_target()
	var changed_target: bool = current_target != target
	actor._bridge_set_combat_target_internal(target, manual_lock)
	_sync_blackboard_target(actor, target)
	actor.clear_interaction_target()
	actor.face_toward(target.global_position)
	if changed_target:
		CombatTelemetry.emit_event(&"target_acquired", {
			"actor": actor.name,
			"target": target.name,
			"manual_lock": manual_lock
		})


static func clear_combat_target(actor: Actor8DirLimbo) -> void:
	var current_target: Node2D = actor.get_combat_target()
	var had_target: bool = current_target != null and is_instance_valid(current_target)
	var old_target_name: String = ""
	if had_target:
		old_target_name = current_target.name
	actor._bridge_reset_combat_target_runtime()
	_sync_blackboard_target(actor, null)
	if had_target:
		CombatTelemetry.emit_event(&"target_lost", {
			"actor": actor.name,
			"target": old_target_name
		})


static func cancel_chase_attack(actor: Actor8DirLimbo, reason: StringName = &"unknown") -> void:
	var current_target: Node2D = actor.get_combat_target()
	var had_target: bool = current_target != null and is_instance_valid(current_target)
	var was_manual_lock: bool = bool(actor.is_combat_target_manual_lock())
	clear_combat_target(actor)
	actor.stop_motor_movement()
	if had_target:
		CombatTelemetry.emit_event(&"chase_canceled", {
			"actor": actor.name,
			"reason": String(reason),
			"manual_lock": was_manual_lock
		})


static func is_target_alive(target: Node2D) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	var health := target.get_node_or_null(^"Health") as HealthComponent
	if health != null:
		return bool(health.is_alive())
	return true


static func on_health_death(actor: Actor8DirLimbo) -> void:
	actor._bridge_set_actor_dead(true)
	actor.clear_attack_pending()
	disable_brain_runtime(actor)
	if actor.hsm != null:
		actor.hsm.set_active(false)
	actor.cancel_all_intents(&"death")
	actor._bridge_play_die_animation_runtime()
	disable_combat_collision(actor)
	CombatTelemetry.emit_event(&"target_died", {"actor": actor.name})
	if not actor.enable_respawn:
		return
	actor._bridge_request_respawn_after_death()


static func disable_combat_collision(actor: Actor8DirLimbo) -> void:
	var hurtbox := actor.get_node_or_null(^"Hurtbox") as Area2D
	if hurtbox != null:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	var body_collision := actor.get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if body_collision != null:
		body_collision.set_deferred("disabled", true)


static func enable_combat_collision(actor: Actor8DirLimbo) -> void:
	var hurtbox := actor.get_node_or_null(^"Hurtbox") as Area2D
	if hurtbox != null:
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
	var body_collision := actor.get_node_or_null(^"CollisionShape2D") as CollisionShape2D
	if body_collision != null:
		body_collision.set_deferred("disabled", false)


static func disable_brain_runtime(actor: Actor8DirLimbo) -> void:
	actor.set_brain_active(false)


static func enable_brain_runtime(actor: Actor8DirLimbo) -> void:
	actor.set_brain_active(true)


static func reset_combat_memory(actor: Actor8DirLimbo) -> void:
	clear_combat_target(actor)
	actor.clear_interaction_target()
	var bb: Blackboard = null
	var bt_player: Node = actor.get_bt_player()
	if bt_player != null:
		bb = bt_player.get("blackboard") as Blackboard
	if bb != null:
		bb.erase_var(AIBlackboardKeys.COMBAT_TARGET)
		bb.erase_var(AIBlackboardKeys.COMBAT_TARGET_LAST_SEEN_MS)
		bb.erase_var(AIBlackboardKeys.COMBAT_NEXT_REACQUIRE_MS)
		bb.erase_var(AIBlackboardKeys.ATTACK_TASK_STARTED)
		bb.erase_var(AIBlackboardKeys.LAST_ATTACK_BLOCKED_REASON)


static func _sync_blackboard_target(actor: Actor8DirLimbo, target: Node2D) -> void:
	var bt_player: Node = actor.get_bt_player()
	if bt_player == null:
		return
	var bb: Blackboard = bt_player.get("blackboard") as Blackboard
	if bb == null:
		return
	if target == null or not is_instance_valid(target):
		bb.erase_var(AIBlackboardKeys.COMBAT_TARGET)
		bb.erase_var(AIBlackboardKeys.COMBAT_TARGET_LAST_SEEN_MS)
		return
	bb.set_var(AIBlackboardKeys.COMBAT_TARGET, target)
	bb.set_var(AIBlackboardKeys.COMBAT_TARGET_LAST_SEEN_MS, Time.get_ticks_msec())
