class_name CombatTelemetry
extends RefCounted

static var _dedupe_last_emit_ms: Dictionary = {}
const _DEFAULT_DEDUPE_MS := 500

static func emit_event(event_name: StringName, payload: Dictionary) -> void:
	if _should_suppress(event_name, payload):
		return
	var line := {
		"event": String(event_name),
		"ts_ms": Time.get_ticks_msec(),
		"data": payload
	}
	print("[COMBAT_TELEMETRY] %s" % JSON.stringify(line))


static func _should_suppress(event_name: StringName, payload: Dictionary) -> bool:
	# Deduplicate high-frequency blocked events to keep logs readable for tuning.
	if event_name != &"attack_blocked_reason":
		return false
	var reason: String = str(payload.get("reason", ""))
	if reason != "request_attack_not_started":
		return false
	var actor: String = str(payload.get("actor", ""))
	var key: String = "%s|%s|%s" % [String(event_name), actor, reason]
	var now_ms: int = Time.get_ticks_msec()
	var last_ms: int = int(_dedupe_last_emit_ms.get(key, -999999999))
	if now_ms - last_ms < _DEFAULT_DEDUPE_MS:
		return true
	_dedupe_last_emit_ms[key] = now_ms
	return false
