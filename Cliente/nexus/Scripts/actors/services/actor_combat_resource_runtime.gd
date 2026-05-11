class_name ActorCombatResourceRuntime
extends RefCounted

const ActorCombatProfileRuntimeRef = preload("res://Scripts/actors/services/actor_combat_profile_runtime.gd")


static func has_stamina_for_attack(actor: Actor8DirLimbo) -> bool:
	var stamina := actor.get_node_or_null(^"Stamina") as StaminaComponent
	if stamina == null:
		return true
	var action_data := ActorCombatProfileRuntimeRef.get_combat_action_data(actor)
	if action_data == null or action_data.stamina_cost <= 0.0:
		return true
	return stamina.has_stamina(get_required_stamina_for_attack(actor))


static func get_required_stamina_for_attack(actor: Actor8DirLimbo) -> float:
	var action_data := ActorCombatProfileRuntimeRef.get_combat_action_data(actor)
	if action_data == null:
		return 0.0
	var cost: float = maxf(0.0, action_data.stamina_cost)
	if cost <= 0.0:
		return 0.0
	var budget_hits: float = maxf(1.0, action_data.attack_stamina_budget_hits)
	var required: float = cost * budget_hits
	var stamina := actor.get_node_or_null(^"Stamina") as StaminaComponent
	if stamina != null and stamina.is_exhausted():
		var exhausted_multiplier: float = maxf(1.0, action_data.attack_stamina_resume_multiplier_when_exhausted)
		required = maxf(required, cost * exhausted_multiplier)
	else:
		var buffer_ratio: float = clampf(action_data.attack_stamina_buffer_ratio, 0.0, 2.0)
		required = maxf(required, cost * (1.0 + buffer_ratio))
	if stamina != null:
		var min_after_ratio: float = clampf(action_data.attack_stamina_min_after_attack_ratio, 0.0, 1.0)
		required = maxf(required, cost + (stamina.max_stamina * min_after_ratio))
	return required


static func get_low_stamina_kite_probability(actor: Actor8DirLimbo) -> float:
	var action_data := ActorCombatProfileRuntimeRef.get_combat_action_data(actor)
	if action_data == null:
		return 0.35
	return clampf(action_data.low_stamina_kite_probability, 0.0, 1.0)


static func get_low_stamina_kite_distance(actor: Actor8DirLimbo) -> float:
	var action_data := ActorCombatProfileRuntimeRef.get_combat_action_data(actor)
	if action_data == null:
		return 18.0
	return maxf(0.0, action_data.low_stamina_kite_distance)


static func get_low_stamina_kite_cooldown_ms(actor: Actor8DirLimbo) -> int:
	var action_data := ActorCombatProfileRuntimeRef.get_combat_action_data(actor)
	if action_data == null:
		return 260
	return max(0, int(action_data.low_stamina_kite_cooldown_ms))
