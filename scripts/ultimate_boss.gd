extends CharacterBody2D

# The true final boss (reached after the map3 Dragon Sovereign fight, in the
# separate "final stage"). Adapted from a 3-phase HP-threshold boss template
# the user supplied (see plan/final-boss-gd.txt): phases are driven by HP%
# instead of a fixed timeline, each phase hits harder and faster, and phase
# transitions get a short "juice" beat (time-freeze + shake + scale pulse).
# Actively closes in on the player the whole time they're in the arena --
# unlike the gate bosses (which mostly hold position with a tiny wander),
# this is the one fight with nowhere to kite forever, so it keeps pressure
# on rather than waiting at a fixed spot.

enum Phase { PHASE_1, PHASE_2, PHASE_3, DEAD }

const CHASE_SPEED := 90.0
const CHASE_STOP_DISTANCE := 35.0

const PHASE2_HP_RATIO := 0.6
const PHASE3_HP_RATIO := 0.3
# Calibrated so a level-35 player at the best gear obtainable by this point
# (windcutter_bow + assassins_signet -> ~180.7 DPS) needs ~60s to clear
# 10840 HP (see docs/PROJECT_SUMMARY.md for the full derivation). Damage is
# calibrated the other way: at ~387 effective HP (dragonscale_armor's +15),
# a Phase 1 hit reduced by 8 defense takes ~10 unhealed hits to kill the
# player, escalating to ~5 hits by Phase 3.
const PHASE_ATTACK_DAMAGE := [45, 65, 90]
const PHASE_ATTACK_INTERVAL := [1.7, 1.2, 0.8]
const HIT_FLASH_DURATION := 0.1
const DEATH_FRAME_TIME := 0.12

# The "enraged" animation (Phase 2+) visually casts a bolt on frame 6 (0-
# indexed) -- an arm-extended orb the frame before, then the actual burst
# releases here. Firing off frame_changed instead of an independent timer
# keeps the shot locked to what's on screen instead of drifting out of sync.
const RANGED_CAST_FRAME := 6
const RANGED_DAMAGE_FACTOR := 0.6
const RANGED_PROJECTILE_SPEED := 260.0

@export var animal_name: String = "The Withered Sovereign"
@export var max_health: int = 10840
@export var level: int = 40
@export var drop_chance: float = 1.0
@export var bonus_drop_item_id: String = "ancient_relic"
@export var bonus_drop_amount: int = 1

# player.gd's _restore_boss_and_guardian_health() blind-accesses these three
# fields on every member of group "enemy" (no has()/has_method() guard), so
# they need to exist here even though this script has its own phase system
# instead of enemy.gd's is_final_boss/gate_boss_id/is_guardian toggles.
var is_final_boss: bool = true
var gate_boss_id: String = ""
var is_guardian: bool = false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var attack_area: Area2D = $AttackArea
@onready var attack_timer: Timer = $AttackTimer
@onready var hurtbox: Area2D = $Hurtbox
@onready var health_bar_fill: Polygon2D = $HealthBar/Fill
@onready var level_label: Label = $LevelLabel

var health: int
var phase: Phase = Phase.PHASE_1
var in_attack_range := false
var _is_dying := false


func _ready() -> void:
	if GlobalState.boss_defeated:
		set_physics_process(false)
		queue_free()
		return
	add_to_group("enemy")
	health = max_health
	level_label.text = "%s — Lv. %d" % [animal_name, level]
	_build_sprite_frames()
	sprite.play("idle")
	attack_area.body_entered.connect(_on_attack_body_entered)
	attack_area.body_exited.connect(_on_attack_body_exited)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.wait_time = PHASE_ATTACK_INTERVAL[Phase.PHASE_1]
	sprite.frame_changed.connect(_on_sprite_frame_changed)


func _physics_process(_delta: float) -> void:
	if phase == Phase.DEAD:
		return
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var to_player = player.global_position - global_position
	if to_player.length() > CHASE_STOP_DISTANCE:
		velocity = to_player.normalized() * CHASE_SPEED
		sprite.flip_h = to_player.x < 0.0
	else:
		velocity = Vector2.ZERO
	move_and_slide()


func _build_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	var groups := {"idle": 8, "enraged": 8, "death": 8}
	for anim_name in groups.keys():
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, anim_name != "death")
		frames.set_animation_speed(anim_name, 6.0 if anim_name != "death" else 1.0 / DEATH_FRAME_TIME)
		for i in range(1, groups[anim_name] + 1):
			var path := "res://assets/sprites/final_boss_%s_%d.png" % [anim_name, i]
			var tex: Texture2D = load(path)
			if tex == null:
				push_error("Missing sprite frame: " + path)
				continue
			frames.add_frame(anim_name, tex)
	sprite.sprite_frames = frames


func _on_attack_body_entered(body: Node) -> void:
	if phase == Phase.DEAD:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		in_attack_range = true
		body.take_damage(PHASE_ATTACK_DAMAGE[phase])
		attack_timer.start()


func _on_attack_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		in_attack_range = false
		attack_timer.stop()


func _on_attack_timer_timeout() -> void:
	if not in_attack_range or phase == Phase.DEAD:
		return
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.has_method("take_damage"):
		player.take_damage(PHASE_ATTACK_DAMAGE[phase])


func _on_sprite_frame_changed() -> void:
	if phase == Phase.DEAD:
		return
	if sprite.animation == "enraged" and sprite.frame == RANGED_CAST_FRAME:
		_fire_ranged_attack()


