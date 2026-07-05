extends RefCounted
class_name ItemDatabase

const COMMON_COLOR := Color(0.85, 0.85, 0.85)
const RARE_COLOR := Color(0.3, 0.55, 1.0)
const EPIC_COLOR := Color(0.65, 0.25, 0.95)

const GEAR_STACK_SIZE := 999999

const ITEMS := {
	"iron_sword": {
		"name": "Iron Sword", "item_type": "weapon", "slot": "weapon", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_iron_sword.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"atk": 3},
		"description": "A simple, dependable blade.",
	},
	"hunting_bow": {
		"name": "Hunting Bow", "item_type": "weapon", "slot": "weapon", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_hunting_bow.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"atk": 3},
		"description": "A simple recurve bow, light and quick to swing.",
	},
	"steel_blade": {
		"name": "Steel Blade", "item_type": "weapon", "slot": "weapon", "rarity": "rare", "color": RARE_COLOR,
		"icon": "res://assets/sprites/icon_steel_blade.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"atk": 6, "crit_chance": 0.05},
		"description": "Well-honed steel. +5% chance to land a critical hit.",
	},
	"knight_axe": {
		"name": "Knight Axe", "item_type": "weapon", "slot": "weapon", "rarity": "epic", "color": EPIC_COLOR,
		"icon": "res://assets/sprites/icon_knight_axe.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"atk": 9, "stun_chance": 0.15},
		"description": "A heavy axe with a 15% chance to stun on hit.",
	},
	"leather_armor": {
		"name": "Leather Armor", "item_type": "armor", "slot": "armor", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_leather_armor.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"def": 2},
		"description": "Basic protection against enemy strikes.",
	},
	"chain_mail": {
		"name": "Chain Mail", "item_type": "armor", "slot": "armor", "rarity": "rare", "color": RARE_COLOR,
		"icon": "res://assets/sprites/icon_chain_mail.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"def": 5, "hp": 10},
		"description": "Sturdy mail links. Also bolsters max HP.",
	},
	"guardian_plate": {
		"name": "Guardian Plate", "item_type": "armor", "slot": "armor", "rarity": "epic", "color": EPIC_COLOR,
		"icon": "res://assets/sprites/icon_guardian_plate.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"def": 9},
		"description": "Heavy plate armor that blunts nearly every blow.",
	},
	"copper_ring": {
		"name": "Copper Ring", "item_type": "accessory", "slot": "accessory", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_copper_ring.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"hp": 5},
		"description": "A modest trinket that toughens you slightly.",
	},
	"amulet_of_focus": {
		"name": "Amulet of Focus", "item_type": "accessory", "slot": "accessory", "rarity": "rare", "color": RARE_COLOR,
		"icon": "res://assets/sprites/icon_amulet_focus.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"attack_speed": 0.15},
		"description": "Sharpens focus, letting you attack 15% faster.",
	},
	"swift_charm": {
		"name": "Swift Charm", "item_type": "accessory", "slot": "accessory", "rarity": "epic", "color": EPIC_COLOR,
		"icon": "res://assets/sprites/icon_swift_charm.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"speed": 40.0},
		"description": "A charm humming with wind magic. Greatly boosts movement speed.",
	},
	"healing_potion": {
		"name": "Healing Potion", "item_type": "consumable", "category": "heal", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_healing_potion.png",
		"stack_size": 10, "cooldown": 3.0, "use_action": "heal",
		"stats": {"heal_amount": 30},
		"description": "Restores 30 HP instantly.",
	},
	"fire_bomb": {
		"name": "Fire Bomb", "item_type": "consumable", "category": "throwable", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_fire_bomb.png",
		"stack_size": 5, "cooldown": 2.0, "use_action": "throw_bomb",
		"stats": {"damage": 15, "radius": 60.0},
		"description": "Thrown bomb that explodes for 15 damage in a small radius.",
	},
	"swift_tonic": {
		"name": "Swift Tonic", "item_type": "consumable", "category": "buff", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_swift_tonic.png",
		"stack_size": 5, "cooldown": 10.0, "use_action": "buff_speed",
		"stats": {"speed_bonus": 80.0, "duration": 8.0},
		"description": "Grants +80 move speed for 8 seconds.",
	},
	"dragon_scale": {
		"name": "Dragon Scale", "item_type": "material", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_dragon_scale.png",
		"stack_size": 99,
		"stats": {},
		"description": "A tough scale shed by a dragon. Useful for future crafting.",
	},
	"iron_ingot": {
		"name": "Iron Ingot", "item_type": "material", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_iron_ingot.png",
		"stack_size": 99,
		"stats": {},
		"description": "A refined bar of iron. Useful for future crafting.",
	},
	"ruby_gem": {
		"name": "Ruby Gem", "item_type": "material", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_ruby_gem.png",
		"stack_size": 99,
		"stats": {},
		"description": "A gleaming red gem. Useful for future crafting.",
	},
	"ancient_relic": {
		"name": "Ancient Relic", "item_type": "quest", "rarity": "epic", "color": EPIC_COLOR,
		"icon": "res://assets/sprites/icon_ancient_relic.png",
		"stack_size": 99,
		"stats": {},
		"description": "A mysterious relic. Someone might want this.",
	},
}

const CONSUMABLE_IDS := ["healing_potion", "healing_potion", "fire_bomb", "swift_tonic"]
const MATERIAL_IDS := ["dragon_scale", "iron_ingot", "ruby_gem"]

const RARITY_WEIGHTS := {"common": 0.55, "rare": 0.3, "epic": 0.15}
const GUARDIAN_RARITY_WEIGHTS := {"epic": 0.5, "rare": 0.5}
const SLOTS := ["weapon", "armor", "accessory"]
const CATEGORY_WEIGHTS := {"gear": 0.65, "consumable": 0.30, "material": 0.05}


static func get_item(id: String) -> Dictionary:
	return ITEMS.get(id, {})


static func get_stat(id: String, stat_name: String) -> float:
	return ITEMS.get(id, {}).get("stats", {}).get(stat_name, 0)


static func _roll_item_by_rarity(rarity: String) -> String:
	var slot: String = SLOTS[randi() % SLOTS.size()]
	var matches: Array[String] = []
	for id in ITEMS.keys():
		var it: Dictionary = ITEMS[id]
		if it.get("slot", "") == slot and it.get("rarity", "") == rarity:
			matches.append(id)
	if matches.is_empty():
		return ""
	return matches[randi() % matches.size()]


static func roll_random_item_id() -> String:
	var roll := randf()
	var rarity := "common"
	if roll < RARITY_WEIGHTS["epic"]:
		rarity = "epic"
	elif roll < RARITY_WEIGHTS["epic"] + RARITY_WEIGHTS["rare"]:
		rarity = "rare"
	return _roll_item_by_rarity(rarity)


static func roll_guardian_drop() -> String:
	var roll := randf()
	var rarity := "rare"
	if roll < GUARDIAN_RARITY_WEIGHTS["epic"]:
		rarity = "epic"
	return _roll_item_by_rarity(rarity)


static func roll_random_drop() -> String:
	var roll := randf()
	if roll < CATEGORY_WEIGHTS["material"]:
		return MATERIAL_IDS[randi() % MATERIAL_IDS.size()]
	elif roll < CATEGORY_WEIGHTS["material"] + CATEGORY_WEIGHTS["consumable"]:
		return CONSUMABLE_IDS[randi() % CONSUMABLE_IDS.size()]
	else:
		return roll_random_item_id()
