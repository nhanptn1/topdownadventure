extends CharacterBody2D

const SPEED := 220.0
const SPRINT_MULTIPLIER := 1.6
const MAX_LEVEL := 100
const XP_REQUIREMENT_MULTIPLIER := 3.0
const HIGH_LEVEL_XP_THRESHOLD := 20
const HIGH_LEVEL_XP_SURCHARGE := 0.1
const BASE_MAX_HEALTH := 100
const HP_PER_LEVEL := 8
const BASE_ATTACK_DAMAGE := 3
const SPRITE_SCALE := 0.75
const ATTACK_COOLDOWN_BASE := 0.4
const RESPAWN_SECONDS := 10
const SHAKE_DECAY := 24.0
const HIT_SHAKE_STRENGTH := 5.0
const QUICK_SLOT_DISPLAY_INTERVAL := 0.1
const ZOOM_LEVELS := [1.0, 1.3]
# Raises the skill cast's visual effect to roughly head/upper-body height on
# its target, matching the offset enemy.gd already uses for its own damage
# numbers -- the AoE damage query itself still centers on the target's real
# (unraised) position for correct hit detection.
const SKILL_EFFECT_HEAD_OFFSET := Vector2(0, -30)

const CHARACTER_DATA := {
	"warrior": {"prefix": "warrior", "directional": true,
		"frame_counts": {"idle_side": 2, "walk_side": 6, "attack_side": 5,
			"idle_back": 2, "walk_back": 4, "attack_back": 3},
		"anim_fps": {"idle_side": 4.0, "walk_side": 10.0, "attack_side": 14.0,
			"idle_back": 4.0, "walk_back": 10.0, "attack_back": 14.0},
		"scale_factor": 0.4, "projectile_scene": "res://scenes/projectile_knife.tscn",
		# Short-ranged knife throw (see projectile_knife.tscn's max_range)
		# needs a higher flat base defense to compensate for playing closer
		# to enemies than the mage's longer-ranged bolt.
		"base_defense": 5},
	"mage": {"prefix": "mage", "directional": true,
		# idle_side reuses 2 walk_side frames (no true idle-side pose on the
		# source sheet - only front/back have a real standing-still pose);
		# attack_side/attack_back duplicate attack_front's cast frames (the
		# sheet's spell-cast animation is front-facing only, no side/back
		# cast pose exists at all)
		"frame_counts": {"idle_side": 2, "walk_side": 3, "attack_side": 6,
			"idle_back": 3, "walk_back": 2, "attack_back": 6,
			"idle_front": 5, "walk_front": 3, "attack_front": 6},
		"anim_fps": {"idle_side": 4.0, "walk_side": 10.0, "attack_side": 11.0,
			"idle_back": 4.0, "walk_back": 10.0, "attack_back": 11.0,
			"idle_front": 4.0, "walk_front": 10.0, "attack_front": 11.0},
		"scale_factor": 0.2, "projectile_scene": "res://scenes/projectile_bolt.tscn",
		"base_defense": 1},
}

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var camera: Camera2D = $Camera2D
@onready var aim_indicator: Node2D = $AimIndicator
@onready var attack_cooldown: Timer = $AttackCooldown
@onready var health_bar_fill: Polygon2D = $HealthBar/Fill
@onready var hud_level_label: Label = $HUD/Margin/VBox/LevelLabel
@onready var hud_health_label: Label = $HUD/Margin/VBox/HealthLabel
@onready var hud_health_bar: ProgressBar = $HUD/Margin/VBox/HealthBarUI
@onready var hud_xp_label: Label = $HUD/Margin/VBox/XPLabel
@onready var hud_xp_bar: ProgressBar = $HUD/Margin/VBox/XPBarUI
@onready var inventory_ui: CanvasLayer = $InventoryUI
@onready var equip_prompt: ConfirmationDialog = $EquipPromptDialog
@onready var death_screen: CanvasLayer = $DeathScreen
@onready var death_info_label: Label = $DeathScreen/Center/VBox/InfoLabel
@onready var death_countdown_label: Label = $DeathScreen/Center/VBox/CountdownLabel
@onready var victory_screen: CanvasLayer = $VictoryScreen
@onready var victory_info_label: Label = $VictoryScreen/Center/VBox/InfoLabel
@onready var ng_plus_label: Label = $HUD/Margin/VBox/NGPlusLabel
@onready var zoom_button: Button = $MinimapLayer/ZoomButton
@onready var auto_attack_button: Button = $MinimapLayer/AutoAttackButton
@onready var quick_slot_heal_label: Label = $HUD/Margin/VBox/QuickSlotBar/Heal/Label
@onready var quick_slot_throwable_label: Label = $HUD/Margin/VBox/QuickSlotBar/Throwable/Label
@onready var quick_slot_buff_label: Label = $HUD/Margin/VBox/QuickSlotBar/Buff/Label
@onready var skill_icon_rect: TextureRect = $HUD/Margin/VBox/SkillBar/Skill/Icon
@onready var skill_label: Label = $HUD/Margin/VBox/SkillBar/Skill/Label
@onready var skill_use_button: Button = $HUD/Margin/VBox/SkillBar/Skill/UseButton
@onready var passive_icon_rect: TextureRect = $HUD/Margin/VBox/SkillBar/Passive/Icon
@onready var passive_label: Label = $HUD/Margin/VBox/SkillBar/Passive/Label

