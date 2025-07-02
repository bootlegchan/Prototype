extends Node

signal time_updated(date_info: Dictionary)
signal day_started(date_info: Dictionary)

var _seconds_per_minute: float = 1.0
var _calender_data: Dictionary = {}
var _current_second: float = 0.0
var current_minute: int = 0
var current_hour: int = 0
var current_day: int = 1
var current_month_index: int = 0
var current_year: int = 1
var _total_days_elapsed: int = 0
var _log_frequency: String = "hour"

func _ready() -> void:
	Debug.post("_ready called. Loading calendar and settings.", "TimeSystem")
	_load_calender()
	_load_settings()
	_initialize_total_days()
	Debug.post("_ready finished.", "TimeSystem")


func _load_settings() -> void:
	Debug.post("_load_settings called. Opening time settings file.", "TimeSystem")
	var file = FileAccess.open(Config.TIME_SETTINGS_FILE_PATH, FileAccess.READ)
	if not file:
		printerr("TimeSystem: Could not open time settings file at: ", Config.TIME_SETTINGS_FILE_PATH)
		return

	var json = JSON.new()
	var text = file.get_as_text()
	file.close()
	if json.parse(text) == OK:
		var settings = json.get_data()
		_seconds_per_minute = settings.get("seconds_per_minute", 1.0)
		current_hour = settings.get("start_hour", 8)
		current_minute = settings.get("start_minute", 0)
		current_day = settings.get("start_day", 1)
		current_month_index = settings.get("start_month_index", 0)
		current_year = settings.get("start_year", 1)
		_log_frequency = settings.get("log_frequency", "hour")
		Debug.post("Settings loaded: seconds_per_minute=%s, start_hour=%d, log_frequency=%s" % [_seconds_per_minute, current_hour, _log_frequency], "TimeSystem")
	else:
		printerr("TimeSystem: Failed to parse JSON for time settings. Error at line %d: %s" % [json.get_error_line(), json.get_error_message()])


func _load_calender() -> void:
	Debug.post("_load_calender called. Opening calendar file.", "TimeSystem")
	var file = FileAccess.open(Config.CALENDER_FILE_PATH, FileAccess.READ)
	if not file:
		printerr("TimeSystem: Could not open calendar file at: ", Config.CALENDER_FILE_PATH)
		return

	var json = JSON.new()
	var text = file.get_as_text()
	file.close()
	if json.parse(text) == OK:
		_calender_data = json.get_data()
		Debug.post("Calendar loaded with %s months and %s days in a week." % [_calender_data.get("months", []).size(), _calender_data.get("days_of_week", []).size()], "TimeSystem")
	else:
		printerr("TimeSystem: Failed to parse JSON for calendar. Error at line %d: %s" % [json.get_error_line(), json.get_error_message()])


func _initialize_total_days() -> void:
	Debug.post("_initialize_total_days called.", "TimeSystem")
	_total_days_elapsed = 0
	var months = _calender_data.get("months", [])
	if months.is_empty(): return
	var full_year_days = 0
	for month_data in months:
		full_year_days += month_data.get("length", 30)
	_total_days_elapsed += (current_year - 1) * full_year_days
	for i in range(current_month_index):
		_total_days_elapsed += months[i].get("length", 30)
	_total_days_elapsed += (current_day - 1)

	var date_info = get_current_date_info()
	var day_name = date_info.get("day_of_week_name", "Unknown")
	Debug.post("TimeSystem initialized. Total days elapsed: %s. Starting Date: %s" % [_total_days_elapsed, day_name], "TimeSystem")
	Debug.post("_initialize_total_days finished.", "TimeSystem")


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
	else:
		if _log_frequency == "minute":
			var date_info = get_current_date_info()
			Debug.post("[TIME] Minute advanced. Time is now %s, %02d:%02d." % [date_info.day_of_week_name, date_info.hour, date_info.minute], "TimeSystem")

	emit_signal("time_updated", get_current_date_info())


func _advance_hour() -> void:
	Debug.post("_advance_hour called.", "TimeSystem")
	current_hour += 1
	if current_hour >= 24:
		current_hour = 0
		_advance_day()

	if _log_frequency == "hour" or _log_frequency == "minute":
		var date_info = get_current_date_info()
		Debug.post("[TIME] Hour advanced. Time is now %s, %02d:00." % [date_info.day_of_week_name, date_info.hour], "TimeSystem")
	Debug.post("_advance_hour finished.", "TimeSystem")


func _advance_day() -> void:
	Debug.post("_advance_day called.", "TimeSystem")
	_total_days_elapsed += 1
	current_day += 1
	var month_info = get_current_month_info()
	if month_info and current_day > month_info.get("length", 30):
		current_day = 1
		_advance_month()
	emit_signal("day_started", get_current_date_info())
	Debug.post("day_started signal emitted.", "TimeSystem")


func _advance_month() -> void:
	Debug.post("_advance_month called.", "TimeSystem")
	current_month_index += 1
	var months = _calender_data.get("months", [])
	if not months.is_empty() and current_month_index >= months.size():
		current_month_index = 0
		current_year += 1
	Debug.post("_advance_month finished. Current month index: %d, Year: %d" % [current_month_index, current_year], "TimeSystem")


func get_current_date_info() -> Dictionary:
	var day_names = _calender_data.get("days_of_week", ["Undefined Day"])
	if day_names.is_empty(): return {}

	var day_of_week_index = _total_days_elapsed % day_names.size()
	return {
		"hour": current_hour,
		"minute": current_minute,
		"day": current_day,
		"month_name": get_current_month_name(),
		"year": current_year,
		"day_of_week_name": day_names[day_of_week_index]
	}


func get_current_month_info() -> Dictionary:
	var months = _calender_data.get("months", [])
	if months.is_empty() or current_month_index >= months.size():
		return {}
	return months[current_month_index]


func get_current_month_name() -> String:
	return get_current_month_info().get("name", "Error")
