class_name GameManager
extends Node

signal status_changed(text: String)

var status_text := ""

func setup() -> void:
	set_status("Select Road, House, Cafe, Tree, or Remove. Hover the grid to inspect a cell.")

func set_status(text: String) -> void:
	if status_text == text:
		return
	status_text = text
	status_changed.emit(status_text)
