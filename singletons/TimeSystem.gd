# The line "class_name TimeSystem" has been REMOVED from the top of this file.
extends Node

# --- Signals ---
signal hour_changed(new_hour: int)
signal day_changed(new_day: int)
signal time_of_day_changed(new_time_of_day_id: String)


# --- Configuration ---
# --- THIS IS THE CHANGE ---
# A value of 0.1 means 10 game minutes will pass every real-world second.
# An in-game hour will now pass every 6 real-world seconds.
const SECONDS_PER_MINUTE: float = 0.1


# --- State ---
var _current_second: float = 0.0
var current_minute: int = 0
var current_hour: int = 8
var current_day: int = 1

const TIME_OF_DAY_MAP: Dictionary = {
	"Night":   [0, 1, 2, 3, 4, 5],
	"Morning": [6, 7, 8, 9, 10, 11],
	"Afternoon": [12, 13, 14, 15, 16, 17],
	"Evening": [18, 19, 20, 21, 22, 23]
}
var _current_time_of_day_id: String = "Morning"


# --- Godot Lifecycle Functions ---
func _process(delta: float) -> void:
	_current_second += delta
	
	if _current_second >= SECONDS_PER_MINUTE:
		_current_second = 0.0
		_advance_minute()


# --- Private Helper Functions ---
func _advance_minute() -> void:
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		_advance_hour()


func _advance_hour() -> void:
	current_hour += 1
	if current_hour >= 24:
		current_hour = 0
		_advance_day()
	
	emit_signal("hour_changed", current_hour)
	_check_time_of_day_change()


func _advance_day() -> void:
	current_day += 1
	emit_signal("day_changed", current_day)


func _check_time_of_day_change() -> void:
	var new_time_of_day = get_time_of_day_for_hour(current_hour)
	if new_time_of_day != _current_time_of_day_id:
		_current_time_of_day_id = new_time_of_day
		emit_signal("time_of_day_changed", _current_time_of_day_id)


# --- Public API ---
func get_formatted_time() -> String:
	return "%02d:%02d" % [current_hour, current_minute]

func get_current_time_of_day() -> String:
	return _current_time_of_day_id

func get_time_of_day_for_hour(hour: int) -> String:
	for key in TIME_OF_DAY_MAP:
		if hour in TIME_OF_DAY_MAP[key]:
			return key
	return "Night"
