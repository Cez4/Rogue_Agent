@tool
extends BTAction

func _generate_name() -> String:
	return "IdleWanderLoop"

func _tick(delta: float) -> Status:
	if agent == null:
		return FAILURE

	if agent.has_method("is_actor_moving") and agent.is_actor_moving():
		if agent.has_method("update_walk_animation"):
			agent.update_walk_animation()
		if agent.has_method("try_play_wander_emote"):
			agent.try_play_wander_emote()
		return RUNNING

	if agent.has_method("play_idle_animation"):
		agent.play_idle_animation()

	if agent.has_method("should_start_wander") and agent.should_start_wander(delta):
		if agent.has_method("begin_wander"):
			agent.begin_wander()

	return RUNNING
