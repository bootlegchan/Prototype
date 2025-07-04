class_name InventoryComponent
extends BaseComponent

var _items: Dictionary = {}

# This function is called automatically by the parent BaseComponent's initialize method.
func _load_data(data: Dictionary) -> void:
	Debug.post("_load_data called with data: %s" % data, "InventoryComponent on '%s'" % _entity_name)
	_items.clear()
	
	if data.has("saved_data"):
		_items = data.get("saved_data", {}).get("items", {}).duplicate(true)
		Debug.post("Loaded items from saved_data.", "InventoryComponent on '%s'" % _entity_name)
	elif data.has("initial_items"):
		var starting_items = data.get("initial_items", {})
		Debug.post("Loading initial items from definition: %s" % starting_items, "InventoryComponent on '%s'" % _entity_name)
		for item_id in starting_items:
			add_item(item_id, starting_items[item_id])
			
	Debug.post("_load_data finished. Items: %s" % _items, "InventoryComponent for '%s'" % _entity_name)

# We are replacing the parent's persistence function.
func get_persistent_data() -> Dictionary:
	Debug.post("get_persistent_data called. Saving items: %s" % _items, "InventoryComponent on '%s'" % _entity_name)
	return { "items": _items }

# --- Public API ---

func get_item_count(item_id: String) -> int:
	return _items.get(item_id, 0)

func add_item(item_id: String, quantity: int = 1):
	if not ItemRegistry.is_item_defined(item_id):
		push_warning("InventoryComponent on '%s': Attempted to add undefined item '%s'." % [_entity_name, item_id])
		return false
	
	var item_def = ItemRegistry.get_item_definition(item_id)
	var max_stack = item_def.get("max_stack_size", 1) if item_def.get("stackable", false) else 1
	
	if _items.has(item_id):
		_items[item_id] = min(_items[item_id] + quantity, max_stack)
	else:
		_items[item_id] = min(quantity, max_stack)
		
	EventSystem.emit_event("inventory_changed", {"owner_name": _entity_name, "item_id": item_id, "new_quantity": _items[item_id]})
	Debug.post("Added %s of '%s'. New total: %s" % [quantity, item_id, _items[item_id]], "InventoryComponent on '%s'" % _entity_name)
	return true

func remove_item(item_id: String, quantity: int = 1):
	if not _items.has(item_id):
		push_warning("InventoryComponent on '%s': Attempted to remove item '%s', which does not exist in inventory." % [_entity_name, item_id])
		return false
		
	_items[item_id] -= quantity
	
	if _items[item_id] <= 0:
		_items.erase(item_id)

	EventSystem.emit_event("inventory_changed", {"owner_name": _entity_name, "item_id": item_id, "new_quantity": get_item_count(item_id)})
	return true

static func transfer_item(from_inventory, to_inventory, item_id: String, quantity: int):
	if from_inventory.get_item_count(item_id) >= quantity:
		if from_inventory.remove_item(item_id, quantity):
			to_inventory.add_item(item_id, quantity)
			Debug.post("Transferred %s '%s' from '%s' to '%s'." % [quantity, item_id, from_inventory._entity_name, to_inventory._entity_name], "InventoryComponent")
	else:
		Debug.post("Transfer failed. Not enough '%s' in source inventory." % item_id, "InventoryComponent")
