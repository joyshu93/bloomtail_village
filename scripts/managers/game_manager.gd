class_name GameManager
extends Node

signal day_passed(day: int)
signal clock_changed(day: int, season_name: String, speed: int, paused: bool)
signal notification_pushed(text: String)

const SEASONS := ["Spring", "Summer", "Autumn", "Winter"]
const DAYS_PER_SEASON := 7
const SECONDS_PER_DAY := 14.0

var current_day := 1
var speed := 1
var paused := false
var _elapsed := 0.0

func _process(delta: float) -> void:
	if paused or speed <= 0:
		return
	_elapsed += delta * float(speed)
	if _elapsed >= SECONDS_PER_DAY:
		_elapsed -= SECONDS_PER_DAY
		current_day += 1
		day_passed.emit(current_day)
		_emit_clock()

func start_new_game() -> void:
	current_day = 1
	speed = 1
	paused = false
	_elapsed = 0.0
	_emit_clock()
	push_notification("A gentle new village day has begun.")

func set_speed(new_speed: int) -> void:
	if new_speed <= 0:
		paused = true
	else:
		paused = false
		speed = new_speed
	_emit_clock()

func toggle_pause() -> void:
	paused = not paused
	_emit_clock()

func get_season_name(day := current_day) -> String:
	var index := int(((day - 1) / DAYS_PER_SEASON) % SEASONS.size())
	return SEASONS[index]

func get_day_in_season(day := current_day) -> int:
	return int(((day - 1) % DAYS_PER_SEASON) + 1)

func export_state() -> Dictionary:
	return {
		"current_day": current_day,
		"speed": speed,
		"paused": paused,
		"elapsed": _elapsed
	}

func import_state(data: Dictionary) -> void:
	current_day = int(data.get("current_day", 1))
	speed = int(data.get("speed", 1))
	paused = bool(data.get("paused", false))
	_elapsed = float(data.get("elapsed", 0.0))
	_emit_clock()

func push_notification(text: String) -> void:
	notification_pushed.emit(text)

func _emit_clock() -> void:
	clock_changed.emit(current_day, get_season_name(), speed, paused)
