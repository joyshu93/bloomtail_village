class_name GameDatabase
extends RefCounted

const PLACEABLE_PATHS := [
	"res://resources/placeables/road.tres",
	"res://resources/placeables/house.tres",
	"res://resources/placeables/cafe.tres",
	"res://resources/placeables/general_store.tres",
	"res://resources/placeables/workshop.tres",
	"res://resources/placeables/plaza.tres",
	"res://resources/placeables/flower.tres",
	"res://resources/placeables/tree.tres",
	"res://resources/placeables/bench.tres",
	"res://resources/placeables/fence.tres",
	"res://resources/placeables/street_lamp.tres"
]

const RESIDENT_PATHS := [
	"res://resources/residents/bibi.tres",
	"res://resources/residents/maru.tres",
	"res://resources/residents/nori.tres",
	"res://resources/residents/piko.tres",
	"res://resources/residents/rio.tres",
	"res://resources/residents/somi.tres",
	"res://resources/residents/toto.tres",
	"res://resources/residents/yuzu.tres"
]

static func load_placeables() -> Array[PlaceableData]:
	var results: Array[PlaceableData] = []
	for path in PLACEABLE_PATHS:
		var resource := load(path)
		if resource is PlaceableData:
			results.append(resource)
	return results

static func load_residents() -> Array[ResidentProfile]:
	var results: Array[ResidentProfile] = []
	for path in RESIDENT_PATHS:
		var resource := load(path)
		if resource is ResidentProfile:
			results.append(resource)
	return results
