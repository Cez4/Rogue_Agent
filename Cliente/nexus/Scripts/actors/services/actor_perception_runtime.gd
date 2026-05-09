class_name ActorPerceptionRuntime
extends RefCounted

const ActorSocialRuntimeRef = preload("res://Scripts/actors/services/actor_social_runtime.gd")

static func look_toward(actor: Node, target_position: Vector2) -> void:
	var dir: Vector2 = target_position - actor.global_position
	actor.play_directional_runtime(actor.idle_prefix, dir)


static func can_look_target(actor: Node, target: Node2D) -> bool:
	return ActorSocialRuntimeRef.can_look_target(actor, target)


static func trigger_look_cooldown(actor: Node) -> void:
	ActorSocialRuntimeRef.trigger_look_cooldown(actor)


static func stop_movement_for_look(actor: Node) -> void:
	if actor.motor != null:
		actor.motor.stop()
	actor.velocity = Vector2.ZERO


static func play_look_emote(actor: Node) -> void:
	await actor.show_emote_runtime(actor.look_emote_name, false, maxf(0.2, actor.look_emote_hold_sec), 2)
