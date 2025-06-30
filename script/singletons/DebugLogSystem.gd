# script/singletons/DebugLogSystem.gd
extends Node

func _ready() -> void:
	# --- DEBUG PRINT ---
	print("[DIAGNOSTIC] DebugLogSystem ready. Subscribing to events.")
	# --- END DEBUG PRINT ---
	EventSystem.subscribe("entity_record_created", Callable(self, "_on_entity_record_created"))
	EventSystem.subscribe("entity_staged", Callable(self, "_on_entity_staged"))
	EventSystem.subscribe("entity_unstaged", Callable(self, "_on_entity_unstaged"))
	EventSystem.subscribe("entity_destroyed", Callable(self, "_on_entity_destroyed"))
	EventSystem.subscribe("inventory_changed", Callable(self, "_on_inventory_changed"))
	# Add subscriptions for other events as needed
	EventSystem.subscribe("item_added_to_inventory", Callable(self, "_on_item_added")) # Example, adjust event name
	EventSystem.subscribe("item_removed_from_inventory", Callable(self, "_on_item_removed")) # Example, adjust event name


func _on_entity_record_created(payload: Dictionary) -> void:
	var instance_id = payload.get("instance_id", "N/A")
	print("[DEBUG LOG] Entity record created: '%s'." % instance_id)

func _on_entity_staged(payload: Dictionary) -> void:
	var instance_id = payload.get("instance_id", "N/A")
	var node = payload.get("node")
	print("[DEBUG LOG] An entity, '%s', has entered the world." % instance_id)

func _on_entity_unstaged(payload: Dictionary) -> void:
	var instance_id = payload.get("instance_id", "N/A")
	print("[DEBUG LOG] An entity, '%s', has left the world." % instance_id)

func _on_entity_destroyed(payload: Dictionary) -> void:
	var instance_id = payload.get("instance_id", "N/A")
	print("[DEBUG LOG] An entity, '%s', has been destroyed." % instance_id)

func _on_inventory_changed(payload: Dictionary) -> void:
	var owner_name = payload.get("owner_name", "N/A")
	var item_id = payload.get("item_id", "N/A")
	var new_quantity = payload.get("new_quantity", 0)
	print("[DEBUG LOG] Inventory changed for '%s': Item '%s', New Quantity: %s." % [owner_name, item_id, new_quantity])

# Add handlers for other relevant events

func _on_item_added(payload: Dictionary) -> void: # Example handler
	var owner_name = payload.get("owner_name", "N/A")
	var item_id = payload.get("item_id", "N/A")
	var quantity = payload.get("quantity", 0) # Assuming quantity is in payload
	print("[DEBUG LOG] Item added: %s of '%s' to '%s'." % [quantity, item_id, owner_name])

func _on_item_removed(payload: Dictionary) -> void: # Example handler
	var owner_name = payload.get("owner_name", "N/A")
	var item_id = payload.get("item_id", "N/A")
	var quantity = payload.get("quantity", 0) # Assuming quantity is in payload
	print("[DEBUG LOG] Item removed: %s of '%s' from '%s'." % [quantity, item_id, owner_name])
