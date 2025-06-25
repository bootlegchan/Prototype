extends Node

signal hour_changed(new_hour: int, new_minute: int)
signal current_minute_changed(new_hour: int, new_minute: int)
signal day_changed(new_day: int, new_month_name: String, new_year: int)

var _seconds_per_minute: float = 1.0
var _calender_data: Dictionary = {}
var _current_second: float = 0.0
var current_minute: int = 0
var current_hour: int = 0
var current_day: int = 1
var current_month_index: int = 0
var current_year: int = 1

var _total_days_elapsed: int = 0


func _ready() -> void:
	_load_calender()
	_load_settings()
	_initialize_total_days()


func _load_settings() -> void:
	var file = FileAccess.open(Config.TIME_SETTINGS_FILE_PATH, FileAccess.READ)
	if not file:
		return
	var settings = JSON.parse_string(file.get_as_text())
	_seconds_per_minute = settings.get("seconds_per_minute", 1.0)
	current_hour = settings.get("start_hour", 8)
	current_minute = settings.get("start_minute", 0)
	current_day = settings.get("start_day", 1)
	current_month_index = settings.get("start_month_index", 0)
	current_year = settings.get("start_year", 1)


func _load_calender() -> void:
	var file = FileAccess.open(Config.CALENDER_FILE_PATH, FileAccess.READ)
	if not file:
		return
	_calender_data = JSON.parse_string(file.get_as_text())


func _initialize_total_days() -> void:
	_total_days_elapsed = 0
	var months = _calender_data.get("months", [])
	if months.is_empty():
		return
	
	var full_year_days = 0
	for month_data in months:
		full_year_days += month_data.get("length", 30)
	_total_days_elapsed += (current_year - 1) * full_year_days
	
	for i in range(current_month_index):
		_total_days_elapsed += months[i].get("length", 30)
		
	_total_days_elapsed += (current_day - 1)
	
	print("TimeSystem initialized. Total days elapsed: %s. Starting Date: %s" % [_total_days_elapsed, get_current_date_info().day_of_week_name])


func _process(delta: float) -> void:
	_current_second += delta
	if _current_second >= _seconds_per_minute:
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


func _advance_day() -> void:
	_total_days_elapsed += 1
	current_day += 1
	var month_info = get_current_month_info()
	if month_info and current_day > month_info.get("length", 30):
		current_day = 1
		_advance_month()
	emit_signal("day_changed", current_day, get_current_month_name(), current_year)


func _advance_month() -> void:
	current_month_index += 1
	var months = _calender_data.get("months", [])
	if not months.is_empty() and current_month_index >= months.size():
		current_month_index = 0
		current_year += 1


# --- Public API ---
func get_current_date_info() -> Dictionary:
	var day_of_week_index = _total_days_elapsed % 7
	var day_names = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
	
	return {
		"hour": current_hour, "minute": current_minute,
		"day": current_day, "month_name": get_current_month_name(), "year": current_year,
		"day_of_week_name": day_names[day_of_week_index]
	}


func get_current_month_info() -> Dictionary:
	var months = _calender_data.get("months", [])
	if months.is_empty() or current_month_index >= months.size():
		return {}
	return months[current_month_index]


func get_current_month_name() -> String:
	return get_current_month_info().get("name", "Error")