func _fire_ranged_attack() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	var dir: Vector2 = (player.global_position - global_position).normalized()
	var proj := preload("res://scenes/boss_projectile.tscn").instantiate()
	proj.direction = dir
	proj.speed = RANGED_PROJECTILE_SPEED
	proj.damage = roundi(PHASE_ATTACK_DAMAGE[phase] * RANGED_DAMAGE_FACTOR)
	proj.global_position = global_position
	get_tree().current_scene.add_child(proj)
	AudioManager.play("attack")


func take_damage(amount: int, is_crit: bool = false) -> void:
	if phase == Phase.DEAD:
		return
	health = maxi(health - amount, 0)
	health_bar_fill.scale.x = clamp(float(health) / float(max_health), 0.0, 1.0)
	_spawn_damage_number(amount, is_crit)
	AudioManager.play("hit")
	_flash_hit()
	if health <= 0:
		_enter_phase(Phase.DEAD)
		return
	var health_ratio := float(health) / float(max_health)
	if phase == Phase.PHASE_1 and health_ratio <= PHASE2_HP_RATIO:
		_enter_phase(Phase.PHASE_2)
	elif phase == Phase.PHASE_2 and health_ratio <= PHASE3_HP_RATIO:
		_enter_phase(Phase.PHASE_3)


func _flash_hit() -> void:
	sprite.modulate = Color(2, 2, 2, 1)
	await get_tree().create_timer(HIT_FLASH_DURATION).timeout
	if phase != Phase.DEAD:
		sprite.modulate = Color(1, 1, 1, 1)


func _enter_phase(new_phase: Phase) -> void:
	phase = new_phase
	match phase:
		Phase.PHASE_2:
			print(animal_name, " enters Phase 2 (", int(PHASE2_HP_RATIO * 100), "% HP) -- attacks speed up.")
			attack_timer.wait_time = PHASE_ATTACK_INTERVAL[Phase.PHASE_2]
			sprite.speed_scale = 1.0
			sprite.play("enraged")
			_phase_transition_juice()
		Phase.PHASE_3:
			print(animal_name, " enters Phase 3 (", int(PHASE3_HP_RATIO * 100), "% HP) -- enraged.")
			attack_timer.wait_time = PHASE_ATTACK_INTERVAL[Phase.PHASE_3]
			# The "enraged" clip (and the ranged bolt it casts on frame
			# RANGED_CAST_FRAME each loop) never got a Phase 3 speed-up on
			# its own -- it just kept playing at the Phase 2 pace, so the
			# ranged attack didn't get more dangerous the way melee does.
			# Scale it by the same ratio melee's cooldown speeds up by, so
			# both attack types escalate together.
			sprite.speed_scale = PHASE_ATTACK_INTERVAL[Phase.PHASE_2] / float(PHASE_ATTACK_INTERVAL[Phase.PHASE_3])
			_phase_transition_juice()
		Phase.DEAD:
			_die()


func _phase_transition_juice() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.has_method("add_camera_shake"):
		player.add_camera_shake(6.0)
	Engine.time_scale = 0.2
	var tween := create_tween()
	tween.tween_property(sprite, "scale", sprite.scale * 1.15, 0.15)
	tween.tween_property(sprite, "scale", sprite.scale, 0.15)
	tween.finished.connect(func(): Engine.time_scale = 1.0)


func _spawn_damage_number(amount: int, is_crit: bool) -> void:
	var number := preload("res://scenes/damage_number.tscn").instantiate()
	number.amount = amount
	number.is_crit = is_crit
	number.global_position = global_position + Vector2(0, -60)
	get_tree().current_scene.add_child(number)


func _die() -> void:
	if _is_dying:
		return
	_is_dying = true
	attack_timer.stop()
	hurtbox.set_deferred("monitoring", false)
	attack_area.set_deferred("monitoring", false)
	AudioManager.play("enemy_death")
	GlobalState.boss_defeated = true
	GlobalState.save_game()
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.has_method("add_camera_shake"):
		player.add_camera_shake(10.0)
	sprite.play("death")
	await get_tree().create_timer(DEATH_FRAME_TIME * 8).timeout
	_grant_rewards(player)
	if is_instance_valid(player) and player.has_method("trigger_victory"):
		player.trigger_victory()
	queue_free()


func _grant_rewards(player: Node) -> void:
	if is_instance_valid(player) and player.has_method("gain_xp"):
		player.gain_xp(max_health, level)
	_try_drop_item()
	_try_bonus_drop()


func _try_drop_item() -> void:
	if randf() >= drop_chance:
		return
	var item_id: String = ItemDatabase.roll_guardian_drop(3)
	if item_id == "":
		return
	var pickup := preload("res://scenes/item_pickup.tscn").instantiate()
	pickup.item_id = item_id
	pickup.global_position = global_position + Vector2(-20, 0)
	get_tree().current_scene.add_child(pickup)


func restore_full_health() -> void:
	if phase == Phase.DEAD:
		return
	health = max_health
	health_bar_fill.scale.x = 1.0
	phase = Phase.PHASE_1
	attack_timer.wait_time = PHASE_ATTACK_INTERVAL[Phase.PHASE_1]
	sprite.speed_scale = 1.0
	sprite.play("idle")


func _try_bonus_drop() -> void:
	if bonus_drop_item_id == "" or bonus_drop_amount <= 0:
		return
	var pickup := preload("res://scenes/item_pickup.tscn").instantiate()
	pickup.item_id = bonus_drop_item_id
	pickup.amount = bonus_drop_amount
	pickup.global_position = global_position + Vector2(20, 0)
	get_tree().current_scene.add_child(pickup)
