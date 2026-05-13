extends LimboState

@export var action_data: Resource
@export var hitbox_path: NodePath = ^"AttackHitbox"

const CLASH_CANCEL_ATTACK_SEQUENCE_META := &"combat_clash_cancel_attack_sequence_id"
const CLASH_CANCEL_REASON_META := &"combat_clash_cancel_reason"
const CLASH_RECOVERY_SEC_META := &"combat_clash_recovery_sec"

var _cooldown_until_sec: float = 0.0
var _attack_sequence_counter: int = 0
var _attack_sequence_id: int = 0
var _attack_phase: StringName = &"idle"
var _attack_started_runtime: bool = false
var _finished_normally: bool = false


func _enter() -> void:
	_reset_attack_telemetry()
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
				CombatTelemetry.emit_event(&"attack_stamina_cost", {
					"actor": str(agent.name),
					"attack_sequence_id": _attack_sequence_id,
					"amount": cost,
					"required": required
				})

	var telemetry_target: String = ""
	var has_valid_telemetry_target: bool = false
	var current_target: Node2D = agent.get_combat_target() as Node2D
	if is_instance_valid(current_target):
		telemetry_target = str(current_target.name)
		has_valid_telemetry_target = true
	if has_valid_telemetry_target:
		CombatTelemetry.emit_event(&"attack_started", {
			"actor": str(agent.name),
			"attack_sequence_id": _attack_sequence_id,
			"target": telemetry_target
		})
		_notify_clash_attack_started(telemetry_target)
	_attack_started_runtime = true
	_emit_attack_phase(&"windup", telemetry_target)

	# Lock animation/state to attack execution; avoid walk visual while hit windows run.
	agent.stop_motor_movement()
	agent.play_attack_animation()
	agent.orient_attack_hitbox()

	var hitbox := agent.get_node_or_null(hitbox_path) as HitboxComponent
	if hitbox != null:
		_apply_action_to_hitbox(hitbox)
		hitbox.attack_sequence_id = _attack_sequence_id
		hitbox.set_hitbox_enabled(false, &"prepare")

	await get_tree().create_timer(_windup()).timeout
	if not is_active(): return
	if _should_cancel_attack_for_clash():
		_cancel_attack_for_clash()
		return
	_emit_attack_phase(&"active", telemetry_target)
	if hitbox != null:
		hitbox.attack_sequence_id = _attack_sequence_id
		hitbox.set_hitbox_enabled(true)

	await get_tree().create_timer(_active()).timeout
	if not is_active(): return
	if _should_cancel_attack_for_clash():
		_cancel_attack_for_clash()
		return
	if hitbox != null:
		hitbox.set_hitbox_enabled(false, &"active_elapsed")
	_emit_attack_phase(&"recover", telemetry_target)

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
			hitbox.set_hitbox_enabled(false, &"interrupted")
		if _attack_started_runtime and not _finished_normally:
			var interrupt_reason: StringName = _resolve_interrupt_reason()
			CombatTelemetry.emit_event(&"attack_interrupted", {
				"actor": str(agent.name),
				"attack_sequence_id": _attack_sequence_id,
				"phase": String(_attack_phase),
				"reason": String(interrupt_reason)
			})
			_notify_clash_attack_interrupted(interrupt_reason)
		_clear_clash_cancel_request()
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
	_finished_normally = true
	_attack_phase = &"finished"
	if agent != null:
		_clear_clash_cancel_request()
		agent.clear_attack_pending()
	get_root().dispatch(EVENT_FINISHED)


func _resolved_action_data() -> Resource:
	if agent != null:
		var loadout: EquipmentLoadout = agent.get_equipment_loadout_runtime() as EquipmentLoadout
		if loadout != null and loadout.weapon != null and loadout.weapon.action_data != null:
			return loadout.weapon.action_data
	return action_data


func _reset_attack_telemetry() -> void:
	_attack_sequence_counter += 1
	_attack_sequence_id = _attack_sequence_counter
	_attack_phase = &"idle"
	_attack_started_runtime = false
	_finished_normally = false


