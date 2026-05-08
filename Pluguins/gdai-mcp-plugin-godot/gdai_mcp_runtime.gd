extends Node


func _enter_tree():
	var runtime_port := _get_runtime_port_from_project_config()
	if not _is_port_available(runtime_port):
		print("[GDAIRuntimeServer] Runtime server skipped: port %d already in use." % runtime_port)
		return

	const RUNTIME_SERVER = "GDAIRuntimeServer"
	if ClassDB.class_exists(RUNTIME_SERVER) and ClassDB.can_instantiate(RUNTIME_SERVER):
		var runtime_server = ClassDB.instantiate(RUNTIME_SERVER)
		add_child(runtime_server)


func _get_runtime_port_from_project_config() -> int:
	const DEFAULT_RUNTIME_PORT := 3572
	const CONFIG_PATH := "res://gdai_mcp_project_config.json"

	if not FileAccess.file_exists(CONFIG_PATH):
		return DEFAULT_RUNTIME_PORT

	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return DEFAULT_RUNTIME_PORT

	var parse_result: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parse_result) != TYPE_DICTIONARY:
		return DEFAULT_RUNTIME_PORT

	var config: Dictionary = parse_result
	var runtime_port_raw: Variant = config.get("GDAI_RUNTIME_SERVER_PORT", str(DEFAULT_RUNTIME_PORT))
	return int(str(runtime_port_raw))


func _is_port_available(port: int) -> bool:
	var tcp_server := TCPServer.new()
	var err := tcp_server.listen(port, "127.0.0.1")
	if err != OK:
		return false
	tcp_server.stop()
	return true