var can_attack := true
var is_attacking := false
var facing_right := true
var facing_direction := Vector2.RIGHT

var max_health := BASE_MAX_HEALTH
var health := max_health
var is_dead := false

var level := 1
var xp := 0

var character_data: Dictionary

var weapon_atk_bonus := 0
var defense := 0
var crit_chance := 0.0
var stun_chance := 0.0
var attack_speed_bonus := 0.0
var accessory_speed_bonus := 0.0

var buff_speed_bonus := 0.0
var _buff_speed_token := 0
var quick_slot_cooldowns := {"heal": 0.0, "throwable": 0.0, "buff": 0.0}
var skill_cooldown_remaining := 0.0

const RARITY_RANK := {"common": 0, "rare": 1, "epic": 2, "mythic": 3}
# Consumable categories that auto-fill their quick slot on pickup instead of
# requiring a trip to the bag (HP potion, speed tonic, bombs).
const AUTO_QUICK_SLOT_CATEGORIES := ["heal", "buff", "throwable"]
var _pending_equip_instance_id := ""

var _shake_strength := 0.0
var _quick_slot_display_timer := 0.0


func _ready() -> void:
	level = GlobalState.player_level
	xp = GlobalState.player_xp
	max_health = GlobalState.player_max_health
	health = GlobalState.player_health
	add_to_group("player")
	character_data = CHARACTER_DATA.get(GlobalState.selected_character, CHARACTER_DATA["warrior"])
	_recalculate_equipment_stats()
	attack_cooldown.timeout.connect(_on_attack_cooldown_timeout)
	equip_prompt.confirmed.connect(_on_equip_prompt_confirmed)
	equip_prompt.canceled.connect(_on_equip_prompt_canceled)
	equip_prompt.visibility_changed.connect(_on_equip_prompt_visibility_changed)
	equip_prompt.get_ok_button().text = "Equip"
	equip_prompt.get_cancel_button().text = "Not now"
	_setup_sprite_frames()
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	sprite.play(_resolve_anim("idle"))
	aim_indicator.rotation = facing_direction.angle()
	_apply_camera_zoom()
	auto_attack_button.pressed.connect(_on_auto_attack_button_pressed)
	_update_auto_attack_button_text()
	_setup_skill_ui()
	ng_plus_label.visible = GlobalState.ng_plus_level > 0
	if ng_plus_label.visible:
		ng_plus_label.text = "NG+%d" % GlobalState.ng_plus_level
	_update_hud()


func _setup_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	var frame_counts: Dictionary = character_data["frame_counts"]
	var anim_fps: Dictionary = character_data["anim_fps"]

	for anim_name in frame_counts.keys():
		_add_animation(frames, anim_name, frame_counts[anim_name], anim_fps[anim_name],
			not anim_name.begins_with("attack"))

	sprite.sprite_frames = frames
	var final_scale: float = SPRITE_SCALE * float(character_data["scale_factor"])
	sprite.scale = Vector2(final_scale, final_scale)


func _add_animation(frames: SpriteFrames, anim_name: String, frame_count: int, fps: float, loop: bool) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, fps)
	for i in range(1, frame_count + 1):
		var path := "res://assets/sprites/%s_%s_%d.png" % [character_data["prefix"], anim_name, i]
		var tex: Texture2D = load(path)
		if tex == null:
			push_error("Missing sprite frame: " + path)
			continue
		frames.add_frame(anim_name, tex)


func _resolve_anim(base: String) -> String:
	if not character_data["directional"]:
		return base
	if facing_direction == Vector2.UP:
		return base + "_back"
	elif facing_direction == Vector2.DOWN and character_data["frame_counts"].has(base + "_front"):
		return base + "_front"
	else:
		return base + "_side"


func _process(delta: float) -> void:
	if _shake_strength > 0.0:
		camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
		_shake_strength = maxf(_shake_strength - SHAKE_DECAY * delta, 0.0)
	elif camera.offset != Vector2.ZERO:
		camera.offset = Vector2.ZERO


