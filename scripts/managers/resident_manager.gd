class_name ResidentManager
extends Node

signal residents_changed(residents: Array[Dictionary])

const RESIDENT_PATHS := [
	"res://resources/residents/miso.tres",
	"res://resources/residents/pico.tres",
	"res://resources/residents/mori.tres",
	"res://resources/residents/nabi.tres"
]

var build_manager: BuildManager
var game_manager: GameManager
var resident_pool: Array[ResidentData] = []
var residents: Array[Dictionary] = []

func setup(builds: BuildManager, game: GameManager) -> void:
	build_manager = builds
	game_manager = game
	_load_pool()
	if not build_manager.placements_changed.is_connected(_on_world_changed):
		build_manager.placements_changed.connect(_on_world_changed)
	if not game_manager.day_advanced.is_connected(_on_day_advanced):
		game_manager.day_advanced.connect(_on_day_advanced)
	refresh()

func refresh() -> void:
	_sync_residents_to_houses()
	_update_reactions()
	residents_changed.emit(get_residents())

func get_residents() -> Array[Dictionary]:
	return residents.duplicate(true)

func _on_world_changed() -> void:
	refresh()

func _on_day_advanced(_day: int) -> void:
	_update_reactions()
	residents_changed.emit(get_residents())

func _load_pool() -> void:
	resident_pool.clear()
	for path in RESIDENT_PATHS:
		var resource: Resource = load(path)
		if resource is ResidentData:
			var data: ResidentData = resource
			resident_pool.append(data)

func _sync_residents_to_houses() -> void:
	var homes: Array[Vector2i] = build_manager.get_active_house_cells()
	var next_residents: Array[Dictionary] = []
	var limit: int = mini(homes.size(), resident_pool.size())
	for i in range(limit):
		var data: ResidentData = resident_pool[i]
		var home: Vector2i = homes[i]
		next_residents.append({
			"id": data.id,
			"name": data.display_name,
			"species": data.species,
			"mood_tag": data.mood_tag,
			"preferred_tag": data.preferred_tag,
			"home": home,
			"state": "neutral",
			"happiness": 50,
			"reaction": ""
		})
	residents = next_residents

func _update_reactions() -> void:
	for resident in residents:
		var home: Vector2i = resident["home"]
		var preferred_tag: String = String(resident["preferred_tag"])
		var likes_preference: bool = build_manager.count_tag_near(home, preferred_tag, 2, true) > 0
		var nearby_road: bool = build_manager.count_tag_near(home, "road", 1, false) > 0
		var state: String = "neutral"
		var happiness: int = 50
		var reaction: String = _neutral_reaction(resident)
		if not nearby_road:
			state = "unhappy"
			happiness = 30
			reaction = "Getting around feels awkward without a nearby road."
		elif likes_preference:
			state = "happy"
			happiness = 74
			reaction = _preferred_reaction(resident)
		elif preferred_tag == "cafe":
			state = "neutral"
			happiness = 48
			reaction = "A cozy cafe nearby would make this place feel lively."
		elif preferred_tag == "tree":
			state = "neutral"
			happiness = 46
			reaction = "I would love a few more trees around the house."
		elif preferred_tag == "road":
			state = "neutral"
			happiness = 52
			reaction = "A tidy little road makes the village feel easier to cross."
		resident["state"] = state
		resident["happiness"] = happiness
		resident["reaction"] = reaction

func _preferred_reaction(resident: Dictionary) -> String:
	match String(resident["preferred_tag"]):
		"tree":
			return "These trees make the village feel calm and tucked away."
		"cafe":
			return "I love having a cafe nearby. It makes mornings feel warm."
		"road":
			return "These roads make it easy to wander around town."
		_:
			return "This part of town suits me nicely."

func _neutral_reaction(resident: Dictionary) -> String:
	match String(resident["mood_tag"]):
		"gentle":
			return "It is quiet here. I think I could settle in."
		"chatty":
			return "This village is starting to feel lively."
		"calm":
			return "A peaceful corner like this is enough for me."
		"curious":
			return "I wonder what this little village will become."
		_:
			return "This village has potential."
