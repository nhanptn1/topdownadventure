extends RefCounted
class_name SkillDatabase

# Active skill unlocks at level 10, and upgrades to a stronger tier at level
# 20 -- skill_tiers[0] is the level-10 version, skill_tiers[1] is the
# level-20 version. Same icon/id across tiers (no separate art per tier),
# just bigger numbers.
const SKILL_UNLOCK_LEVEL := 10
const SKILL_LEVEL_2_AT := 20

const SKILLS := {
	"warrior": {
		"skill_tiers": [
			{"id": "flame_slash", "name": "Flame Slash",
				"icon": "res://assets/sprites/skill_icon_flame_slash.png",
				"description": "A blazing cone strike in front of you. Deals 250% attack damage.",
				"cooldown": 8.0, "damage_multiplier": 2.5, "radius": 55.0},
			{"id": "flame_slash", "name": "Flame Slash+",
				"icon": "res://assets/sprites/skill_icon_flame_slash.png",
				"description": "An empowered blazing cone strike. Deals 350% attack damage.",
				"cooldown": 7.0, "damage_multiplier": 3.5, "radius": 65.0},
		],
		# stat is the key added to _recalculate_equipment_stats()'s output;
		# the actual point value scales with passive_level_for(), not here.
		"passive": {"name": "Guardian's Resolve",
			"icon": "res://assets/sprites/skill_icon_guardians_resolve.png",
			"description": "Hardened by countless battles.", "stat": "def"},
	},
	"mage": {
		"skill_tiers": [
			{"id": "meteor", "name": "Meteor",
				"icon": "res://assets/sprites/skill_icon_meteor.png",
				"description": "Calls down a meteor on the nearest foe. Deals 300% attack damage in a radius.",
				"cooldown": 10.0, "damage_multiplier": 3.0, "radius": 80.0},
			{"id": "meteor", "name": "Meteor+",
				"icon": "res://assets/sprites/skill_icon_meteor.png",
				"description": "A larger, hungrier meteor. Deals 400% attack damage in a radius.",
				"cooldown": 8.5, "damage_multiplier": 4.0, "radius": 95.0},
		],
		"passive": {"name": "Arcane Insight",
			"icon": "res://assets/sprites/skill_icon_arcane_insight.png",
			"description": "Years of arcane study sharpen the mind and quicken the step.", "stat": "speed"},
	},
}


# 0 = locked (below SKILL_UNLOCK_LEVEL), 1 = base tier, 2 = upgraded tier.
static func skill_level_for(character_level: int) -> int:
	if character_level >= SKILL_LEVEL_2_AT:
		return 2
	elif character_level >= SKILL_UNLOCK_LEVEL:
		return 1
	return 0


# Empty dict means the skill is still locked at this character level.
static func get_skill(character: String, character_level: int) -> Dictionary:
	var tier := skill_level_for(character_level)
	if tier == 0:
		return {}
	var tiers: Array = SKILLS.get(character, {}).get("skill_tiers", [])
	if tier - 1 >= tiers.size():
		return {}
	return tiers[tier - 1]


static func get_passive_info(character: String) -> Dictionary:
	return SKILLS.get(character, {}).get("passive", {})


# Starts at 1 point from level 1, +1 point every 2 character levels
# (levels 2, 4, 6, ... each add another point).
static func passive_level_for(character_level: int) -> int:
	return 1 + int(character_level / 2)


static func get_passive_stats(character: String, character_level: int) -> Dictionary:
	var info := get_passive_info(character)
	var stat_key: String = info.get("stat", "")
	if stat_key == "":
		return {}
	return {stat_key: float(passive_level_for(character_level))}