func add_camera_shake(amount: float) -> void:
	_shake_strength = maxf(_shake_strength, amount)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	for category in quick_slot_cooldowns:
		quick_slot_cooldowns[category] = maxf(quick_slot_cooldowns[category] - delta, 0.0)
	skill_cooldown_remaining = maxf(skill_cooldown_remaining - delta, 0.0)
	# Auto-attack mode also auto-casts the active skill whenever it's off
	# cooldown -- _try_skill() already no-ops gracefully while mid-swing,
	# dead, on cooldown, or still locked, so it's safe to just try it every
	# frame the toggle is on rather than threading it through the attack
	# animation's own chained re-fire callbacks. Auto-cast additionally
	# requires an actual enemy in range -- unlike a manual R-press (which can
	# still swing at empty air like a normal attack), auto-cast would
	# otherwise keep firing the skill into empty space on cooldown forever
	# while no enemy is nearby.
	if GlobalState.auto_attack_enabled and skill_cooldown_remaining <= 0.0 and not is_attacking:
		var auto_skill := SkillDatabase.get_skill(GlobalState.selected_character, level)
		if not auto_skill.is_empty() and _find_nearest_enemy_in_range(_skill_search_range(auto_skill)) != null:
			_try_skill()
	_quick_slot_display_timer += delta
	if _quick_slot_display_timer >= QUICK_SLOT_DISPLAY_INTERVAL:
		_quick_slot_display_timer = 0.0
		_update_quick_slot_cooldown_display()
		_update_skill_cooldown_display()

	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_vector.y = Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	input_vector = input_vector.normalized()

	var sprinting := Input.is_action_pressed("sprint")
	var speed := SPEED + accessory_speed_bonus + buff_speed_bonus
	if sprinting:
		speed *= SPRINT_MULTIPLIER

	velocity = input_vector * speed
	move_and_slide()

	# Movement direction always takes priority over an in-progress attack:
	# facing keeps updating live (never frozen mid-swing), and turning to a
	# new direction while attacking cancels the current swing immediately
	# instead of forcing the player to sit through the old-direction pose.
	if input_vector.x > 0.1:
		facing_right = true
	elif input_vector.x < -0.1:
		facing_right = false

	if input_vector.length() > 0.1:
		var new_facing_direction: Vector2
		if absf(input_vector.x) >= absf(input_vector.y):
			new_facing_direction = Vector2.RIGHT if input_vector.x >= 0.0 else Vector2.LEFT
		else:
			new_facing_direction = Vector2.DOWN if input_vector.y >= 0.0 else Vector2.UP

		var direction_changed := is_attacking and new_facing_direction != facing_direction
		facing_direction = new_facing_direction
		aim_indicator.rotation = facing_direction.angle()
		if direction_changed:
			_cancel_attack()

	var has_front: bool = character_data["directional"] and character_data["frame_counts"].has("idle_front")
	if character_data["directional"] and facing_direction == Vector2.UP:
		sprite.flip_h = false
	elif character_data["directional"] and facing_direction == Vector2.DOWN and has_front:
		sprite.flip_h = false
	else:
		sprite.flip_h = not facing_right

	if not is_attacking:
		var moving := input_vector.length() > 0.01
		sprite.speed_scale = 1.6 if (sprinting and moving) else 1.0
		var desired_animation := _resolve_anim("walk" if moving else "idle")
		if sprite.animation != desired_animation:
			sprite.play(desired_animation)


func _cancel_attack() -> void:
	# The projectile for the current swing already fired at swing-start, so
	# cutting the follow-through pose short doesn't skip any damage -- it
	# just lets movement/animation react to the new direction immediately.
	is_attacking = false
	if GlobalState.auto_attack_enabled and can_attack and not is_dead:
		_try_attack()


func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_try_attack()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		_step_zoom(1)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_step_zoom(-1)
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F:
		_try_attack()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		_try_skill()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_I:
		_open_inventory()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_B:
		_open_inventory()
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_1:
		_use_quick_slot("heal")
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_2:
		_use_quick_slot("throwable")
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_3:
		_use_quick_slot("buff")


func _open_inventory() -> void:
	if not inventory_ui.visible:
		AudioManager.play("ui_click")
		inventory_ui.open()


func _on_inventory_button_pressed() -> void:
	_open_inventory()


func _apply_camera_zoom() -> void:
	camera.zoom = Vector2(GlobalState.camera_zoom, GlobalState.camera_zoom)
	zoom_button.text = "Zoom: %.1fx" % GlobalState.camera_zoom


func _on_zoom_button_pressed() -> void:
	var current_index := ZOOM_LEVELS.find(GlobalState.camera_zoom)
	var next_index := (current_index + 1) % ZOOM_LEVELS.size() if current_index != -1 else 0
	GlobalState.camera_zoom = ZOOM_LEVELS[next_index]
	_apply_camera_zoom()
	GlobalState.save_game()


func _update_auto_attack_button_text() -> void:
	auto_attack_button.text = "Auto-Attack: ON" if GlobalState.auto_attack_enabled else "Auto-Attack: OFF"


