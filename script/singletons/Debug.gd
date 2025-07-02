extends Node

var _active_log_sources: Dictionary = {}

func _ready() -> void:
	_load_config()
	post("Debug System Initialized. Active sources: %s" % str(_active_log_sources.keys()), "Debug")
	_subscribe_to_events()

func _load_config() -> void:
	var file = FileAccess.open(Config.DEBUG_SETTINGS_FILE_PATH, FileAccess.READ)
	if not file:
		printerr("FATAL: Could not open debug settings file at: ", Config.DEBUG_SETTINGS_FILE_PATH)
		return
	
	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(text) != OK:
		printerr("FATAL: Could not parse debug_settings.json. Error: %s at line %s" % [json.get_error_message(), json.get_error_line()])
		return
		
	var config_data: Dictionary = json.get_data()
	for source in config_data:
		if config_data[source] == true:
			_active_log_sources[source] = true

# --- THIS IS THE FIX ---
# The global logging function is now named 'post' to avoid collision with the built-in log().
func post(message: String, source_system: String) -> void:
	if _active_log_sources.has(source_system):
		print("[%s] %s" % [source_system, message])
# --- END OF FIX ---
		
func _subscribe_to_events() -> void:
	post("Subscribing to game events.", "Debug")
	EventSystem.subscribe("entity_record_created", Callable(self, "_on_entity_record_created"))
	EventSystem.subscribe("entity_staged", Callable(self, "_on_entity_staged"))
	EventSystem.subscribe("entity_unstaged", Callable(self, "_on_entity_unstaged"))
	EventSystem.subscribe("entity_destroyed", Callable(self, "_on_entity_destroyed"))
	EventSystem.subscribe("inventory_changed", Callable(self, "_on_inventory_changed"))
	EventSystem.subscribe("item_added_to_inventory", Callable(self, "_on_item_added"))
	EventSystem.subscribe("item_removed_from_inventory", Callable(self, "_on_item_removed"))

# --- All internal calls are also changed to 'post' ---
func _on_entity_record_created(payload: Dictionary) -> void:
	var instance_id = payload.get("instance_id", "N/A")
	post("Entity record created: '%s'." % instance_id, "EntityManager")

func _on_entity_staged(payload: Dictionary) -> void:
	var instance_id = payload.get("instance_id", "N/A")
	post("An entity, '%s', has entered the world." % instance_id, "EntityManager")

func _on_entity_unstaged(payload: Dictionary) -> void:
	var instance_id = payload.get("instance_id", "N/A")
	post("An entity, '%s', has left the world." % instance_id, "EntityManager")

func _on_entity_destroyed(payload: Dictionary) -> void:
	var instance_id = payload.get("instance_id", "N/A")
	post("An entity, '%s', has been destroyed." % instance_id, "EntityManager")

func _on_inventory_changed(payload: Dictionary) -> void:
	var owner_name = payload.get("owner_name", "N/A")
	var item_id = payload.get("item_id", "N/A")
	var new_quantity = payload.get("new_quantity", 0)
	post("Inventory changed for '%s': Item '%s', New Quantity: %s." % [owner_name, item_id, new_quantity], "InventoryComponent")

func _on_item_added(payload: Dictionary) -> void:
	var owner_name = payload.get("owner_name", "N/A")
	var item_id = payload.get("item_id", "N/A")
	var quantity = payload.get("quantity", 0)
	post("Item added: %s of '%s' to '%s'." % [quantity, item_id, owner_name], "InventoryComponent")

func _on_item_removed(payload: Dictionary) -> void:
	var owner_name = payload.get("owner_name", "N/A")
	var item_id = payload.get("item_id", "N/A")
	var quantity = payload.get("quantity", 0)
	post("Item removed: %s of '%s' from '%s'." % [quantity, item_id, owner_name], "InventoryComponent")
