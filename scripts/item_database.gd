extends RefCounted
class_name ItemDatabase

const COMMON_COLOR := Color(0.85, 0.85, 0.85)
const RARE_COLOR := Color(0.3, 0.55, 1.0)
const EPIC_COLOR := Color(0.65, 0.25, 0.95)
const MYTHIC_COLOR := Color(1.0, 0.75, 0.15)

const GEAR_STACK_SIZE := 999999

const ITEMS := {
	"weathered_bow": {
		"name": "Weathered Bow", "item_type": "weapon", "slot": "weapon", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_weathered_bow.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"atk": 3},
		"description": "A simple wooden bow, its string worn from years of use.",
	},
	"frostwind_bow": {
		"name": "Frostwind Bow", "item_type": "weapon", "slot": "weapon", "rarity": "rare", "color": RARE_COLOR,
		"icon": "res://assets/sprites/icon_frostwind_bow.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"atk": 6, "attack_speed": 0.10},
		"description": "A slender bow etched with frost-blue filigree. +10% attack speed.",
	},
	"cursed_runebow": {
		"name": "Cursed Runebow", "item_type": "weapon", "slot": "weapon", "rarity": "epic", "color": EPIC_COLOR,
		"icon": "res://assets/sprites/icon_cursed_runebow.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"atk": 8, "crit_chance": 0.12, "attack_speed": 0.08},
		"description": "A bow bound in crimson runes that hunger for a killing blow. +12% crit chance, +8% attack speed.",
	},
	"sovereigns_bow": {
		"name": "Sovereign's Bow", "item_type": "weapon", "slot": "weapon", "rarity": "mythic", "color": MYTHIC_COLOR,
		"icon": "res://assets/sprites/icon_sovereigns_bow.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"atk": 14, "crit_chance": 0.20, "attack_speed": 0.25, "stun_chance": 0.10},
		"description": "Reforged with the Withered Sovereign's essence. +20% crit chance, +25% attack speed, +10% chance to stun on hit.",
	},
	"travelers_tunic": {
		"name": "Traveler's Tunic", "item_type": "armor", "slot": "armor", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_travelers_tunic.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"def": 2},
		"description": "A simple tunic offering modest protection.",
	},
	"steel_plate_armor": {
		"name": "Steel Plate Armor", "item_type": "armor", "slot": "armor", "rarity": "rare", "color": RARE_COLOR,
		"icon": "res://assets/sprites/icon_steel_plate_armor.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"def": 6, "hp": 10},
		"description": "Polished steel plate, sturdy and reassuring. Also bolsters max HP.",
	},
	"voidscale_armor": {
		"name": "Voidscale Armor", "item_type": "armor", "slot": "armor", "rarity": "epic", "color": EPIC_COLOR,
		"icon": "res://assets/sprites/icon_voidscale_armor.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"def": 8, "hp": 15, "speed": 10.0},
		"description": "Armor grown from scales torn out of the void. Tough, vitalizing, and unnaturally light.",
	},
	"sovereigns_aegis": {
		"name": "Sovereign's Aegis", "item_type": "armor", "slot": "armor", "rarity": "mythic", "color": MYTHIC_COLOR,
		"icon": "res://assets/sprites/icon_sovereigns_aegis.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"def": 16, "hp": 35, "speed": 20.0, "crit_chance": 0.08},
		"description": "Reforged with the Withered Sovereign's essence. Nearly impervious, and its wearer strikes with unnatural precision. +8% crit chance.",
	},
	"iron_ring": {
		"name": "Iron Ring", "item_type": "accessory", "slot": "accessory", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_iron_ring.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"hp": 5},
		"description": "A plain iron ring, cool to the touch.",
	},
	"sapphire_ring": {
		"name": "Sapphire Ring", "item_type": "accessory", "slot": "accessory", "rarity": "rare", "color": RARE_COLOR,
		"icon": "res://assets/sprites/icon_sapphire_ring.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"hp": 15, "speed": 10.0},
		"description": "A gem-set ring that fills you with vitality and a touch of swiftness.",
	},
	"void_ring": {
		"name": "Void Ring", "item_type": "accessory", "slot": "accessory", "rarity": "epic", "color": EPIC_COLOR,
		"icon": "res://assets/sprites/icon_void_ring.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"crit_chance": 0.15, "attack_speed": 0.10, "hp": 8},
		"description": "A ring humming with dark power. +15% crit chance, +10% attack speed.",
	},
	"sovereigns_signet": {
		"name": "Sovereign's Signet", "item_type": "accessory", "slot": "accessory", "rarity": "mythic", "color": MYTHIC_COLOR,
		"icon": "res://assets/sprites/icon_sovereigns_signet.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"crit_chance": 0.25, "attack_speed": 0.18, "hp": 20, "speed": 15.0},
		"description": "Reforged with the Withered Sovereign's essence. +25% crit chance, +18% attack speed, and a surge of vitality and swiftness.",
	},
	"healing_potion": {
		"name": "Healing Potion", "item_type": "consumable", "category": "heal", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_healing_potion.png",
		"stack_size": 20, "cooldown": 3.0, "use_action": "heal",
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

const CONSUMABLE_IDS := ["healing_potion", "healing_potion", "healing_potion", "fire_bomb", "swift_tonic"]
const MATERIAL_IDS := ["dragon_scale", "iron_ingot", "ruby_gem"]

const SLOTS := ["weapon", "armor", "accessory"]
const CATEGORY_WEIGHTS := {"gear": 0.55, "consumable": 0.40, "material": 0.05}

# Per-map-tier rarity gates: Map 1 (white/blue only, no epic), Map 2 (blue +
# a low chance of epic), Map 3 (epic dominant, full rarity range unlocked).
# Keys are iterated in insertion order for the cumulative roll below.
const RARITY_WEIGHTS_BY_TIER := {
	1: {"common": 0.7, "rare": 0.3},
	2: {"rare": 0.75, "epic": 0.25},
	3: {"rare": 0.3, "epic": 0.7},
}
const GUARDIAN_RARITY_WEIGHTS_BY_TIER := {
	1: {"rare": 1.0},
	2: {"rare": 0.6, "epic": 0.4},
	3: {"rare": 0.15, "epic": 0.85},
}

# Mythic gear is New Game+ only -- a reason to keep replaying the harder
# final boss beyond the bigger numbers. allow_mythic is only ever passed
# true from the true final boss's drop roll (see ultimate_boss.gd), never
# from regular gate bosses/guardians, so it stays a final-boss-only carrot.
const MYTHIC_DROP_CHANCE := 0.5

# Every gear item's authored `stats` value is the ceiling of what that item
# can roll, not a fixed number -- an actual drop lands somewhere in
# [STAT_ROLL_MIN_RATIO * base, base] per stat, independently per stat (see
# roll_stats()). 0.6 means a "def: 5" item can roll as low as 3, matching
# the reference example this was designed from.
const STAT_ROLL_MIN_RATIO := 0.6
const INT_STATS := ["atk", "def", "hp"]


# item_id -> {material_id: count}, common/rare/epic tiers only -- mythic gear
# is deliberately not craftable, staying a NG+-exclusive drop-only reward (see
# MYTHIC_DROP_CHANCE above). Costs scale with rarity; first-pass numbers,
# retune here if farming feels too fast/slow.
const CRAFTING_RECIPES := {
	"weathered_bow": {"iron_ingot": 2},
	"travelers_tunic": {"iron_ingot": 2},
	"iron_ring": {"iron_ingot": 2},
	"frostwind_bow": {"iron_ingot": 4, "ruby_gem": 3},
	"steel_plate_armor": {"iron_ingot": 4, "ruby_gem": 3},
	"sapphire_ring": {"iron_ingot": 4, "ruby_gem": 3},
	"cursed_runebow": {"iron_ingot": 6, "ruby_gem": 5, "dragon_scale": 4},
	"voidscale_armor": {"iron_ingot": 6, "ruby_gem": 5, "dragon_scale": 4},
	"void_ring": {"iron_ingot": 6, "ruby_gem": 5, "dragon_scale": 4},
}


static func get_recipe(item_id: String) -> Dictionary:
	return CRAFTING_RECIPES.get(item_id, {})


static func get_item(id: String) -> Dictionary:
	return ITEMS.get(id, {})


static func get_stat(id: String, stat_name: String) -> float:
	return ITEMS.get(id, {}).get("stats", {}).get(stat_name, 0)


static func roll_stats(id: String) -> Dictionary:
	var base: Dictionary = ITEMS.get(id, {}).get("stats", {})
	var rolled := {}
	for key in base.keys():
		var max_val: float = base[key]
		var min_val: float = max_val * STAT_ROLL_MIN_RATIO
		var value := randf_range(min_val, max_val)
		if key in INT_STATS:
			rolled[key] = roundi(value)
		elif key == "speed":
			rolled[key] = roundf(value)
		else:
			rolled[key] = roundf(value * 100.0) / 100.0
	return rolled


# Mean of each stat's position within its own [min, max] roll range (0 =
# worst possible roll, 1 = best) -- lets two rolls of the same item be
# compared on a common scale even though their stats (atk vs crit_chance
# vs hp) aren't otherwise comparable numbers.
static func roll_power_ratio(id: String, rolled: Dictionary) -> float:
	var base: Dictionary = ITEMS.get(id, {}).get("stats", {})
	if base.is_empty():
		return 0.0
	var total := 0.0
	for key in base.keys():
		var max_val: float = base[key]
		var min_val: float = max_val * STAT_ROLL_MIN_RATIO
		var value: float = rolled.get(key, min_val)
		total += 1.0 if max_val == min_val else (value - min_val) / (max_val - min_val)
	return total / base.size()


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


static func _pick_rarity(weights: Dictionary) -> String:
	var roll := randf()
	var cumulative := 0.0
	var last_rarity := "common"
	for rarity in weights.keys():
		cumulative += weights[rarity]
		last_rarity = rarity
		if roll < cumulative:
			return rarity
	return last_rarity  # float rounding fallback: just use the last tier in the table


static func roll_random_item_id(map_tier: int = 1) -> String:
	var weights: Dictionary = RARITY_WEIGHTS_BY_TIER.get(map_tier, RARITY_WEIGHTS_BY_TIER[1])
	return _roll_item_by_rarity(_pick_rarity(weights))


static func roll_guardian_drop(map_tier: int = 1, allow_mythic: bool = false) -> String:
	if allow_mythic and randf() < MYTHIC_DROP_CHANCE:
		return _roll_item_by_rarity("mythic")
	var weights: Dictionary = GUARDIAN_RARITY_WEIGHTS_BY_TIER.get(map_tier, GUARDIAN_RARITY_WEIGHTS_BY_TIER[1])
	return _roll_item_by_rarity(_pick_rarity(weights))


static func roll_random_drop(map_tier: int = 1) -> String:
	var roll := randf()
	if roll < CATEGORY_WEIGHTS["material"]:
		return MATERIAL_IDS[randi() % MATERIAL_IDS.size()]
	elif roll < CATEGORY_WEIGHTS["material"] + CATEGORY_WEIGHTS["consumable"]:
		return CONSUMABLE_IDS[randi() % CONSUMABLE_IDS.size()]
	else:
		return roll_random_item_id(map_tier)
