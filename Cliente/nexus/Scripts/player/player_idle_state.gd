extends LimboState


func _enter() -> void:
	if agent != null and agent.has_method("play_idle_animation"):
		agent.play_idle_animation()


func _update(_delta: float) -> void:
	if agent != null and agent.has_method("is_player_moving") and agent.is_player_moving():
		get_root().dispatch(EVENT_FINISHED)