func _setup_skill_ui() -> void:
	# Icon/description are the same across skill tiers (no separate art per
	# tier) so they're set once here; the tier-dependent name/numbers and the
	# locked/unlocked state are refreshed live in _update_skill_cooldown_display().
	var skill_tiers: Array = SkillDatabase.SKILLS.get(GlobalState.selected_character, {}).get("skill_tiers", [])
	if not skill_tiers.is_empty():
		var base_skill: Dictionary = skill_tiers[0]
		var skill_icon: String = base_skill.get("icon", "")
		if skill_icon != "":
			skill_icon_rect.texture = load(skill_icon)
	var passive := SkillDatabase.get_passive_info(GlobalState.selected_character)
	var passive_icon: String = passive.get("icon", "")
	if passive_icon != "":
		passive_icon_rect.texture = load(passive_icon)
	passive_icon_rect.tooltip_text = passive.get("description", "")
	_update_skill_cooldown_display()


func _on_auto_attack_button_pressed() -> void:
	GlobalState.auto_attack_enabled = not GlobalState.auto_attack_enabled
	_update_auto_attack_button_text()
	GlobalState.save_game()
	# If we just turned it on and the weapon is already off cooldown, fire
	# right away instead of waiting for a cooldown timer that isn't running.
	if GlobalState.auto_attack_enabled and can_attack and not is_dead:
		_try_attack()


func _step_zoom(direction: int) -> void:
	var current_index := ZOOM_LEVELS.find(GlobalState.camera_zoom)
	if current_index == -1:
		current_index = 0
	var next_index: int = clampi(current_index + direction, 0, ZOOM_LEVELS.size() - 1)
	if ZOOM_LEVELS[next_index] == GlobalState.camera_zoom:
		return
	GlobalState.camera_zoom = ZOOM_LEVELS[next_index]
	_apply_camera_zoom()
	GlobalState.save_game()


func _on_quick_slot_heal_pressed() -> void:
	_use_quick_slot("heal")


func _on_quick_slot_throwable_pressed() -> void:
	_use_quick_slot("throwable")


func _on_quick_slot_buff_pressed() -> void:
	_use_quick_slot("buff")


func _try_attack() -> void:
	if not can_attack or is_attacking:
		return
	can_attack = false
	is_attacking = true
	attack_cooldown.wait_time = ATTACK_COOLDOWN_BASE * (1.0 - attack_speed_bonus)
	attack_cooldown.start()

	var aim_dir := facing_direction

	var dmg := total_attack_damage()
	var crit := randf() < crit_chance
	if crit:
		dmg *= 2

	var proj_scene: PackedScene = load(character_data["projectile_scene"])
	var proj := proj_scene.instantiate()
	proj.direction = aim_dir
	proj.damage = dmg
	proj.stun_chance = stun_chance
	proj.is_crit = crit
	proj.global_position = global_position + aim_dir * 12.0
	get_tree().current_scene.add_child(proj)
	AudioManager.play("attack")

	var anim_name := _resolve_anim("attack")
	sprite.speed_scale = _attack_speed_scale_for(anim_name)
	sprite.play(anim_name)


func _attack_speed_scale_for(anim_name: String) -> float:
	# Keep the swing animation's real playtime locked to the actual
	# cooldown (attack_cooldown.wait_time, already adjusted for gear's
	# attack_speed_bonus) instead of always playing at 1x. Without this,
	# any character whose natural frame_count/fps runtime differs from
	# ATTACK_COOLDOWN_BASE drifts out of sync with the cooldown -- and
	# attack-speed gear, which only shortens the cooldown, would have no
	# visible effect once the cooldown drops below the animation's fixed
	# natural duration.
	var frames := sprite.sprite_frames
	if frames == null or not frames.has_animation(anim_name):
		return 1.0
	var frame_count := frames.get_frame_count(anim_name)
	var base_fps := frames.get_animation_speed(anim_name)
	if frame_count <= 0 or base_fps <= 0.0 or attack_cooldown.wait_time <= 0.0:
		return 1.0
	var natural_duration := float(frame_count) / base_fps
	return natural_duration / attack_cooldown.wait_time


func _on_sprite_animation_finished() -> void:
	if sprite.animation.begins_with("attack"):
		is_attacking = false
		# Cooldown may have already elapsed while this (longer) swing
		# animation was still playing -- fire the queued next attack now
		# instead of waiting on a timer that already fired.
		if GlobalState.auto_attack_enabled and can_attack and not is_dead:
			_try_attack()


func _on_attack_cooldown_timeout() -> void:
	can_attack = true
	if GlobalState.auto_attack_enabled and not is_dead and not is_attacking:
		_try_attack()


func _on_skill_button_pressed() -> void:
	_try_skill()


func _try_skill() -> void:
	if is_dead or is_attacking:
		return
	if skill_cooldown_remaining > 0.0:
		return
	var skill := SkillDatabase.get_skill(GlobalState.selected_character, level)
	if skill.is_empty():
		return

	is_attacking = true
	skill_cooldown_remaining = float(skill.get("cooldown", 8.0))

	var dmg := roundi(total_attack_damage() * float(skill.get("damage_multiplier", 2.0)))
	var crit := randf() < crit_chance
	if crit:
		dmg *= 2

	var target_pos := _skill_target_position(skill)
	var radius := float(skill.get("radius", 60.0))
	_deal_aoe_damage(target_pos, dmg, radius, crit)
	_spawn_skill_effect(skill, target_pos + SKILL_EFFECT_HEAD_OFFSET, radius)
	add_camera_shake(HIT_SHAKE_STRENGTH * 1.5)
	AudioManager.play("attack")

	var anim_name := _resolve_anim("attack")
	sprite.speed_scale = 1.0
	sprite.play(anim_name)


