class_name ActorStatsRuntime
extends RefCounted

static func setup_stats(actor: Actor8DirLimbo) -> void:
	var stats: StatsComponent = actor.get_node_or_null(^"Stats") as StatsComponent
	if stats == null:
		stats = StatsComponent.new()
		stats.name = "Stats"
		actor.add_child(stats)
	actor._bridge_set_stats_component(stats)
	stats.set_base_stats({
		&"dex": actor.base_dex,
		&"perception_radius": actor.base_perception_radius,
		&"perception_min_distance": actor.base_perception_min_distance,
		&"perception_max_distance": actor.base_perception_max_distance,
		&"combat_acquire_radius": actor.get_combat_acquire_radius(),
		&"combat_lose_radius": actor.get_combat_lose_radius(),
		&"combat_target_memory_sec": actor.get_combat_target_memory_sec(),
		&"combat_reacquire_interval_sec": actor.get_combat_reacquire_interval_sec(),
		&"attack_range_bonus": actor.base_attack_range_bonus,
		&"attack_range_multiplier": actor.base_attack_range_multiplier,
		&"attack_stop_buffer": actor.combat_perception_profile.attack_stop_buffer if actor.combat_perception_profile != null else actor.base_attack_stop_buffer
	})
	apply_loadout_modifiers_to_stats(actor)


static func apply_loadout_modifiers_to_stats(actor: Actor8DirLimbo) -> void:
	var stats: StatsComponent = actor._bridge_get_stats_component()
	if stats == null:
		return
	stats.clear_modifiers()
	var loadout := actor.get_equipment_loadout_runtime()
	if loadout == null:
		return
	add_item_modifiers(actor, loadout.weapon)
	add_item_modifiers(actor, loadout.armor)
	add_item_modifiers(actor, loadout.necklace)


static func add_item_modifiers(actor: Actor8DirLimbo, item: EquipmentData) -> void:
	if item == null:
		return
	var mods: Array[StatModifier] = item.stat_modifiers
	for modifier in mods:
		if modifier != null:
			var stats: StatsComponent = actor._bridge_get_stats_component()
			if stats != null:
				stats.add_modifier(modifier)


static func get_stat_value(actor: Actor8DirLimbo, stat_id: StringName, fallback: float = 0.0) -> float:
	var stats: StatsComponent = actor._bridge_get_stats_component()
	if stats == null:
		return fallback
	return stats.get_stat(stat_id, fallback)
