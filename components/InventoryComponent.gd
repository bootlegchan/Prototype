class_name InventoryComponent
extends Node

# This node will act as the container for the actual item entity nodes.
var item_container: Node
var _entity_name: String = "Unnamed"

func initialize(entity_name: String, data: Dictionary) -> void:
	_entity_name = entity_name
	
	# Create a dedicated child node to hold the items.
	item_container = Node.new()
	item_container.name = "ItemContainer"
	add_child(item_container)
	
	print("InventoryComponent initialized for '%s'." % _entity_name)


# --- Public API ---

func add_item_entity(item_entity: Node) -> void:
	var logic_node = item_entity.get_node("EntityLogic")
	if not logic_node: return
	
	var item_comp = logic_node.get_component("ItemComponent")
	if not item_comp:
		push_warning("Attempted to add a non-item entity to '%s' inventory." % _entity_name)
		return

	if item_comp.stackable:
		for existing_item in item_container.get_children():
			var existing_logic_node = existing_item.get_node("EntityLogic")
			if not existing_logic_node: continue
			
			var existing_item_comp = existing_logic_node.get_component("ItemComponent")
			if existing_item_comp.display_name == item_comp.display_name:
				existing_item_comp.quantity += item_comp.quantity
				print("Merged %s into existing stack in '%s'. New total: %s" % [item_entity.name, _entity_name, existing_item_comp.quantity])
				item_entity.queue_free()
				return
	
	if item_entity.get_parent():
		item_entity.get_parent().remove_child(item_entity)
	
	item_container.add_child(item_entity)
	_set_item_in_inventory_state(item_entity, true)
	
	print("Added new item entity '%s' to '%s' inventory." % [item_entity.name, _entity_name])


func drop_item_entity(item_entity: Node, drop_position: Vector3) -> void:
	if item_entity.get_parent() != item_container:
		push_warning("Attempted to drop an item not in this inventory.")
		return
		
	item_container.remove_child(item_entity)
	get_tree().current_scene.add_child(item_entity)
	
	if item_entity is Node3D:
		item_entity.global_position = drop_position
		
	_set_item_in_inventory_state(item_entity, false)
	print("Dropped item '%s' from '%s' inventory into the world." % [item_entity.name, _entity_name])


# Helper function to disable physics and visibility for items in an inventory.
func _set_item_in_inventory_state(item_entity: Node, is_in_inventory: bool) -> void:
	if item_entity is CollisionObject3D:
		item_entity.set_process(!is_in_inventory)
		item_entity.set_physics_process(!is_in_inventory)
		
		for child in item_entity.get_children():
			if child is CollisionShape3D:
				child.disabled = is_in_inventory
				break
		
	var logic_node = item_entity.get_node_or_null("EntityLogic")
	if logic_node:
		var visual_comp = logic_node.get_component("VisualComponent")
		if visual_comp:
			# --- THIS IS THE FIX ---
			# Find the actual MeshInstance3D child within the VisualComponent.
			for child in visual_comp.get_children():
				if child is MeshInstance3D:
					child.visible = not is_in_inventory
					break # Stop after finding the first one.