# The character sprite sheets have no dedicated skill-cast animation (mage
# doesn't even have full directional attack poses -- see CHARACTER_DATA's
# comment), so the skill's own icon art (already extracted from
# skill-design.png) is used as a pop-in/fade world-space effect at the cast
# location instead of trying to build a whole new animation set.
func _spawn_skill_effect(skill: Dictionary, pos: Vector2, radius: float) -> void:
	var icon_path: String = skill.get("icon", "")
	if icon_path == "":
		return
	var tex: Texture2D = load(icon_path)
	if tex == null:
		return
	var effect := preload("res://scenes/skill_effect.tscn").instantiate()
	get_tree().current_scene.add_child(effect)
	effect.global_position = pos
	effect.setup(tex, radius * 1.8)


# Flame Slash searches at roughly its melee knife range; Meteor searches
# much further out, matching its ranged-spell identity.
func _skill_search_range(skill: Dictionary) -> float:
	var is_meteor: bool = skill.get("id", "") == "meteor"
	return 400.0 if is_meteor else 150.0


func _find_nearest_enemy_in_range(search_range: float) -> Node2D:
	var nearest: Node2D = null
	var nearest_dist := search_range
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		var d := global_position.distance_to(enemy.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = enemy
	return nearest


# Both skills target the nearest enemy in range so the damage and the
# visual effect actually land on the foe being hit, not just somewhere near
# the player -- falls back to a point in front of the player only when
# nothing's in range (e.g. a manual cast swinging at empty air), so the
# skill still has somewhere sensible to land.
func _skill_target_position(skill: Dictionary) -> Vector2:
	var is_meteor: bool = skill.get("id", "") == "meteor"
	var nearest := _find_nearest_enemy_in_range(_skill_search_range(skill))
	if nearest:
		return nearest.global_position
	var fallback_dist := 200.0 if is_meteor else 40.0
	return global_position + facing_direction * fallback_dist


# Same enemy-hurtbox shape-query approach as thrown_bomb.gd's
# _deal_area_damage() -- proven AoE pattern, reused rather than reinvented.
func _deal_aoe_damage(pos: Vector2, damage: int, radius: float, is_crit: bool) -> void:
	var space_state := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, pos)
	query.collision_mask = 8  # enemy hurtbox layer
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var results := space_state.intersect_shape(query, 32)
	for result in results:
		var hurtbox: Area2D = result["collider"]
		var target := hurtbox.get_parent()
		if target and target.has_method("take_damage"):
			target.take_damage(damage, is_crit)
			if randf() < stun_chance and target.has_method("apply_stun"):
				target.apply_stun(1.0)


func _update_skill_cooldown_display() -> void:
	var skill := SkillDatabase.get_skill(GlobalState.selected_character, level)
	var label: String
	if skill.is_empty():
		label = "Skill: Locked (Lv. %d)" % SkillDatabase.SKILL_UNLOCK_LEVEL
	else:
		label = "Skill: %s" % skill.get("name", "?")
		if skill_cooldown_remaining > 0.0:
			label += " (%.1fs)" % skill_cooldown_remaining
	skill_label.text = label
	skill_use_button.disabled = skill.is_empty()

	var passive := SkillDatabase.get_passive_info(GlobalState.selected_character)
	var passive_stats := SkillDatabase.get_passive_stats(GlobalState.selected_character, level)
	var stat_key: String = passive.get("stat", "")
	var stat_value: float = passive_stats.get(stat_key, 0.0)
	passive_label.text = "Passive: %s (+%d %s)" % [passive.get("name", "?"), roundi(stat_value), stat_key]
	passive_label.tooltip_text = passive.get("description", "")


func total_attack_damage() -> int:
	return BASE_ATTACK_DAMAGE + (level - 1) + weapon_atk_bonus


func xp_to_next_level() -> int:
	# x3 across the board to slow overall leveling pace, plus an extra
	# per-level surcharge past 20 so high levels take noticeably longer still.
	var required := float(15 + (level - 1) * 10) * XP_REQUIREMENT_MULTIPLIER
	if level > HIGH_LEVEL_XP_THRESHOLD:
		required *= 1.0 + (level - HIGH_LEVEL_XP_THRESHOLD) * HIGH_LEVEL_XP_SURCHARGE
	return roundi(required)


