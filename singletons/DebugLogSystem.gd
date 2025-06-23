extends Node

func _ready() -> void:
	# We must wait a frame to ensure the EventSystem is ready to accept subscriptions.
	call_deferred("subscribe_to_events")


func subscribe_to_events() -> void:
	# --- THIS IS THE FIX ---
	# The second argument to Callable should be the function name as a StringName.
	EventSystem.subscribe("item_added_to_inventory", Callable(self, "_on_item_added"))
	EventSystem.subscribe("entity_staged", Callable(self, "_on_entity_staged"))


# --- Callback Functions ---

func _on_item_added(payload: Dictionary) -> void:
	var entity_name = payload.get("owner_name", "Unknown")
	var item_id = payload.get("item_id", "unknown_item")
	var quantity = payload.get("quantity", 0)
	print("[DEBUG LOG] Item Added: %s received %s of %s." % [entity_name, quantity, item_id])


func _on_entity_staged(payload: Dictionary) -> void:
	var instance_id = payload.get("instance_id", "unknown_instance")
	print("[DEBUG LOG] An entity, '%s', has entered the world." % instance_id)
