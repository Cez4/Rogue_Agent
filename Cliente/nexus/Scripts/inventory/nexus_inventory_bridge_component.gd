class_name NexusInventoryBridgeComponent
extends Node

const AUTHORITY_SCRIPT_PATH := "res://Scripts/inventory/nexus_inventory_authority.gd"

@export var actor_path: NodePath = ^".."
@export var database: InventoryDatabase
@export var use_grid_inventory: bool = false
@export var grid_size: Vector2i = Vector2i(4, 4)
@export var starting_items: Array[String] = []
@export var starting_item_amounts: Array[int] = []

var _actor: Node
var _inventory: Inventory
var _starting_items_applied := false


func _ready() -> void:
	_actor = get_node_or_null(actor_path)
	_ensure_inventory()
	_apply_starting_items()


func setup_for_smoke(smoke_database: InventoryDatabase, grid_inventory: bool = false, smoke_grid_size: Vector2i = Vector2i(4, 4)) -> void:
	database = smoke_database
	use_grid_inventory = grid_inventory
	grid_size = smoke_grid_size
	_ensure_inventory()


func get_actor_name() -> String:
	if _actor != null:
		return str(_actor.name)
	if owner != null:
		return str(owner.name)
	return str(get_parent().name) if get_parent() != null else str(name)


func get_database() -> InventoryDatabase:
	return database


func get_inventory() -> Inventory:
	_ensure_inventory()
	return _inventory


func request_add_item(item_id: String, amount: int = 1, properties: Dictionary = {}) -> int:
	_ensure_inventory()
	return _authority().apply_add_item(self, item_id, amount, properties)


func request_remove_item(item_id: String, amount: int = 1) -> int:
	_ensure_inventory()
	return _authority().apply_remove_item(self, item_id, amount)


func request_transfer_stack(stack_index: int, target_bridge: NexusInventoryBridgeComponent, amount: int = 1) -> int:
	_ensure_inventory()
	if target_bridge != null:
		target_bridge.get_inventory()
	return _authority().apply_transfer_stack(self, stack_index, target_bridge, amount)


func serialize_inventory() -> Dictionary:
	_ensure_inventory()
	if _inventory == null:
		return {}
	return _inventory.serialize()


func deserialize_inventory(data: Dictionary) -> void:
	_ensure_inventory()
	if _inventory == null:
		return
	_inventory.deserialize(data)


func _ensure_inventory() -> void:
	if _inventory != null:
		return
	if use_grid_inventory:
		var grid: GridInventory = ClassDB.instantiate("GridInventory")
		grid.set_size(grid_size)
		_inventory = grid
	else:
		_inventory = ClassDB.instantiate("Inventory")
	if _inventory != null:
		_inventory.database = database


func _apply_starting_items() -> void:
	if _starting_items_applied:
		return
	_starting_items_applied = true
	if _inventory == null or database == null or not _inventory.stacks.is_empty():
		return
	for index in range(starting_items.size()):
		var item_id := starting_items[index]
		var amount := 1
		if index < starting_item_amounts.size():
			amount = starting_item_amounts[index]
		if item_id.is_empty() or amount <= 0:
			continue
		_authority().apply_add_item(self, item_id, amount)


func _authority() -> GDScript:
	return ResourceLoader.load(AUTHORITY_SCRIPT_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as GDScript
