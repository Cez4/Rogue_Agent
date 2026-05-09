@tool
extends BTAction

func _generate_name() -> String:
	return "IdleWanderLoop"

func _tick(delta: float) -> Status:
	if agent == null:
		return FAILURE

	if agent.is_actor_moving():
		agent.update_walk_animation()
		agent.try_play_wander_emote()
		return RUNNING

	agent.play_idle_animation()

	if agent.should_start_wander(delta):
		agent.begin_wander()

	return RUNNING