func _xp_penalty_multiplier(source_level: int) -> float:
	# Killing enemies well below the player's own level gives diminishing XP
	# (a "trivial/grey mob" penalty) that hard-zeroes out past a wide enough
	# gap, so grinding a low-tier map forever cannot out-level it indefinitely
	# the way it could when XP was just the enemy's flat HP value.
	var gap := level - source_level
	if gap >= 14:
		return 0.0
	elif gap >= 10:
		return 0.08
	elif gap >= 6:
		return 0.25
	elif gap >= 3:
		return 0.6
	return 1.0


func gain_xp(amount: int, source_level: int = -1) -> void:
	if level >= MAX_LEVEL:
		return
	if source_level > 0:
		amount = roundi(amount * _xp_penalty_multiplier(source_level))
		if amount <= 0:
			return
	xp += amount
	var leveled_up := false
	var old_passive_hp_bonus := _total_hp_bonus()
	while level < MAX_LEVEL and xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		max_health += HP_PER_LEVEL
		health += HP_PER_LEVEL
		leveled_up = true
		print("Level up! Now level ", level, " (damage: ", level, ")")
	if leveled_up:
		AudioManager.play("level_up")
		# Skill unlock/upgrade and passive stat scaling (see skill_database.gd)
		# both key off level, so gear-equip-time recalculation alone would go
		# stale between now and the next equip/unequip action.
		max_health += _total_hp_bonus() - old_passive_hp_bonus
		health = clampi(health, 0, max_health)
		_recalculate_equipment_stats()
	_update_hud()


func take_damage(amount: int) -> void:
	if is_dead:
		return
	var reduced_amount: int = max(amount - defense, 1)
	health = max(health - reduced_amount, 0)
	print("Player hit! HP: ", health, "/", max_health)
	_update_hud()
	_spawn_damage_number(reduced_amount)
	add_camera_shake(HIT_SHAKE_STRENGTH)
	AudioManager.play("hit")
	modulate = Color(2, 2, 2, 1)
	await get_tree().create_timer(0.1).timeout
	if is_dead:
		return
	modulate = Color(1, 1, 1, 1)
	if health <= 0:
		_die()


func _spawn_damage_number(amount: int) -> void:
	var number := preload("res://scenes/damage_number.tscn").instantiate()
	number.amount = amount
	number.is_player_damage = true
	number.global_position = global_position + Vector2(0, -40)
	get_tree().current_scene.add_child(number)


func _update_hud() -> void:
	GlobalState.player_level = level
	GlobalState.player_xp = xp
	GlobalState.player_max_health = max_health
	GlobalState.player_health = health
	health_bar_fill.scale.x = float(health) / float(max_health)
	hud_level_label.text = "Lv. %d" % level
	hud_health_label.text = "HP: %d/%d" % [health, max_health]
	hud_health_bar.max_value = max_health
	hud_health_bar.value = health
	hud_xp_label.text = "XP: %d/%d" % [xp, xp_to_next_level()]
	hud_xp_bar.max_value = xp_to_next_level()
	hud_xp_bar.value = xp
	_update_quick_slot_cooldown_display()
	GlobalState.save_game()


func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	modulate = Color(0.4, 0.4, 0.4, 1)
	print("Game Over")
	AudioManager.play("player_death")
	death_info_label.text = "You reached Level %d" % level
	death_screen.visible = true
	get_tree().paused = true
	for remaining in range(RESPAWN_SECONDS, 0, -1):
		death_countdown_label.text = "Respawning in %d..." % remaining
		await get_tree().create_timer(1.0).timeout
	_respawn()


func _respawn() -> void:
	health = max_health
	is_dead = false
	modulate = Color(1, 1, 1, 1)
	var spawn := get_tree().get_first_node_in_group("spawn_point")
	if is_instance_valid(spawn):
		global_position = spawn.global_position
	death_screen.visible = false
	get_tree().paused = false
	_update_hud()
	_restore_boss_and_guardian_health()


func _restore_boss_and_guardian_health() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not is_instance_valid(enemy):
			continue
		if enemy.is_final_boss or enemy.gate_boss_id != "" or enemy.is_guardian:
			enemy.restore_full_health()


func trigger_victory() -> void:
	AudioManager.play("victory")
	victory_info_label.text = "You reached Level %d as the slayer of The Withered Sovereign" % level
	victory_screen.visible = true
	get_tree().paused = true


func _on_continue_playing_pressed() -> void:
	victory_screen.visible = false
	get_tree().paused = false


func _on_new_game_plus_pressed() -> void:
	GlobalState.start_new_game_plus()
	victory_screen.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/map.tscn")


func add_item_to_inventory(item_id: String, amount: int = 1) -> bool:
	if ItemDatabase.get_item(item_id).get("slot", "") != "":
		# Gear: each copy rolls its own independent stats and becomes its own
		# distinguishable instance (see global_state.gd) rather than being
		# folded into a flat item_id -> count stack.
		var last_instance := ""
		for i in range(maxi(amount, 1)):
			last_instance = GlobalState.gear_add(item_id)
		_maybe_prompt_equip(last_instance)
	else:
		var added := GlobalState.storage_add(item_id, amount)
		if added == 0:
			return false
		_maybe_auto_assign_quick_slot(item_id)
	if inventory_ui.visible:
		inventory_ui.refresh()
	_update_quick_slot_cooldown_display()
	GlobalState.save_game()
	return true


