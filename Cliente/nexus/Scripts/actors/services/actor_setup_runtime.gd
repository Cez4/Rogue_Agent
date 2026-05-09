class_name ActorSetupRuntime
extends RefCounted

static func ready(actor: Node) -> void:
	actor.set_spawn_position(actor.global_position)
	if actor.combat_perception_profile == null:
		actor.combat_perception_profile = CombatPerceptionProfile.new()
	if actor.player_controlled:
		actor.add_to_group("player")
	else:
		actor.add_to_group("npc")
		if actor.is_hostile:
			actor.add_to_group("hostile")

	if actor.movement_config == null:
		actor.movement_config = load("res://configs/player/player_movement_config.tres")
	if actor.equipment_loadout == null and actor.player_controlled:
		actor.equipment_loadout = load("res://configs/items/loadouts/player_starter_loadout.tres")
	if actor.movement_config != null:
		actor.movement_config = actor.movement_config.duplicate(true)
		if actor.enable_wander and not actor.player_controlled:
			# Wander NPCs should not depend on nav projection being available in all maps.
			actor.movement_config.project_target_to_navmesh = false

	actor.motor.config = actor.movement_config
	actor.motor.setup(actor)
	actor.controller.setup(actor)
	actor.setup_stats_runtime()
	_setup_interactable_component(actor)
	_connect_health_signals(actor)
	actor.reset_wander_timer_runtime()
	actor.hide_emote_runtime()
	actor.setup_hsm_runtime()


static func setup_interactable_component(actor: Node) -> void:
	_setup_interactable_component(actor)


static func connect_health_signals(actor: Node) -> void:
	_connect_health_signals(actor)


static func _setup_interactable_component(actor: Node) -> void:
	var interactable := actor.get_node_or_null(^"Interactable") as InteractableComponent
	if interactable == null:
		interactable = InteractableComponent.new()
		interactable.name = "Interactable"
		actor.add_child(interactable)
	if actor.is_hostile:
		interactable.kind = InteractableComponent.Kind.HOSTILE
		interactable.primary_intent = &"none"
		interactable.secondary_intent = &"chase_attack"
	elif actor.player_controlled:
		interactable.kind = InteractableComponent.Kind.FRIENDLY
		interactable.primary_intent = &"none"
		interactable.secondary_intent = &"none"
	else:
		interactable.kind = InteractableComponent.Kind.FRIENDLY
		interactable.primary_intent = &"inspect"
		interactable.secondary_intent = &"none"
	interactable.interaction_range = actor.interaction_stop_range


static func _connect_health_signals(actor: Node) -> void:
	var health := actor.get_node_or_null(^"Health")
	if health == null:
		return
	if health.has_signal("death") and not health.death.is_connected(actor.on_health_death_runtime):
		health.death.connect(actor.on_health_death_runtime)
