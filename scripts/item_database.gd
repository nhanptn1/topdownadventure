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
	"hand_axe": {
		"name": "Hand Axe", "item_type": "weapon", "slot": "weapon", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_hand_axe.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"atk": 3},
		"description": "A sturdy one-handed axe, simple and reliable.",
	},
	"war_spear": {
		"name": "War Spear", "item_type": "weapon", "slot": "weapon", "rarity": "rare", "color": RARE_COLOR,
		"icon": "res://assets/sprites/icon_war_spear.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"atk": 5, "stun_chance": 0.08},
		"description": "A long spear built for staggering blows. 8% chance to stun on hit.",
	},
	"silver_rapier": {
		"name": "Silver Rapier", "item_type": "weapon", "slot": "weapon", "rarity": "rare", "color": RARE_COLOR,
		"icon": "res://assets/sprites/icon_silver_rapier.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"atk": 5, "attack_speed": 0.10},
		"description": "A light, glowing blade. +10% attack speed.",
	},
	"berserker_mace": {
		"name": "Berserker Mace", "item_type": "weapon", "slot": "weapon", "rarity": "epic", "color": EPIC_COLOR,
		"icon": "res://assets/sprites/icon_berserker_mace.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"atk": 8, "crit_chance": 0.12},
		"description": "A brutal spiked mace. +12% chance to land a critical hit.",
	},
	"windcutter_bow": {
		"name": "Windcutter Bow", "item_type": "weapon", "slot": "weapon", "rarity": "epic", "color": EPIC_COLOR,
		"icon": "res://assets/sprites/icon_windcutter_bow.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"atk": 7, "attack_speed": 0.20},
		"description": "An aerodynamic recurve bow. +20% attack speed.",
	},
	"padded_vest": {
		"name": "Padded Vest", "item_type": "armor", "slot": "armor", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_padded_vest.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"def": 2},
		"description": "A simple padded vest offering modest protection.",
	},
	"hide_jerkin": {
		"name": "Hide Jerkin", "item_type": "armor", "slot": "armor", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_hide_jerkin.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"def": 1, "hp": 5},
		"description": "Tough animal hide, light but slightly bolsters max HP.",
	},
	"ranger_cloak": {
		"name": "Ranger Cloak", "item_type": "armor", "slot": "armor", "rarity": "rare", "color": RARE_COLOR,
		"icon": "res://assets/sprites/icon_ranger_cloak.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"def": 3, "speed": 20.0},
		"description": "A light traveler's cloak. Trades defense for mobility.",
	},
	"reinforced_mail": {
		"name": "Reinforced Mail", "item_type": "armor", "slot": "armor", "rarity": "rare", "color": RARE_COLOR,
		"icon": "res://assets/sprites/icon_reinforced_mail.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"def": 7},
		"description": "Dense reinforced mail. Pure, dependable defense.",
	},
	"dragonscale_armor": {
		"name": "Dragonscale Armor", "item_type": "armor", "slot": "armor", "rarity": "epic", "color": EPIC_COLOR,
		"icon": "res://assets/sprites/icon_dragonscale_armor.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"def": 8, "hp": 15},
		"description": "Armor plated with dragon scales. Tough and vitalizing.",
	},
	"phantom_vest": {
		"name": "Phantom Vest", "item_type": "armor", "slot": "armor", "rarity": "epic", "color": EPIC_COLOR,
		"icon": "res://assets/sprites/icon_phantom_vest.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"def": 6, "speed": 25.0},
		"description": "Eerily light armor that barely slows you down.",
	},
	"iron_band": {
		"name": "Iron Band", "item_type": "accessory", "slot": "accessory", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_iron_band.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"def": 2},
		"description": "A plain iron ring, cool to the touch.",
	},
	"quick_charm": {
		"name": "Quick Charm", "item_type": "accessory", "slot": "accessory", "rarity": "common", "color": COMMON_COLOR,
		"icon": "res://assets/sprites/icon_quick_charm.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"speed": 10.0},
		"description": "A humming charm that lightens your step.",
	},
	"ring_of_vigor": {
		"name": "Ring of Vigor", "item_type": "accessory", "slot": "accessory", "rarity": "rare", "color": RARE_COLOR,
		"icon": "res://assets/sprites/icon_ring_of_vigor.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"hp": 15},
		"description": "A gem-set ring that fills you with vitality.",
	},
	"berserker_talisman": {
		"name": "Berserker Talisman", "item_type": "accessory", "slot": "accessory", "rarity": "rare", "color": RARE_COLOR,
		"icon": "res://assets/sprites/icon_berserker_talisman.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"crit_chance": 0.08},
		"description": "A grim horned talisman. +8% chance to land a critical hit.",
	},
	"amulet_of_the_bear": {
		"name": "Amulet of the Bear", "item_type": "accessory", "slot": "accessory", "rarity": "epic", "color": EPIC_COLOR,
		"icon": "res://assets/sprites/icon_amulet_of_the_bear.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"hp": 30, "def": 3},
		"description": "An ancient medallion radiating enduring strength.",
	},
	"assassins_signet": {
		"name": "Assassin's Signet", "item_type": "accessory", "slot": "accessory", "rarity": "epic", "color": EPIC_COLOR,
		"icon": "res://assets/sprites/icon_assassins_signet.png",
		"stack_size": GEAR_STACK_SIZE,
		"stats": {"crit_chance": 0.15, "attack_speed": 0.10},
		"description": "A sleek pendant favored by assassins. +15% crit chance, +10% attack speed.",
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

const SLOTS := ["weapon", "armor", "accessory"]
const CATEGORY_WEIGHTS := {"gear": 0.65, "consumable": 0.30, "material": 0.05}

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


static func roll_guardian_drop(map_tier: int = 1) -> String:
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
