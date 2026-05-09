extends LimboState

func _enter() -> void:
	if agent == null:
		return
	agent.play_walk_animation()

func _update(_delta: float) -> void:
	if agent == null:
		return
	agent.update_walk_animation()
	if not agent.is_actor_moving():
		get_root().dispatch(EVENT_FINISHED)
