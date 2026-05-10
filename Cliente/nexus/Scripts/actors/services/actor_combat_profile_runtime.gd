class_name ActorCombatProfileRuntime
extends RefCounted

static func get_combat_action_data(actor: Actor8DirLimbo) -> CombatActionData:
	if actor.equipment_loadout != null and actor.equipment_loadout.weapon != null:
		if actor.equipment_loadout.weapon.get("action_data") != null:
			return actor.equipment_loadout.weapon.action_data
	if actor.attack_state != null and actor.attack_state.get("action_data") != null:
		return actor.attack_state.get("action_data") as CombatActionData
	return null

static func get_attack_range(actor: Actor8DirLimbo) -> float:
	var range_bonus: float = actor.get_stat_value(&"attack_range_bonus", actor.base_attack_range_bonus)
	var range_mul: float = actor.get_stat_value(&"attack_range_multiplier", actor.base_attack_range_multiplier)
	if actor.equipment_loadout != null and actor.equipment_loadout.weapon != null:
		var weapon_range: float = float(actor.equipment_loadout.weapon.attack_range)
		return maxf(6.0, (weapon_range + range_bonus) * (1.0 + range_mul))
	return maxf(6.0, (actor.chase_attack_range + range_bonus) * (1.0 + range_mul))


static func get_attack_stop_distance(actor: Actor8DirLimbo) -> float:
	var profile_stop_buffer: float = actor.base_attack_stop_buffer
	if actor.combat_perception_profile != null:
		profile_stop_buffer = actor.combat_perception_profile.attack_stop_buffer
	var stop_buffer: float = actor.get_stat_value(&"attack_stop_buffer", profile_stop_buffer)
	return maxf(2.0, get_attack_range(actor) - stop_buffer)


static func get_perception_min_distance(actor: Actor8DirLimbo) -> float:
	return maxf(0.0, actor.get_stat_value(&"perception_min_distance", actor.base_perception_min_distance))


static func get_perception_max_distance(actor: Actor8DirLimbo) -> float:
	var profile_max: float = actor.base_perception_max_distance
	if actor.combat_perception_profile != null:
		profile_max = actor.combat_perception_profile.lose_radius
	return maxf(get_perception_min_distance(actor), actor.get_stat_value(&"perception_max_distance", profile_max))


static func get_combat_acquire_radius(actor: Actor8DirLimbo) -> float:
	var profile_acquire: float = actor.base_perception_radius
	if actor.combat_perception_profile != null:
		profile_acquire = actor.combat_perception_profile.acquire_radius
	return maxf(8.0, actor.get_stat_value(&"combat_acquire_radius", profile_acquire))


static func get_combat_lose_radius(actor: Actor8DirLimbo) -> float:
	var profile_lose: float = maxf(get_combat_acquire_radius(actor), actor.base_perception_max_distance)
	if actor.combat_perception_profile != null:
		profile_lose = maxf(get_combat_acquire_radius(actor), actor.combat_perception_profile.lose_radius)
	return maxf(get_combat_acquire_radius(actor), actor.get_stat_value(&"combat_lose_radius", profile_lose))


static func get_combat_target_memory_sec(actor: Actor8DirLimbo) -> float:
	var profile_memory: float = 1.2
	if actor.combat_perception_profile != null:
		profile_memory = actor.combat_perception_profile.target_memory_sec
	return maxf(0.0, actor.get_stat_value(&"combat_target_memory_sec", profile_memory))


static func get_combat_reacquire_interval_sec(actor: Actor8DirLimbo) -> float:
	var profile_reacquire: float = 0.12
	if actor.combat_perception_profile != null:
		profile_reacquire = actor.combat_perception_profile.reacquire_interval_sec
	return maxf(0.01, actor.get_stat_value(&"combat_reacquire_interval_sec", profile_reacquire))
