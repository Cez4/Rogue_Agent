extends LimboState
class_name StaggerState

@export var stagger_duration_sec: float = 2.0
var _timer: float = 0.0

func _enter() -> void:
	var actor := agent as Actor8DirLimbo
	if actor == null:
		return
	
	# Stop all movement
	actor.stop_motor_movement()
	
	# Play exhausted/stagger animation or idle
	actor.play_idle_animation()
	
	_timer = stagger_duration_sec
	
	CombatTelemetry.emit_event(&"actor_staggered", {
		"actor": actor.name,
		"duration": stagger_duration_sec
	})

func _update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		get_root().dispatch(EVENT_FINISHED)
