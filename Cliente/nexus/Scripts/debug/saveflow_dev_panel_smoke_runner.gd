class_name SaveFlowDevPanelSmokeRunner
extends Node

@export var panel_path: NodePath = ^"../SaveFlowDevPanel"


func _ready() -> void:
	call_deferred("_run_smoke")


func _run_smoke() -> void:
	var panel := get_node_or_null(panel_path)
	if panel == null:
		_emit_result(false, "missing_panel")
		queue_free()
		return
	if not panel.has_method("save_slot") or not panel.has_method("load_slot") or not panel.has_method("refresh_summary"):
		_emit_result(false, "invalid_panel_contract")
		queue_free()
		return

	panel.call("save_slot")
	panel.call("load_slot")
	panel.call("refresh_summary")
	_emit_result(true, "ok")
	queue_free()


func _emit_result(ok: bool, reason: String) -> void:
	CombatTelemetry.emit_event(&"saveflow_dev_panel_smoke_result", {
		"ok": ok,
		"reason": reason,
	})
