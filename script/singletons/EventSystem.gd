# script/singletons/EventSystem.gd
extends Node

var _subscribers: Dictionary = {}

func _ready() -> void:
	# --- DEBUG PRINT ---
	print("[DIAGNOSTIC] EventSystem ready.")
	# --- END DEBUG PRINT ---
	pass

func subscribe(event_name: String, subscriber: Callable) -> void:
	if not _subscribers.has(event_name):
		_subscribers[event_name] = []
	if not subscriber in _subscribers[event_name]:
		_subscribers[event_name].append(subscriber)
		# --- DEBUG PRINT ---
		print("[EVENT] Subscriber added for event '%s': %s" % [event_name, subscriber])
		# --- END DEBUG PRINT ---
	else:
		# --- DEBUG PRINT ---
		print("[EVENT] Subscriber already exists for event '%s': %s" % [event_name, subscriber])
		# --- END DEBUG PRINT ---


func unsubscribe(event_name: String, subscriber: Callable) -> void:
	if _subscribers.has(event_name) and subscriber in _subscribers[event_name]:
		_subscribers[event_name].erase(subscriber)
		# --- DEBUG PRINT ---
		print("[EVENT] Subscriber removed for event '%s': %s" % [event_name, subscriber])
		# --- END DEBUG PRINT ---


func emit_event(event_name: String, payload: Dictionary = {}) -> void:
	if _subscribers.has(event_name):
		# Iterate over a copy of the list in case subscribers unsubscribe during iteration
		var current_subscribers = _subscribers[event_name].duplicate()
		# --- DEBUG PRINT ---
		print("[EVENT] Emitting event '%s' with payload: %s. Subscribers: %d" % [event_name, payload, current_subscribers.size()])
		# --- END DEBUG PRINT ---
		for subscriber in current_subscribers:
			if subscriber.is_valid(): # Ensure the callable is still valid
				subscriber.call(payload)
			else:
				# --- DEBUG PRINT ---
				push_warning("[EVENT] Invalid subscriber found for event '%s', removing." % event_name)
				# --- END DEBUG PRINT ---
				_subscribers[event_name].erase(subscriber)
