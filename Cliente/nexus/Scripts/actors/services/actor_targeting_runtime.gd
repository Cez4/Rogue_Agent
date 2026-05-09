class_name ActorTargetingRuntime
extends RefCounted

static func set_interaction_target(actor: Node, target: Node2D, stop_range: float = -1.0) -> void:
	if target == null or not is_instance_valid(target) or target == actor:
		clear_interaction_target(actor)
		return
	actor._interaction_target = target
	if stop_range < 0.0:
		actor._interaction_target_range = actor.interaction_stop_range
	else:
		actor._interaction_target_range = maxf(8.0, stop_range)


static func clear_interaction_target(actor: Node) -> void:
	actor._interaction_target = null
	actor._interaction_target_range = 0.0


static func cancel_all_intents(actor: Node) -> void:
	clear_interaction_target(actor)
	actor.cancel_chase_attack()
