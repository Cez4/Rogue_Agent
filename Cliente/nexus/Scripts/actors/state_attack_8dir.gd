extends LimboState

@export var action_data: Resource
@export var hitbox_path: NodePath = ^"AttackHitbox"

var _cooldown_until_sec: float = 0.0


func _enter() -> void:
	if agent == null:
		_finish_attack()
		return

	var now_sec: float = Time.get_ticks_msec() * 0.001
	if now_sec < _cooldown_until_sec:
		_finish_attack()
		return

	var stamina := agent.get_node_or_null(^"Stamina") as StaminaComponent
	if stamina != null:
		var resolved_action: Resource = _resolved_action_data()
		if resolved_action != null and resolved_action.get("stamina_cost") != null:
			var cost: float = float(resolved_action.get("stamina_cost"))
			if cost > 0.0:
				var required: float = float(agent.get_required_stamina_for_attack())
				if required <= 0.0:
					required = cost
				if not stamina.has_stamina(required):
					_finish_attack()
					return
				if not stamina.consume(cost):
					_finish_attack()
					return

	var telemetry_target: String = ""
	var has_valid_telemetry_target: bool = false
	var current_target: Node2D = agent.get_combat_target() as Node2D
	if is_instance_valid(current_target):
		telemetry_target = str(current_target.name)
		has_valid_telemetry_target = true
	if has_valid_telemetry_target:
		CombatTelemetry.emit_event(&"attack_started", {
			"actor": str(agent.name),
			"target": telemetry_target
		})

	# Lock animation/state to attack execution; avoid walk visual while hit windows run.
	agent.stop_motor_movement()
	agent.play_attack_animation()
	agent.orient_attack_hitbox()

	var hitbox := agent.get_node_or_null(hitbox_path) as HitboxComponent
	if hitbox != null:
		_apply_action_to_hitbox(hitbox)
		hitbox.set_hitbox_enabled(false)

	await get_tree().create_timer(_windup()).timeout
	if not is_active(): return
	if hitbox != null:
		hitbox.set_hitbox_enabled(true)

	await get_tree().create_timer(_active()).timeout
	if not is_active(): return
	if hitbox != null:
		hitbox.set_hitbox_enabled(false)

	await get_tree().create_timer(_recover()).timeout
	if not is_active(): return
	await agent.wait_for_attack_animation_end(_windup() + _active() + _recover())
	if not is_active(): return
	_cooldown_until_sec = Time.get_ticks_msec() * 0.001 + _cooldown()
	_finish_attack()


func _exit() -> void:
	# Hardening: if this state is interrupted mid-coroutine, ensure combat does not stay locked.
	if agent != null:
		var hitbox := agent.get_node_or_null(hitbox_path) as HitboxComponent
		if hitbox != null:
			hitbox.set_hitbox_enabled(false)
		agent.clear_attack_pending()


func _apply_action_to_hitbox(hitbox: Node) -> void:
	var resolved_action: Resource = _resolved_action_data()
	if resolved_action == null:
		return
	hitbox.damage = resolved_action.get("damage")
	
	var action: CombatActionData = resolved_action as CombatActionData
	if action != null:
		if "knockback_force" in hitbox:
			hitbox.knockback_force = action.knockback_force
		if "knockback_duration_sec" in hitbox:
			hitbox.knockback_duration_sec = action.knockback_duration_sec
			
	hitbox.one_hit_per_target_per_attack = resolved_action.get("one_hit_per_target_per_attack")
	hitbox.max_targets_per_attack = resolved_action.get("max_targets_per_attack")


func _windup() -> float:
	var resolved_action: Resource = _resolved_action_data()
	return 0.12 if resolved_action == null else maxf(0.01, float(resolved_action.get("windup_sec")))


func _active() -> float:
	var resolved_action: Resource = _resolved_action_data()
	return 0.08 if resolved_action == null else maxf(0.01, float(resolved_action.get("active_sec")))


func _recover() -> float:
	var resolved_action: Resource = _resolved_action_data()
	return 0.16 if resolved_action == null else maxf(0.01, float(resolved_action.get("recover_sec")))


func _cooldown() -> float:
	var resolved_action: Resource = _resolved_action_data()
	return 0.24 if resolved_action == null else maxf(0.0, float(resolved_action.get("cooldown_sec")))


func _finish_attack() -> void:
	if agent != null:
		agent.clear_attack_pending()
	get_root().dispatch(EVENT_FINISHED)


func _resolved_action_data() -> Resource:
	if agent != null:
		var loadout: EquipmentLoadout = agent.get_equipment_loadout_runtime() as EquipmentLoadout
		if loadout != null and loadout.weapon != null and loadout.weapon.action_data != null:
			return loadout.weapon.action_data
	return action_data
