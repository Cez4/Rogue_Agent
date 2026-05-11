@tool
extends BTAction

@export var event_name: StringName = &"tactical_event"

func _generate_name() -> String:
	return "Emit Telemetry"

func _tick(_delta: float) -> Status:
	if agent == null:
		return FAILURE
		
	CombatTelemetry.emit_event(event_name, {
		"actor": agent.name,
		"state": "bt_action"
	})
	return SUCCESS