@tool
extends BTAction

@export var event_name: StringName = &"tactical_event"
@export var suppress_repeated_event: bool = true

static var _last_event_by_actor: Dictionary = {}

func _generate_name() -> String:
	return "Emit Telemetry"

func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
	if suppress_repeated_event:
		var actor_key: int = int(agent.get_instance_id())
		var last_event: StringName = _last_event_by_actor.get(actor_key, &"") as StringName
		if last_event == event_name:
			return SUCCESS
		_last_event_by_actor[actor_key] = event_name

	CombatTelemetry.emit_event(event_name, {
		"actor": agent.name,
		"state": "bt_action"
	})
	return SUCCESS
