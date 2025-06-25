class_name InventoryComponent
extends Node

var _items: Dictionary = {} # Key: item_id, Value: quantity
var _entity_name: String = "Unnamed"

func initialize(entity_name: String, data: Dictionary) -> void:
	_entity_name = entity_name
	_items.clear()
	
	if data.has("saved_data"):
		# Re-hydrate from saved data
		var saved_items = data["saved_data"].get("items", {})
		_items = saved_items.duplicate(true)
		print("InventoryComponent for '%s' re-hydrated with items: %s" % [_entity_name, _items])
	else:
		# Initialize fresh
		print("InventoryComponent initialized for '%s'." % _entity_name)

func get_persistent_data() -> Dictionary:
	return { "items": _items }

# --- Public API ---

func add_item(item_id: String, quantity: int = 1) -> bool:
	if not ItemRegistry.is_item_defined(item_id):
		push_warning("Attempted to add undefined item '%s'." % item_id)
		return false
	
	var item_def = ItemRegistry.get_item_definition(item_id)
	var max_stack = item_def.get("max_stack_size", 1) if item_def.get("stackable") else 1

	if _items.has(item_id):
		_items[item_id] = min(_items[item_id] + quantity, max_stack)
	else:
		_items[item_id] = min(quantity, max_stack)
	
	EventSystem.emit_event("inventory_changed", {"owner_name": _entity_name, "item_id": item_id, "new_quantity": _items[item_id]})
	print("Added %s of '%s' to '%s'. New total: %s" % [quantity, item_id, _entity_name, _items[item_id]])
	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	if not _items.has(item_id):
		push_warning("Attempted to remove item '%s', which does not exist in inventory." % item_id)
		return false
		
	_items[item_id] -= quantity
	
	if _items[item_id] <= 0:
		_items.erase(item_id)
		print("Removed all '%s' from '%s'." % [item_id, _entity_name])
	else:
		print("Removed %s of '%s' from '%s'. New total: %s" % [quantity, item_id, _entity_name, _items[item_id]])

	EventSystem.emit_event("inventory_changed", {"owner_name": _entity_name, "item_id": item_id, "new_quantity": get_item_count(item_id)})
	return true

func get_item_count(item_id: String) -> int:
	return _items.get(item_id, 0)

# --- NEW FUNCTION for transfers ---
static func transfer_item(from_inventory, to_inventory, item_id: String, quantity: int) -> void:
	if from_inventory.get_item_count(item_id) >= quantity:
		if from_inventory.remove_item(item_id, quantity):
			to_inventory.add_item(item_id, quantity)
			print("Transferred %s of '%s' from '%s' to '%s'." % [quantity, item_id, from_inventory._entity_name, to_inventory._entity_name])
	else:
		print("Transfer failed. Not enough '%s' in source inventory." % item_id)
