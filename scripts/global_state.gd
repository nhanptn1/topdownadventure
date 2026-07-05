extends Node

const SAVE_PATH := "user://savegame.json"

var selected_character: String = "warrior"
var current_map_path: String = "res://scenes/map.tscn"

var player_level: int = 1
var player_xp: int = 0
var player_max_health: int = 100
var player_health: int = 100
var boss_defeated: bool = false
var defeated_gate_bosses: Array = []
var camera_zoom: float = 1.3

var storage: Dictionary = {}
var equipped := {"weapon": "", "armor": "", "accessory": ""}
var quick_slots := {"heal": "", "throwable": "", "buff": ""}


func storage_add(item_id: String, amount: int = 1) -> int:
	var cap: int = ItemDatabase.get_item(item_id).get("stack_size", 1)
	var current: int = storage.get(item_id, 0)
	var space: int = maxi(cap - current, 0)
	var added: int = clampi(amount, 0, space)
	if added > 0:
		storage[item_id] = current + added
	return added


func storage_remove(item_id: String, amount: int = 1) -> void:
	var current: int = storage.get(item_id, 0)
	var remaining := current - amount
	if remaining <= 0:
		storage.erase(item_id)
	else:
		storage[item_id] = remaining


func has_defeated_gate_boss(id: String) -> bool:
	return defeated_gate_bosses.has(id)


func save_game() -> void:
	var data := {
		"selected_character": selected_character,
		"current_map_path": current_map_path,
		"player_level": player_level,
		"player_xp": player_xp,
		"player_max_health": player_max_health,
		"player_health": player_health,
		"boss_defeated": boss_defeated,
		"defeated_gate_bosses": defeated_gate_bosses,
		"camera_zoom": camera_zoom,
		"storage": storage,
		"equipped": equipped,
		"quick_slots": quick_slots,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	var loaded_storage = parsed.get("storage", {})
	var loaded_equipped = parsed.get("equipped", {})
	var loaded_quick_slots = parsed.get("quick_slots", {})
	if typeof(loaded_storage) != TYPE_DICTIONARY \
			or typeof(loaded_equipped) != TYPE_DICTIONARY \
			or typeof(loaded_quick_slots) != TYPE_DICTIONARY:
		return false

	selected_character = parsed.get("selected_character", selected_character)
	current_map_path = parsed.get("current_map_path", current_map_path)
	player_level = int(parsed.get("player_level", player_level))
	player_xp = int(parsed.get("player_xp", player_xp))
	player_max_health = int(parsed.get("player_max_health", player_max_health))
	player_health = int(parsed.get("player_health", player_health))
	boss_defeated = parsed.get("boss_defeated", boss_defeated)
	var loaded_gate_bosses = parsed.get("defeated_gate_bosses", [])
	if typeof(loaded_gate_bosses) != TYPE_ARRAY:
		loaded_gate_bosses = []
	defeated_gate_bosses = []
	for entry in loaded_gate_bosses:
		if typeof(entry) == TYPE_STRING:
			defeated_gate_bosses.append(entry)
	camera_zoom = float(parsed.get("camera_zoom", camera_zoom))
	storage = {}
	for key in loaded_storage.keys():
		storage[key] = int(loaded_storage[key])
	equipped = loaded_equipped
	quick_slots = loaded_quick_slots
	return true
