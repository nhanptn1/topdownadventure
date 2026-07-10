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
var auto_attack_enabled: bool = false
var ng_plus_level: int = 0

var storage: Dictionary = {}
var equipped := {"weapon": "", "armor": "", "accessory": ""}
var quick_slots := {"heal": "", "throwable": "", "buff": ""}
# item_id -> {stat_key: rolled_value}. One remembered roll per id (not per
# copy -- gear has never been held/equipped as distinguishable individual
# copies in this game), always the best roll seen so far for that id.
var rolled_stats: Dictionary = {}


func get_rolled_stats(item_id: String) -> Dictionary:
	return rolled_stats.get(item_id, ItemDatabase.get_item(item_id).get("stats", {}))


func get_rolled_stat(item_id: String, stat_name: String) -> float:
	return get_rolled_stats(item_id).get(stat_name, 0)


func difficulty_multiplier() -> float:
	return 1.0 + 0.5 * ng_plus_level


# Keeps player_level/xp/storage/equipped/quick_slots -- that's the point of a
# replay. Resets map/gate progress so the whole world (including the final
# boss) needs re-clearing, now scaled up via difficulty_multiplier().
func start_new_game_plus() -> void:
	ng_plus_level += 1
	boss_defeated = false
	defeated_gate_bosses.clear()
	current_map_path = "res://scenes/map.tscn"
	player_health = player_max_health
	save_game()


func storage_add(item_id: String, amount: int = 1) -> int:
	var cap: int = ItemDatabase.get_item(item_id).get("stack_size", 1)
	var current: int = storage.get(item_id, 0)
	var space: int = maxi(cap - current, 0)
	var added: int = clampi(amount, 0, space)
	if added > 0:
		storage[item_id] = current + added
		if ItemDatabase.get_item(item_id).get("slot", "") != "":
			_reroll_if_better(item_id)
	return added


# Every gear pickup rolls fresh stats and keeps them only if they beat
# whatever roll (if any) is already remembered for this id -- so finding a
# duplicate is always either an upgrade or a no-op, never a downgrade.
func _reroll_if_better(item_id: String) -> void:
	var candidate := ItemDatabase.roll_stats(item_id)
	if not rolled_stats.has(item_id):
		rolled_stats[item_id] = candidate
		return
	var candidate_ratio := ItemDatabase.roll_power_ratio(item_id, candidate)
	var current_ratio := ItemDatabase.roll_power_ratio(item_id, rolled_stats[item_id])
	if candidate_ratio > current_ratio:
		rolled_stats[item_id] = candidate


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
		"auto_attack_enabled": auto_attack_enabled,
		"ng_plus_level": ng_plus_level,
		"storage": storage,
		"equipped": equipped,
		"quick_slots": quick_slots,
		"rolled_stats": rolled_stats,
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
	var loaded_rolled_stats = parsed.get("rolled_stats", {})
	if typeof(loaded_storage) != TYPE_DICTIONARY \
			or typeof(loaded_equipped) != TYPE_DICTIONARY \
			or typeof(loaded_quick_slots) != TYPE_DICTIONARY \
			or typeof(loaded_rolled_stats) != TYPE_DICTIONARY:
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
	auto_attack_enabled = bool(parsed.get("auto_attack_enabled", auto_attack_enabled))
	ng_plus_level = int(parsed.get("ng_plus_level", ng_plus_level))
	storage = {}
	for key in loaded_storage.keys():
		storage[key] = int(loaded_storage[key])
	equipped = loaded_equipped
	quick_slots = loaded_quick_slots
	rolled_stats = {}
	for item_id in loaded_rolled_stats.keys():
		var stat_dict = loaded_rolled_stats[item_id]
		if typeof(stat_dict) != TYPE_DICTIONARY:
			continue
		var coerced := {}
		for stat_key in stat_dict.keys():
			coerced[stat_key] = float(stat_dict[stat_key])
		rolled_stats[item_id] = coerced
	return true
