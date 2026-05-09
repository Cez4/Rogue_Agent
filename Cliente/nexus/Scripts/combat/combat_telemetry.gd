class_name CombatTelemetry
extends RefCounted
const CombatBlockedReasonsRef = preload("res://Scripts/combat/combat_blocked_reasons.gd")

static var _dedupe_last_emit_ms: Dictionary = {}
const _DEFAULT_DEDUPE_MS := 500
const _REACQUIRE_DEDUPE_MS := 450
const _OUT_OF_RANGE_DEDUPE_MS := 650

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
	var actor: String = str(payload.get("actor", ""))
	var target: String = str(payload.get("target", ""))
	var now_ms: int = Time.get_ticks_msec()

	if event_name == &"reacquire":
		var reacquire_key: String = "%s|%s|%s" % [String(event_name), actor, target]
		var reacquire_last_ms: int = int(_dedupe_last_emit_ms.get(reacquire_key, -999999999))
		if now_ms - reacquire_last_ms < _REACQUIRE_DEDUPE_MS:
			return true
		_dedupe_last_emit_ms[reacquire_key] = now_ms
		return false

	if event_name == &"attack_blocked_reason":
		var reason: String = str(payload.get("reason", ""))
		var dedupe_ms: int = _DEFAULT_DEDUPE_MS
		if reason == CombatBlockedReasonsRef.OUT_OF_RANGE:
			dedupe_ms = _OUT_OF_RANGE_DEDUPE_MS
		var blocked_key: String = "%s|%s|%s|%s" % [String(event_name), actor, target, reason]
		var blocked_last_ms: int = int(_dedupe_last_emit_ms.get(blocked_key, -999999999))
		if now_ms - blocked_last_ms < dedupe_ms:
			return true
		_dedupe_last_emit_ms[blocked_key] = now_ms
		return false

	return false
