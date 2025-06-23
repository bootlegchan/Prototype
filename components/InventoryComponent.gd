class_name InventoryComponent
extends Node

# An array of dictionaries, where each dictionary represents an item slot.
# Example: { "item_id": "general/apple", "quantity": 5 }
var items: Array[Dictionary] = []
var _entity_name: String = "Unnamed"

func initialize(entity_name: String, data: Dictionary) -> void:
	_entity_name = entity_name
	# We could potentially initialize with starting items from JSON here if needed.
	print("InventoryComponent initialized for '%s'." % _entity_name)


# --- Public API ---

func add_item(item_id: String, quantity: int = 1) -> bool:
	if not ItemRegistry.is_item_defined(item_id):
		push_warning("Attempted to add undefined item '%s' to '%s'." % [item_id, _entity_name])
		return false
	
	var item_def = ItemRegistry.get_item_definition(item_id)
	
	# If the item is stackable, try to add to an existing stack first.
	if item_def.get("stackable", false):
		for slot in items:
			if slot["item_id"] == item_id:
				slot["quantity"] += quantity
				print("Added %s %s(s) to existing stack in '%s' inventory. New total: %s" % [quantity, item_id, _entity_name, slot["quantity"]])
				return true
	
	# If no existing stack, or not stackable, create a new slot.
	var new_slot = {
		"item_id": item_id,
		"quantity": quantity
	}
	items.append(new_slot)
	print("Added %s %s(s) as new item to '%s' inventory." % [quantity, item_id, _entity_name])
	return true


func remove_item(item_id: String, quantity: int = 1) -> bool:
	# Iterate backwards so we can safely remove items.
	for i in range(items.size() - 1, -1, -1):
		var slot = items[i]
		if slot["item_id"] == item_id:
			slot["quantity"] -= quantity
			print("Removed %s %s(s) from '%s' inventory. Remaining: %s" % [quantity, item_id, _entity_name, slot["quantity"]])
			
			# If the stack is empty, remove the slot entirely.
			if slot["quantity"] <= 0:
				items.remove_at(i)
				print("Item slot '%s' is now empty and was removed from '%s'." % [item_id, _entity_name])
			return true
			
	push_warning("Could not find item '%s' to remove from '%s'." % [item_id, _entity_name])
	return false


func get_item_count(item_id: String) -> int:
	var total = 0
	for slot in items:
		if slot["item_id"] == item_id:
			total += slot["quantity"]
	return total
