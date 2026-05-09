class_name BTDecisionTelemetry
extends RefCounted

static var _last_emit_ms: Dictionary = {}
const _DEFAULT_DEDUPE_MS: int = 220

static func emit(task_name: String, agent: Node, blackboard: Variant, debug_var: StringName, status_name: String, reason: String = "") -> void:
	if blackboard == null:
		return
	var enabled: bool = false
	if blackboard.has_var(debug_var):
		enabled = bool(blackboard.get_var(debug_var))
	if not enabled:
		return
	var actor_name: String = ""
	if agent != null:
		actor_name = str(agent.name)
	var dedupe_key: String = "%s|%s|%s|%s" % [task_name, actor_name, status_name, reason]
	var now_ms: int = Time.get_ticks_msec()
	var last_ms: int = int(_last_emit_ms.get(dedupe_key, -999999999))
	if now_ms - last_ms < _DEFAULT_DEDUPE_MS:
		return
	_last_emit_ms[dedupe_key] = now_ms
	CombatTelemetry.emit_event(&"bt_decision", {
		"task": task_name,
		"actor": actor_name,
		"status": status_name,
		"reason": reason
	})
