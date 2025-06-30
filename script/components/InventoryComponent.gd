# script/components/InventoryComponent.gd
class_name InventoryComponent
extends BaseComponent

var _items: Dictionary = {} # Key: item_id, Value: quantity

# This function is called automatically by the parent BaseComponent's initialize method.
# It contains only the logic specific to loading inventory data.
func _load_data(data: Dictionary) -> void:
	_items.clear()
	
	if data.has("saved_data"):
		_items = data.get("saved_data", {}).get("items", {}).duplicate(true)
	elif data.has("initial_items"):
		var starting_items = data.get("initial_items", {})
		for item_id in starting_items:
			add_item(item_id, starting_items[item_id])
			
	print("InventoryComponent for '%s' initialized with items: %s" % [_entity_name, _items])

# We are replacing the parent's persistence function.
func get_persistent_data() -> Dictionary:
	return { "items": _items }

# --- Public API ---

func get_item_count(item_id: String) -> int:
	return _items.get(item_id, 0)

func add_item(item_id: String, quantity: int = 1):
	if not ItemRegistry.is_item_defined(item_id): return
	var item_def = ItemRegistry.get_item_definition(item_id)
	var max_stack = item_def.get("max_stack_size", 1) if item_def.get("stackable", false) else 1
	
	if _items.has(item_id):
		_items[item_id] = min(_items[item_id] + quantity, max_stack)
	else:
		_items[item_id] = min(quantity, max_stack)
		
	EventSystem.emit_event("inventory_changed", {"owner_name": _entity_name, "item_id": item_id, "new_quantity": _items[item_id]})

func remove_item(item_id: String, quantity: int = 1):
	if not _items.has(item_id): return
	_items[item_id] -= quantity
	
	if _items[item_id] <= 0:
		_items.erase(item_id)
		
	EventSystem.emit_event("inventory_changed", {"owner_name": _entity_name, "item_id": item_id, "new_quantity": get_item_count(item_id)})

static func transfer_item(from_inventory, to_inventory, item_id: String, quantity: int):
	if from_inventory.get_item_count(item_id) >= quantity:
		from_inventory.remove_item(item_id, quantity)
		to_inventory.add_item(item_id, quantity)
		print("Transferred %s '%s' from '%s' to '%s'." % [quantity, item_id, from_inventory._entity_name, to_inventory._entity_name])