func _emit_attack_phase(phase: StringName, target: String = "") -> void:
	_attack_phase = phase
	var payload := {
		"actor": str(agent.name),
		"attack_sequence_id": _attack_sequence_id,
		"phase": String(phase)
	}
	if not target.is_empty():
		payload["target"] = target
	CombatTelemetry.emit_event(&"attack_phase_started", payload)
	_notify_clash_attack_phase(phase, target)


func _resolve_interrupt_reason() -> StringName:
	if agent == null:
		return &"missing_agent"
	var health := agent.get_node_or_null(^"Health") as HealthComponent
	if health != null and not health.is_alive():
		if agent.has_meta(&"attack_interrupt_reason"):
			agent.remove_meta(&"attack_interrupt_reason")
		return &"death"
	if agent.has_meta(&"attack_interrupt_reason"):
		var reason: StringName = StringName(str(agent.get_meta(&"attack_interrupt_reason")))
		agent.remove_meta(&"attack_interrupt_reason")
		return reason
	return &"state_exit"


func _get_clash_component() -> Node:
	if agent == null:
		return null
	return agent.get_node_or_null(^"CombatClashComponent")


func _notify_clash_attack_started(target: String) -> void:
	var clash := _get_clash_component()
	if clash != null:
		clash.notify_attack_started(_attack_sequence_id, target)


func _notify_clash_attack_phase(phase: StringName, target: String) -> void:
	var clash := _get_clash_component()
	if clash != null:
		clash.notify_attack_phase(_attack_sequence_id, phase, target)


func _notify_clash_attack_interrupted(reason: StringName) -> void:
	var clash := _get_clash_component()
	if clash != null:
		clash.notify_attack_interrupted(_attack_sequence_id, _attack_phase, reason)


func _should_cancel_attack_for_clash() -> bool:
	if agent == null:
		return false
	if not agent.has_meta(CLASH_CANCEL_ATTACK_SEQUENCE_META):
		return false
	return int(agent.get_meta(CLASH_CANCEL_ATTACK_SEQUENCE_META)) == _attack_sequence_id


func _cancel_attack_for_clash() -> void:
	if agent == null:
		_finish_attack()
		return
	var hitbox := agent.get_node_or_null(hitbox_path) as HitboxComponent
	if hitbox != null:
		hitbox.set_hitbox_enabled(false, &"combat_clash")
	var reason: StringName = StringName(str(agent.get_meta(CLASH_CANCEL_REASON_META, &"mutual_clash")))
	CombatTelemetry.emit_event(&"attack_interrupted", {
		"actor": str(agent.name),
		"attack_sequence_id": _attack_sequence_id,
		"phase": String(_attack_phase),
		"reason": String(reason)
	})
	CombatTelemetry.emit_event(&"combat_clash_attack_cancelled", {
		"actor": str(agent.name),
		"attack_sequence_id": _attack_sequence_id,
		"phase": String(_attack_phase),
		"reason": String(reason),
		"post_clash_lockout_sec": _clash_recovery_sec()
	})
	_notify_clash_attack_interrupted(reason)
	_cooldown_until_sec = Time.get_ticks_msec() * 0.001 + _clash_recovery_sec()
	_clear_clash_cancel_request()
	_finish_attack()


func _clear_clash_cancel_request() -> void:
	if agent == null:
		return
	if agent.has_meta(CLASH_CANCEL_ATTACK_SEQUENCE_META) and int(agent.get_meta(CLASH_CANCEL_ATTACK_SEQUENCE_META)) == _attack_sequence_id:
		agent.remove_meta(CLASH_CANCEL_ATTACK_SEQUENCE_META)
	if agent.has_meta(CLASH_CANCEL_REASON_META):
		agent.remove_meta(CLASH_CANCEL_REASON_META)
	if agent.has_meta(CLASH_RECOVERY_SEC_META):
		agent.remove_meta(CLASH_RECOVERY_SEC_META)


func _clash_recovery_sec() -> float:
	if agent == null:
		return _recover()
	if not agent.has_meta(CLASH_RECOVERY_SEC_META):
		return _recover()
	return maxf(_recover(), float(agent.get_meta(CLASH_RECOVERY_SEC_META)))
