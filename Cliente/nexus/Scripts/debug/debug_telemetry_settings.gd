extends Node

signal settings_changed

const _CFG_PATH := "user://debug_telemetry.cfg"
const _SECTION := "telemetry"

var combat_enabled: bool = true
var thought_enabled: bool = true
var thought_dedupe_ms: int = 700
var thought_actor_min_interval_ms: int = 300

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

func _persist_and_emit() -> void:
	_save_to_disk()
	CombatTelemetry.emit_event(&"telemetry_toggle_changed", {
		"combat_enabled": combat_enabled,
		"thought_enabled": thought_enabled,
		"thought_dedupe_ms": thought_dedupe_ms,
		"thought_actor_min_interval_ms": thought_actor_min_interval_ms
	})
	settings_changed.emit()

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
	thought_dedupe_ms = clampi(thought_dedupe_ms, 0, 5000)
	thought_actor_min_interval_ms = clampi(thought_actor_min_interval_ms, 0, 5000)

func _save_to_disk() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value(_SECTION, "combat_enabled", combat_enabled)
	cfg.set_value(_SECTION, "thought_enabled", thought_enabled)
	cfg.set_value(_SECTION, "thought_dedupe_ms", thought_dedupe_ms)
	cfg.set_value(_SECTION, "thought_actor_min_interval_ms", thought_actor_min_interval_ms)
	cfg.save(_CFG_PATH)
