class_name GameManager
extends Node

signal status_changed(text: String)
signal stats_changed(money: int, day: int, population: int, daily_income: int)
signal day_advanced(day: int)

const STARTING_MONEY := 500
const STARTING_DAY := 1
const DAY_LENGTH_SECONDS := 6.0

var build_manager: BuildManager
var status_text := ""
var money := STARTING_MONEY
var day := STARTING_DAY
var population := 0
var daily_income := 0
var day_progress := 0.0

func setup() -> void:
	build_manager = null
	money = STARTING_MONEY
	day = STARTING_DAY
	population = 0
	daily_income = 0
	day_progress = 0.0
	set_process(true)
	_emit_stats()
	set_status("Select Road, House, Cafe, Tree, or Remove. Hover the grid to inspect a cell.")

func attach_build_manager(manager: BuildManager) -> void:
	build_manager = manager
	if not build_manager.placements_changed.is_connected(_on_placements_changed):
		build_manager.placements_changed.connect(_on_placements_changed)
	_recalculate_stats()

func _process(delta: float) -> void:
	if build_manager == null:
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return
	day_progress += delta
	if day_progress < DAY_LENGTH_SECONDS:
		return
	while day_progress >= DAY_LENGTH_SECONDS:
		day_progress -= DAY_LENGTH_SECONDS
		_advance_day()

func can_afford(amount: int) -> bool:
	return amount <= 0 or money >= amount

func spend_money(amount: int) -> bool:
	if amount <= 0:
		return true
	if not can_afford(amount):
		return false
	money -= amount
	_emit_stats()
	return true

func add_money(amount: int) -> void:
	if amount <= 0:
		return
	money += amount
	_emit_stats()

func set_status(text: String) -> void:
	if status_text == text:
		return
	status_text = text
	status_changed.emit(status_text)

func _advance_day() -> void:
	day += 1
	day_advanced.emit(day)
	if daily_income > 0:
		add_money(daily_income)
		set_status("Day %d. Active cafes earned %d coins." % [day, daily_income])
	else:
		_emit_stats()
		set_status("Day %d. No active cafe income yet." % day)

func _on_placements_changed() -> void:
	_recalculate_stats()

func _recalculate_stats() -> void:
	if build_manager == null:
		population = 0
		daily_income = 0
		_emit_stats()
		return
	var next_population := 0
	var next_income := 0
	for item in build_manager.get_placements():
		if not bool(item.get("active", true)):
			continue
		var data: PlaceableData = item["data"]
		if data == null:
			continue
		next_population += data.resident_capacity
		next_income += data.daily_income
	population = next_population
	daily_income = next_income
	_emit_stats()

func _emit_stats() -> void:
	stats_changed.emit(money, day, population, daily_income)