func _maybe_auto_assign_quick_slot(item_id: String) -> void:
	var item := ItemDatabase.get_item(item_id)
	var category: String = item.get("category", "")
	if not AUTO_QUICK_SLOT_CATEGORIES.has(category):
		return
	if GlobalState.quick_slots.get(category, "") == "":
		GlobalState.quick_slots[category] = item_id


func _maybe_prompt_equip(instance_id: String) -> void:
	if instance_id == "":
		return
	var item_id := GlobalState.gear_instance_item_id(instance_id)
	var item := ItemDatabase.get_item(item_id)
	var slot: String = item.get("slot", "")
	if slot == "":
		return  # not equippable gear (consumable/material/quest item)
	var equipped_instance: String = GlobalState.equipped.get(slot, "")
	var is_upgrade := false
	if equipped_instance == "":
		is_upgrade = true
	else:
		var current_item_id := GlobalState.gear_instance_item_id(equipped_instance)
		var current_rarity: String = ItemDatabase.get_item(current_item_id).get("rarity", "common")
		var new_rarity: String = item.get("rarity", "common")
		is_upgrade = RARITY_RANK.get(new_rarity, 0) > RARITY_RANK.get(current_rarity, 0)
	if not is_upgrade:
		return
	_pending_equip_instance_id = instance_id
	var verb := "Equip" if equipped_instance == "" else "Equip upgrade"
	equip_prompt.dialog_text = "%s: %s (%s)?" % [verb, item.get("name", "?"), str(item.get("rarity", "common")).capitalize()]
	get_tree().paused = true
	equip_prompt.popup_centered()


func _on_equip_prompt_confirmed() -> void:
	if _pending_equip_instance_id != "":
		equip_item(_pending_equip_instance_id)
		_pending_equip_instance_id = ""


func _on_equip_prompt_canceled() -> void:
	_pending_equip_instance_id = ""


func _on_equip_prompt_visibility_changed() -> void:
	# AcceptDialog can hide() itself before or after emitting confirmed/
	# canceled depending on path, so this only handles unpausing -- clearing
	# _pending_equip_instance_id is the job of the confirmed/canceled handlers above,
	# since relying on visibility timing here caused a real race (the dialog
	# hid and cleared the pending id before "confirmed" ran, silently
	# dropping the equip).
	if equip_prompt.visible:
		return  # this fired because the dialog just opened, not closed
	get_tree().paused = false


func equip_item(instance_id: String) -> void:
	var item_id := GlobalState.gear_instance_item_id(instance_id)
	var item := ItemDatabase.get_item(item_id)
	if item.is_empty():
		return
	var slot: String = item.get("slot", "")
	if slot == "":
		return
	var previous_instance: String = GlobalState.equipped.get(slot, "")
	var old_hp_total := _total_hp_bonus()

	GlobalState.gear_take_from_bag(instance_id)
	if previous_instance != "":
		# The previously-equipped copy goes back into the bag with its own
		# already-rolled stats intact -- swapping gear never rerolls it.
		GlobalState.gear_move_to_bag(previous_instance)
	GlobalState.equipped[slot] = instance_id

	var new_hp_total := _total_hp_bonus()
	max_health += new_hp_total - old_hp_total
	health = clampi(health, 0, max_health)

	_recalculate_equipment_stats()
	_update_hud()


func unequip_slot(slot: String) -> void:
	var instance_id: String = GlobalState.equipped.get(slot, "")
	if instance_id == "":
		return
	var old_hp_total := _total_hp_bonus()

	GlobalState.equipped[slot] = ""
	GlobalState.gear_move_to_bag(instance_id)

	var new_hp_total := _total_hp_bonus()
	max_health += new_hp_total - old_hp_total
	health = clampi(health, 0, max_health)

	_recalculate_equipment_stats()
	_update_hud()


func assign_quick_slot(category: String, item_id: String) -> void:
	if not GlobalState.quick_slots.has(category):
		return
	var item := ItemDatabase.get_item(item_id)
	if item.get("category", "") != category:
		return
	GlobalState.quick_slots[category] = item_id
	_update_quick_slot_cooldown_display()
	GlobalState.save_game()


func unassign_quick_slot(category: String) -> void:
	if GlobalState.quick_slots.has(category):
		GlobalState.quick_slots[category] = ""
		_update_quick_slot_cooldown_display()
		GlobalState.save_game()


func discard_item(item_id: String) -> void:
	var count: int = GlobalState.storage.get(item_id, 0)
	if count <= 0:
		return
	GlobalState.storage_remove(item_id, count)
	GlobalState.save_game()


