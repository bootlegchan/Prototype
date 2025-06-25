extends Node

signal hour_changed(new_hour: int, new_minute: int)
signal current_minute_changed(new_hour: int, new_minute: int)
signal day_changed(new_day: int)
signal time_of_day_changed(new_time_of_day_id: String)

# These are now variables that will be loaded from a settings file.
var seconds_per_minute: float = 1.0
var _current_second: float = 0.0
var current_minute: int = 0
var current_hour: int = 8
var current_day: int = 1

# This could also be moved to a JSON definition in the future.
const TIME_OF_DAY_MAP: Dictionary = {
	"Night":   [0, 1, 2, 3, 4, 5],
	"Morning": [6, 7, 8, 9, 10, 11],
	"Afternoon": [12, 13, 14, 15, 16, 17],
	"Evening": [18, 19, 20, 21, 22, 23]
}
var _current_time_of_day_id: String = "Morning"


func _ready() -> void:
	_load_settings()


func _load_settings() -> void:
	var settings_path = Config.SETTINGS_PATH + "time_settings.json"
	var file = FileAccess.open(settings_path, FileAccess.READ)
	if not file:
		printerr("Could not open time_settings.json at '%s'. Using default values." % settings_path)
		return
		
	var settings_data = JSON.parse_string(file.get_as_text())
	
	seconds_per_minute = settings_data.get("seconds_per_minute", 1.0)
	current_hour = settings_data.get("start_hour", 8)
	current_minute = settings_data.get("start_minute", 0)
	
	print("TimeSystem settings loaded: %s sec/min, starting at %02d:%02d" % [seconds_per_minute, current_hour, current_minute])


func _process(delta: float) -> void:
	_current_second += delta
	if _current_second >= seconds_per_minute:
		_current_second = 0.0
		_advance_minute()


func _advance_minute() -> void:
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		_advance_hour()
	emit_signal("current_minute_changed", current_hour, current_minute)


func _advance_hour() -> void:
	current_hour += 1
	if current_hour >= 24:
		current_hour = 0
		_advance_day()
	emit_signal("hour_changed", current_hour, current_minute)
	_check_time_of_day_change()


func _advance_day() -> void:
	current_day += 1
	emit_signal("day_changed", current_day)


func _check_time_of_day_change() -> void:
	var new_time_of_day = get_time_of_day_for_hour(current_hour)
	if new_time_of_day != _current_time_of_day_id:
		_current_time_of_day_id = new_time_of_day
		emit_signal("time_of_day_changed", _current_time_of_day_id)


func get_formatted_time() -> String:
	return "%02d:%02d" % [current_hour, current_minute]


func get_current_time_of_day() -> String:
	return _current_time_of_day_id


func get_time_of_day_for_hour(hour: int) -> String:
	for key in TIME_OF_DAY_MAP:
		if hour in TIME_OF_DAY_MAP[key]:
			return key
	return "Night"
