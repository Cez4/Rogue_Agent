extends Node

signal settings_changed

const _CFG_PATH := "user://debug_telemetry.cfg"
const _SECTION := "telemetry"

var combat_enabled: bool = true
var thought_enabled: bool = true
var thought_dedupe_ms: int = 700
var thought_actor_min_interval_ms: int = 300
var thought_transitions_only: bool = true
var thought_heartbeat_ms: int = 2000
var boundary_guard_enabled: bool = false

func _ready() -> void:
	_load_from_disk()

func set_combat_enabled(enabled: bool) -> void:
	if combat_enabled == enabled:
		return
	combat_enabled = enabled
	_persist_and_emit()

func set_thought_enabled(enabled: bool) -> void:
	if thought_enabled == enabled:
		return
	thought_enabled = enabled
	_persist_and_emit()

func set_thought_dedupe_ms(value: int) -> void:
	var clamped := clampi(value, 0, 5000)
	if thought_dedupe_ms == clamped:
		return
	thought_dedupe_ms = clamped
	_persist_and_emit()

func set_thought_actor_min_interval_ms(value: int) -> void:
	var clamped := clampi(value, 0, 5000)
	if thought_actor_min_interval_ms == clamped:
		return
	thought_actor_min_interval_ms = clamped
	_persist_and_emit()

func set_thought_transitions_only(enabled: bool) -> void:
	if thought_transitions_only == enabled:
		return
	thought_transitions_only = enabled
	_persist_and_emit()

func set_thought_heartbeat_ms(value: int) -> void:
	var clamped := clampi(value, 0, 10000)
	if thought_heartbeat_ms == clamped:
		return
	thought_heartbeat_ms = clamped
	_persist_and_emit()

func _persist_and_emit() -> void:
	_save_to_disk()
	CombatTelemetry.emit_event(&"telemetry_toggle_changed", {
		"combat_enabled": combat_enabled,
		"thought_enabled": thought_enabled,
		"thought_dedupe_ms": thought_dedupe_ms,
		"thought_actor_min_interval_ms": thought_actor_min_interval_ms,
		"thought_transitions_only": thought_transitions_only,
		"thought_heartbeat_ms": thought_heartbeat_ms,
		"boundary_guard_enabled": boundary_guard_enabled
	})
	settings_changed.emit()

func set_boundary_guard_enabled(enabled: bool) -> void:
	if boundary_guard_enabled == enabled:
		return
	boundary_guard_enabled = enabled
	_persist_and_emit()

func _load_from_disk() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(_CFG_PATH)
	if err != OK:
		_save_to_disk()
		return
	combat_enabled = bool(cfg.get_value(_SECTION, "combat_enabled", combat_enabled))
	thought_enabled = bool(cfg.get_value(_SECTION, "thought_enabled", thought_enabled))
	thought_dedupe_ms = int(cfg.get_value(_SECTION, "thought_dedupe_ms", thought_dedupe_ms))
	thought_actor_min_interval_ms = int(cfg.get_value(_SECTION, "thought_actor_min_interval_ms", thought_actor_min_interval_ms))
	thought_transitions_only = bool(cfg.get_value(_SECTION, "thought_transitions_only", thought_transitions_only))
	thought_heartbeat_ms = int(cfg.get_value(_SECTION, "thought_heartbeat_ms", thought_heartbeat_ms))
	boundary_guard_enabled = bool(cfg.get_value(_SECTION, "boundary_guard_enabled", boundary_guard_enabled))
	thought_dedupe_ms = clampi(thought_dedupe_ms, 0, 5000)
	thought_actor_min_interval_ms = clampi(thought_actor_min_interval_ms, 0, 5000)
	thought_heartbeat_ms = clampi(thought_heartbeat_ms, 0, 10000)

func _save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(_SECTION, "combat_enabled", combat_enabled)
	cfg.set_value(_SECTION, "thought_enabled", thought_enabled)
	cfg.set_value(_SECTION, "thought_dedupe_ms", thought_dedupe_ms)
	cfg.set_value(_SECTION, "thought_actor_min_interval_ms", thought_actor_min_interval_ms)
	cfg.set_value(_SECTION, "thought_transitions_only", thought_transitions_only)
	cfg.set_value(_SECTION, "thought_heartbeat_ms", thought_heartbeat_ms)
	cfg.set_value(_SECTION, "boundary_guard_enabled", boundary_guard_enabled)
	cfg.save(_CFG_PATH)
