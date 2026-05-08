class_name CombatTelemetry
extends RefCounted

static func emit_event(event_name: StringName, payload: Dictionary) -> void:
	var line := {
		"event": String(event_name),
		"ts_ms": Time.get_ticks_msec(),
		"data": payload
	}
	print("[COMBAT_TELEMETRY] %s" % JSON.stringify(line))
