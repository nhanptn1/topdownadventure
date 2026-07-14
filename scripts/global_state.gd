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

# Non-gear stackable items only (consumables/materials/quest items) --
# item_id -> count. Gear (weapon/armor/accessory) lives in gear_instances/
# gear_bag instead, see below.
var storage: Dictionary = {}
var quick_slots := {"heal": "", "throwable": "", "buff": ""}

# Every individual gear pickup is now its own distinguishable copy with its
# own independently-rolled stats, rather than one remembered roll per item
# id -- this lets the player hold several copies of the same weapon with
# different rolls and choose which one to equip/discard, instead of the
# game silently only ever keeping whichever single roll happened to be best
# across every pickup (which made gear feel "fixed" once it converged).
# instance_id (String) -> {"item_id": String, "stats": Dictionary}
var gear_instances: Dictionary = {}
# item_id -> Array[String] of instance ids currently unequipped, in the bag.
var gear_bag: Dictionary = {}
# slot -> instance id of the equipped copy (or "" if the slot is empty).
var equipped := {"weapon": "", "armor": "", "accessory": ""}
var _next_gear_instance := 0


func gear_instance_item_id(instance_id: String) -> String:
	return gear_instances.get(instance_id, {}).get("item_id", "")


func gear_instance_stats(instance_id: String) -> Dictionary:
	return gear_instances.get(instance_id, {}).get("stats", {})


func gear_instance_stat(instance_id: String, stat_name: String) -> float:
	return gear_instance_stats(instance_id).get(stat_name, 0)


func gear_bag_instances(item_id: String) -> Array:
	return gear_bag.get(item_id, [])


# Rolls a fresh, independent set of stats for a brand-new copy of item_id and
# drops it straight into the bag. Returns the new instance id.
func gear_add(item_id: String) -> String:
	var instance_id := "gi%d" % _next_gear_instance
	_next_gear_instance += 1
	gear_instances[instance_id] = {"item_id": item_id, "stats": ItemDatabase.roll_stats(item_id)}
	gear_move_to_bag(instance_id)
	return instance_id


func gear_move_to_bag(instance_id: String) -> void:
	var item_id := gear_instance_item_id(instance_id)
	if item_id == "":
		return
	if not gear_bag.has(item_id):
		gear_bag[item_id] = []
	gear_bag[item_id].append(instance_id)


func gear_take_from_bag(instance_id: String) -> void:
	var item_id := gear_instance_item_id(instance_id)
	if not gear_bag.has(item_id):
		return
	gear_bag[item_id].erase(instance_id)
	if gear_bag[item_id].is_empty():
		gear_bag.erase(item_id)


# Permanently forgets a copy (used for the inventory's Discard action) --
# unlike gear_take_from_bag(), which just relocates the instance to the
# equipped slot, this actually erases its rolled stats.
func gear_discard_instance(instance_id: String) -> void:
	gear_take_from_bag(instance_id)
	gear_instances.erase(instance_id)


func difficulty_multiplier() -> float:
	return 1.0 + 0.5 * ng_plus_level


# Keeps player_level/xp/storage/gear_instances/gear_bag/equipped/quick_slots
# -- that's the point of a replay. Resets map/gate progress so the whole
# world (including the final boss) needs re-clearing, now scaled up via
# difficulty_multiplier().
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
		"auto_attack_enabled": auto_attack_enabled,
		"ng_plus_level": ng_plus_level,
		"storage": storage,
		"equipped": equipped,
		"quick_slots": quick_slots,
		"gear_instances": gear_instances,
		"gear_bag": gear_bag,
		"next_gear_instance": _next_gear_instance,
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
	var loaded_gear_instances = parsed.get("gear_instances", {})
	var loaded_gear_bag = parsed.get("gear_bag", {})
	if typeof(loaded_storage) != TYPE_DICTIONARY \
			or typeof(loaded_equipped) != TYPE_DICTIONARY \
			or typeof(loaded_quick_slots) != TYPE_DICTIONARY \
			or typeof(loaded_gear_instances) != TYPE_DICTIONARY \
			or typeof(loaded_gear_bag) != TYPE_DICTIONARY:
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
		if ItemDatabase.get_item(key).get("slot", "") != "":
			continue  # legacy gear entry from before the per-copy rework -- no longer tracked in storage
		storage[key] = int(loaded_storage[key])

	# Saves from before the per-copy gear rework (which stored gear in
	# `storage`/`rolled_stats` with one roll per item id) don't have
	# gear_instances/gear_bag at all -- rather than migrating that old
	# single-roll data, equipped gear/bag contents reset empty on first load
	# with the new save format, same tradeoff already accepted when the
	# whole item roster was replaced earlier in this project's history.
	gear_instances = {}
	for instance_id in loaded_gear_instances.keys():
		var entry = loaded_gear_instances[instance_id]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var item_id = entry.get("item_id", "")
		var stat_dict = entry.get("stats", {})
		if typeof(item_id) != TYPE_STRING or typeof(stat_dict) != TYPE_DICTIONARY:
			continue
		var coerced := {}
		for stat_key in stat_dict.keys():
			coerced[stat_key] = float(stat_dict[stat_key])
		gear_instances[instance_id] = {"item_id": item_id, "stats": coerced}

	gear_bag = {}
	for item_id in loaded_gear_bag.keys():
		var ids = loaded_gear_bag[item_id]
		if typeof(ids) != TYPE_ARRAY:
			continue
		var kept: Array[String] = []
		for instance_id in ids:
			if typeof(instance_id) == TYPE_STRING and gear_instances.has(instance_id):
				kept.append(instance_id)
		gear_bag[item_id] = kept

	equipped = {"weapon": "", "armor": "", "accessory": ""}
	for slot in loaded_equipped.keys():
		var instance_id = loaded_equipped[slot]
		if equipped.has(slot) and typeof(instance_id) == TYPE_STRING and (instance_id == "" or gear_instances.has(instance_id)):
			equipped[slot] = instance_id

	quick_slots = loaded_quick_slots
	_next_gear_instance = int(parsed.get("next_gear_instance", 0))
	return true