func discard_gear_instance(instance_id: String) -> void:
	GlobalState.gear_discard_instance(instance_id)
	GlobalState.save_game()


func _use_quick_slot(category: String) -> void:
	var item_id: String = GlobalState.quick_slots.get(category, "")
	if item_id == "":
		return
	if GlobalState.storage.get(item_id, 0) <= 0:
		return
	if quick_slot_cooldowns.get(category, 0.0) > 0.0:
		return

	var item := ItemDatabase.get_item(item_id)
	GlobalState.storage_remove(item_id, 1)
	_dispatch_consumable(item_id, item)
	quick_slot_cooldowns[category] = item.get("cooldown", 0.0)
	_update_hud()
	if inventory_ui.visible:
		inventory_ui.refresh()


func _dispatch_consumable(item_id: String, item: Dictionary) -> void:
	match item.get("use_action", ""):
		"heal":
			var amount := int(ItemDatabase.get_stat(item_id, "heal_amount"))
			health = mini(health + amount, max_health)
		"throw_bomb":
			_throw_bomb(item)
		"buff_speed":
			var bonus := ItemDatabase.get_stat(item_id, "speed_bonus")
			var duration := ItemDatabase.get_stat(item_id, "duration")
			_apply_speed_buff(bonus, duration)


func _apply_speed_buff(bonus: float, duration: float) -> void:
	_buff_speed_token += 1
	var my_token := _buff_speed_token
	buff_speed_bonus = bonus
	await get_tree().create_timer(duration).timeout
	if my_token != _buff_speed_token:
		return
	buff_speed_bonus = 0.0


func _throw_bomb(item: Dictionary) -> void:
	var stats: Dictionary = item.get("stats", {})
	var bomb_scene: PackedScene = preload("res://scenes/thrown_bomb.tscn")
	var bomb := bomb_scene.instantiate()
	bomb.direction = facing_direction
	bomb.damage = int(stats.get("damage", 0))
	bomb.radius = float(stats.get("radius", 0.0))
	bomb.global_position = global_position + facing_direction * 24.0
	get_tree().current_scene.add_child(bomb)


func _update_quick_slot_cooldown_display() -> void:
	quick_slot_heal_label.text = _quick_slot_text("heal")
	quick_slot_throwable_label.text = _quick_slot_text("throwable")
	quick_slot_buff_label.text = _quick_slot_text("buff")


func _quick_slot_text(category: String) -> String:
	var item_id: String = GlobalState.quick_slots.get(category, "")
	var label: String = category.capitalize()
	if item_id == "":
		label += ": -"
	else:
		var count: int = GlobalState.storage.get(item_id, 0)
		var item := ItemDatabase.get_item(item_id)
		label += ": %s x%d" % [item.get("name", "?"), count]
	var cd: float = quick_slot_cooldowns.get(category, 0.0)
	if cd > 0.0:
		label += " (%.1fs)" % cd
	return label


func _total_hp_bonus() -> int:
	var total := 0
	for slot in GlobalState.equipped.keys():
		var instance_id: String = GlobalState.equipped[slot]
		if instance_id != "":
			total += int(GlobalState.gear_instance_stat(instance_id, "hp"))
	var passive_stats := SkillDatabase.get_passive_stats(GlobalState.selected_character, level)
	total += int(passive_stats.get("hp", 0))
	return total


func _recalculate_equipment_stats() -> void:
	var atk := 0
	var def: int = int(character_data.get("base_defense", 0))
	var crit := 0.0
	var stun := 0.0
	var atk_speed := 0.0
	var spd := 0.0
	for slot in GlobalState.equipped.keys():
		var instance_id: String = GlobalState.equipped[slot]
		if instance_id == "":
			continue
		atk += int(GlobalState.gear_instance_stat(instance_id, "atk"))
		def += int(GlobalState.gear_instance_stat(instance_id, "def"))
		crit += GlobalState.gear_instance_stat(instance_id, "crit_chance")
		stun += GlobalState.gear_instance_stat(instance_id, "stun_chance")
		atk_speed += GlobalState.gear_instance_stat(instance_id, "attack_speed")
		spd += GlobalState.gear_instance_stat(instance_id, "speed")
	# Passive skill (see skill_database.gd) is always active, on top of gear,
	# and scales with character level (passive_level_for()).
	var passive_stats := SkillDatabase.get_passive_stats(GlobalState.selected_character, level)
	atk += int(passive_stats.get("atk", 0))
	def += int(passive_stats.get("def", 0))
	crit += passive_stats.get("crit_chance", 0.0)
	stun += passive_stats.get("stun_chance", 0.0)
	atk_speed += passive_stats.get("attack_speed", 0.0)
	spd += passive_stats.get("speed", 0.0)
	weapon_atk_bonus = atk
	defense = def
	crit_chance = crit
	stun_chance = stun
	attack_speed_bonus = clampf(atk_speed, 0.0, 0.9)
	accessory_speed_bonus = spd
