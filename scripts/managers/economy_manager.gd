class_name EconomyManager
extends Node

signal funds_changed(amount: int)
signal income_applied(amount: int)

var funds := 520

func reset_new_game() -> void:
	funds = 520
	funds_changed.emit(funds)

func can_afford(cost: int) -> bool:
	return funds >= cost

func spend(cost: int) -> bool:
	if not can_afford(cost):
		return false
	funds -= cost
	funds_changed.emit(funds)
	return true

func add_income(amount: int) -> void:
	funds += amount
	funds_changed.emit(funds)
	income_applied.emit(amount)

func export_state() -> Dictionary:
	return {"funds": funds}

func import_state(data: Dictionary) -> void:
	funds = int(data.get("funds", 520))
	funds_changed.emit(funds)
