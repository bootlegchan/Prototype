extends Node

# A dictionary where the key is the event name (String)
# and the value is an Array of connected Callables.
var _subscribers: Dictionary = {}

# --- Public API ---

# Any system can call this to broadcast an event.
# The payload is an optional dictionary for carrying data.
func emit_event(event_name: String, payload: Dictionary = {}) -> void:
	# --- Centralized Logging ---
	# Every single event passes through here, giving us a perfect debug log.
	print("[EVENT] %s: %s" % [event_name, payload])
	
	if _subscribers.has(event_name):
		# We make a copy of the array in case a subscriber tries to unsubscribe
		# while we are iterating, which would modify the original array.
		var listeners = _subscribers[event_name].duplicate()
		for callable in listeners:
			# Call the listener's function, passing the payload.
			# Using call_deferred makes the system more robust against cascading events.
			callable.call_deferred(payload)


# Any system can call this to register interest in an event.
# The callable should be a function that accepts one argument (the payload dictionary).
func subscribe(event_name: String, callable: Callable) -> void:
	if not callable.is_valid():
		printerr("Attempted to subscribe with an invalid callable for event: ", event_name)
		return

	if not _subscribers.has(event_name):
		_subscribers[event_name] = []
	
	# Add the function to the list of listeners for this event.
	_subscribers[event_name].append(callable)


# (Optional but good practice) A way for systems to unsubscribe.
func unsubscribe(event_name: String, callable: Callable) -> void:
	if _subscribers.has(event_name):
		if _subscribers[event_name].has(callable):
			_subscribers[event_name].erase(callable)
