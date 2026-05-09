class_name ActorLifecycleRuntime
extends RefCounted
const ActorCombatRuntimeRef = preload("res://Scripts/actors/services/actor_combat_runtime.gd")

static func respawn_after_delay(actor: Actor8DirLimbo) -> void:
	await actor.get_tree().create_timer(maxf(0.5, actor.respawn_delay_sec)).timeout
	var health := actor.get_node_or_null(^"Health") as HealthComponent
	if health != null:
		health.reset_health()
	actor.set_actor_dead(false)
	actor.global_position = actor.get_spawn_position()
	actor.velocity = Vector2.ZERO
	ActorCombatRuntimeRef.reset_combat_memory(actor)
	ActorCombatRuntimeRef.enable_combat_collision(actor)
	if actor.motor != null:
		actor.motor.stop()
	if actor.hsm != null:
		actor.hsm.set_active(true)
	actor.play_idle_animation()
	await actor.get_tree().create_timer(maxf(0.0, actor.respawn_brain_delay_sec)).timeout
	actor.set_brain_active(true)
	CombatTelemetry.emit_event(&"respawned", {"actor": actor.name})
