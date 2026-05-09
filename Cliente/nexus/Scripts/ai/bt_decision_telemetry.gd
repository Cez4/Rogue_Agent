class_name BTDecisionTelemetry
extends RefCounted

static var _last_emit_ms: Dictionary = {}
static var _last_actor_emit_ms: Dictionary = {}
static var _last_actor_signature: Dictionary = {}
const _DEFAULT_DEDUPE_MS: int = 220
const _DEFAULT_ACTOR_MIN_MS: int = 0
const _DEFAULT_HEARTBEAT_MS: int = 2000
const _REASON_MIN_MS := {
	"attack_pending": 1200,
	"idling": 900,
	"moving": 900
}

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
	var dedupe_ms: int = _DEFAULT_DEDUPE_MS
	var actor_min_ms: int = _DEFAULT_ACTOR_MIN_MS
	var transitions_only: bool = false
	var heartbeat_ms: int = _DEFAULT_HEARTBEAT_MS
	var settings := _get_debug_settings()
	if settings != null:
		dedupe_ms = max(0, int(settings.get("thought_dedupe_ms")))
		actor_min_ms = max(0, int(settings.get("thought_actor_min_interval_ms")))
		transitions_only = bool(settings.get("thought_transitions_only"))
		heartbeat_ms = max(0, int(settings.get("thought_heartbeat_ms")))
	elif blackboard.has_var(AIBlackboardKeys.DEBUG_BT_DECISION_DEDUPE_MS):
		dedupe_ms = max(0, int(blackboard.get_var(AIBlackboardKeys.DEBUG_BT_DECISION_DEDUPE_MS)))
	var reason_min_ms: int = int(_REASON_MIN_MS.get(reason, 0))
	dedupe_ms = max(dedupe_ms, reason_min_ms)
	if transitions_only and actor_name != "":
		var actor_sig_key: String = actor_name
		var curr_sig: String = "%s|%s|%s" % [task_name, status_name, reason]
		var last_sig: String = str(_last_actor_signature.get(actor_sig_key, ""))
		var last_actor_ms_for_sig: int = int(_last_actor_emit_ms.get(actor_sig_key, -999999999))
		if curr_sig == last_sig and now_ms - last_actor_ms_for_sig < heartbeat_ms:
			return
	if actor_name != "":
		var last_actor_ms: int = int(_last_actor_emit_ms.get(actor_name, -999999999))
		if now_ms - last_actor_ms < actor_min_ms:
			return
	if now_ms - last_ms < dedupe_ms:
		return
	if actor_name != "":
		_last_actor_emit_ms[actor_name] = now_ms
		_last_actor_signature[actor_name] = "%s|%s|%s" % [task_name, status_name, reason]
	_last_emit_ms[dedupe_key] = now_ms
	CombatTelemetry.emit_event(&"bt_decision", {
		"task": task_name,
		"actor": actor_name,
		"status": status_name,
		"reason": reason
	})


static func _get_debug_settings() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return null
	return tree.root.get_node_or_null("DebugTelemetrySettings")
