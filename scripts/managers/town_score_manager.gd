class_name TownScoreManager
extends Node

signal scores_changed(scores: Dictionary, comment: String)

var scores := {
	"coziness": 0,
	"nature": 0,
	"convenience": 0,
	"atmosphere": 0
}

func recalculate(build_manager: BuildManager, resident_manager: ResidentManager) -> void:
	scores = build_manager.get_base_scores()
	var happiness_bonus := int(round(float(resident_manager.get_average_happiness()) / 20.0))
	scores["coziness"] += happiness_bonus
	scores["atmosphere"] += happiness_bonus
	scores_changed.emit(scores.duplicate(true), get_summary_comment())

func get_summary_comment() -> String:
	var highest_key := "coziness"
	for key in scores.keys():
		if scores[key] > scores[highest_key]:
			highest_key = key
	match highest_key:
		"nature":
			return "Nature is thriving, but a few more social spots could help."
		"convenience":
			return "The village feels easy to live in and move through."
		"atmosphere":
			return "The atmosphere is charming and full of little moments."
		_:
			return "The streets already feel snug and welcoming."

func export_state() -> Dictionary:
	return {"scores": scores}

func import_state(data: Dictionary) -> void:
	var imported_scores: Dictionary = data.get("scores", {})
	scores = {
		"coziness": int(imported_scores.get("coziness", 0)),
		"nature": int(imported_scores.get("nature", 0)),
		"convenience": int(imported_scores.get("convenience", 0)),
		"atmosphere": int(imported_scores.get("atmosphere", imported_scores.get("vibe", 0)))
	}
	scores_changed.emit(scores.duplicate(true), get_summary_comment())
