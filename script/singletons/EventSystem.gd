extends Node

var _subscribers: Dictionary = {}

func _ready() -> void:
	Debug.post("EventSystem ready.", "EventSystem")
	pass

func subscribe(event_name: String, subscriber: Callable) -> void:
	if not _subscribers.has(event_name):
		_subscribers[event_name] = []
	if not subscriber in _subscribers[event_name]:
		_subscribers[event_name].append(subscriber)
		Debug.post("Subscriber added for event '%s': %s" % [event_name, subscriber], "EventSystem")
	else:
		Debug.post("Subscriber already exists for event '%s': %s" % [event_name, subscriber], "EventSystem")


func unsubscribe(event_name: String, subscriber: Callable) -> void:
	if _subscribers.has(event_name) and subscriber in _subscribers[event_name]:
		_subscribers[event_name].erase(subscriber)
		Debug.post("Subscriber removed for event '%s': %s" % [event_name, subscriber], "EventSystem")


func emit_event(event_name: String, payload: Dictionary = {}) -> void:
	if _subscribers.has(event_name):
		# Iterate over a copy of the list in case subscribers unsubscribe during iteration
		var current_subscribers = _subscribers[event_name].duplicate()
		Debug.post("Emitting event '%s' with payload: %s. Subscribers: %d" % [event_name, payload, current_subscribers.size()], "EventSystem")
		for subscriber in current_subscribers:
			if subscriber.is_valid(): # Ensure the callable is still valid
				subscriber.call(payload)
			else:
				push_warning("[EVENT] Invalid subscriber found for event '%s', removing." % event_name)
				_subscribers[event_name].erase(subscriber)
