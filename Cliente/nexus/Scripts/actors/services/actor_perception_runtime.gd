class_name ActorPerceptionRuntime
extends RefCounted

const ActorSocialRuntimeRef = preload("res://Scripts/actors/services/actor_social_runtime.gd")
const ActorRuntimeBridgeRef = preload("res://Scripts/actors/services/actor_runtime_bridge.gd")

static func look_toward(actor: Actor8DirLimbo, target_position: Vector2) -> void:
	var dir: Vector2 = target_position - actor.global_position
	ActorRuntimeBridgeRef.play_directional(actor, actor.idle_prefix, dir)


static func can_look_target(actor: Actor8DirLimbo, target: Node2D) -> bool:
	return ActorSocialRuntimeRef.can_look_target(actor, target)


static func trigger_look_cooldown(actor: Actor8DirLimbo) -> void:
	ActorSocialRuntimeRef.trigger_look_cooldown(actor)


static func stop_movement_for_look(actor: Actor8DirLimbo) -> void:
	if actor.motor != null:
		actor.motor.stop()
	actor.velocity = Vector2.ZERO


static func play_look_emote(actor: Actor8DirLimbo) -> void:
	await ActorRuntimeBridgeRef.show_emote(actor, actor.look_emote_name, false, maxf(0.2, actor.look_emote_hold_sec), 2)
