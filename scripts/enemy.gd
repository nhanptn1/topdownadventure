extends CharacterBody2D

signal defeated

enum State { IDLE, CHASE, DEAD }

const CHASE_SPEED := 90.0
const WANDER_SPEED := 30.0
const STUN_TINT_DELAY := 0.15
const BASE_HP := 8
const HP_PER_LEVEL := 3
const BASE_ATTACK := 4
const ATTACK_PER_LEVEL := 2

const SPECIES_DATA := {
	"dragon": {
		"prefix": "dragon", "directional": true, "sprite_scale": 0.58,
		"frame_counts": {
			"idle_side": 2, "walk_side": 6, "attack_side": 2,
			"idle_back": 2, "walk_back": 6, "attack_back": 2,
			"idle_front": 2, "walk_front": 2, "attack_front": 2,
		},
		"anim_fps": {
			"idle_side": 4.0, "walk_side": 10.0, "attack_side": 14.0,
			"idle_back": 4.0, "walk_back": 10.0, "attack_back": 14.0,
			"idle_front": 4.0, "walk_front": 4.0, "attack_front": 14.0,
		},
	},
	"slime": {
		"prefix": "slime", "directional": false, "sprite_scale": 1.0,
		"frame_counts": {"idle": 1, "walk": 1, "attack": 1},
		"anim_fps": {"idle": 4.0, "walk": 4.0, "attack": 4.0},
	},
	"zombie": {
		"prefix": "zombie", "directional": false, "sprite_scale": 0.85,
		"frame_counts": {"idle": 1, "walk": 1, "attack": 1},
		"anim_fps": {"idle": 4.0, "walk": 4.0, "attack": 4.0},
	},
	"skeleton": {
		"prefix": "skeleton", "directional": false, "sprite_scale": 0.85,
		"frame_counts": {"idle": 1, "walk": 1, "attack": 1},
		"anim_fps": {"idle": 4.0, "walk": 4.0, "attack": 4.0},
	},
}

@export var species: String = "dragon"
@export var animal_name: String = "Dragon"
@export var is_aggressive: bool = true
@export var min_level: int = 1
@export var max_level: int = 5
@export var body_tint: Color = Color(1, 1, 1, 1)
@export var wander_radius: float = 60.0
@export var drop_chance: float = 0.35
@export var is_final_boss: bool = false
@export var gate_boss_id: String = ""
@export var is_guardian: bool = false
@export var bonus_max_health: int = 0
@export var bonus_attack_damage: int = 0
@export var bonus_drop_item_id: String = ""
@export var bonus_drop_amount: int = 0
@export var map_tier: int = 1

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_area: Area2D = $AttackArea
@onready var attack_timer: Timer = $AttackTimer
@onready var wander_timer: Timer = $WanderTimer
@onready var health_bar_fill: Polygon2D = $HealthBar/Fill
@onready var level_label: Label = $LevelLabel

var state: State = State.IDLE
var species_data: Dictionary
var level: int
var max_health: int
var health: int
var attack_damage: int
var target_player: Node2D = null
var potential_target: Node2D = null
var in_attack_range := false
var facing_direction := Vector2.DOWN

var home_position: Vector2
var wander_target: Vector2
var is_wandering := false

var is_stunned := false


func _ready() -> void:
	if is_final_boss and GlobalState.boss_defeated:
		set_physics_process(false)
		queue_free()
		return
	if gate_boss_id != "" and GlobalState.has_defeated_gate_boss(gate_boss_id):
		set_physics_process(false)
		queue_free()
		return
	add_to_group("enemy")
	species_data = SPECIES_DATA.get(species, SPECIES_DATA["dragon"])
	level = randi_range(min_level, max_level)
	max_health = BASE_HP + HP_PER_LEVEL * (level - 1) + bonus_max_health
	attack_damage = BASE_ATTACK + ATTACK_PER_LEVEL * (level - 1) + bonus_attack_damage
	health = max_health
	if is_final_boss or gate_boss_id != "":
		level_label.text = "%s — Lv. %d" % [animal_name, level]
	else:
		level_label.text = "Lv. %d" % level
	home_position = global_position
	_setup_sprite_frames()
	sprite.modulate = body_tint
	sprite.play(_resolve_anim("idle"))
	wander_timer.timeout.connect(_on_wander_timer_timeout)
	_schedule_next_wander()
	if is_aggressive:
		detection_area.body_entered.connect(_on_detection_body_entered)
		detection_area.body_exited.connect(_on_detection_body_exited)
		attack_area.body_entered.connect(_on_attack_body_entered)
		attack_area.body_exited.connect(_on_attack_body_exited)
		attack_timer.timeout.connect(_on_attack_timer_timeout)
	else:
		detection_area.monitoring = false
		attack_area.monitoring = false


func _setup_sprite_frames() -> void:
	var frames := SpriteFrames.new()
	var prefix: String = species_data["prefix"]
	var frame_counts: Dictionary = species_data["frame_counts"]
	var anim_fps: Dictionary = species_data["anim_fps"]
	for anim_name in frame_counts.keys():
		frames.add_animation(anim_name)
		frames.set_animation_loop(anim_name, true)
		frames.set_animation_speed(anim_name, anim_fps[anim_name])
		for i in range(1, frame_counts[anim_name] + 1):
			var path := "res://assets/sprites/%s_%s_%d.png" % [prefix, anim_name, i]
			var tex: Texture2D = load(path)
			if tex == null:
				push_error("Missing sprite frame: " + path)
				continue
			frames.add_frame(anim_name, tex)
	sprite.sprite_frames = frames
	var s: float = species_data["sprite_scale"]
	sprite.scale = Vector2(s, s)


func _resolve_anim(action: String) -> String:
	if not species_data["directional"]:
		return action
	if facing_direction == Vector2.UP:
		return action + "_back"
	elif facing_direction == Vector2.DOWN:
		return action + "_front"
	else:
		return action + "_side"


func _physics_process(_delta: float) -> void:
	if state == State.DEAD:
		return

	if is_stunned:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_animation()
		return

	if state == State.IDLE and potential_target != null:
		if _has_line_of_sight(potential_target):
			target_player = potential_target
			_stop_wandering()
			state = State.CHASE

	if state == State.CHASE and is_instance_valid(target_player):
		var to_target := target_player.global_position - global_position
		if in_attack_range:
			velocity = Vector2.ZERO
		else:
			velocity = to_target.normalized() * CHASE_SPEED
		if to_target.length() > 0.1:
			_update_facing(to_target)
	elif state == State.IDLE:
		_process_wander()
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	_update_animation()


func _process_wander() -> void:
	if not is_wandering:
		velocity = Vector2.ZERO
		return
	var to_target := wander_target - global_position
	if to_target.length() < 4.0:
		is_wandering = false
		velocity = Vector2.ZERO
		_schedule_next_wander()
	else:
		velocity = to_target.normalized() * WANDER_SPEED
		_update_facing(to_target)


func _schedule_next_wander() -> void:
	if not wander_timer.is_inside_tree():
		return
	wander_timer.wait_time = randf_range(2.0, 3.0)
	wander_timer.start()


func _stop_wandering() -> void:
	is_wandering = false
	wander_timer.stop()


func apply_stun(duration: float) -> void:
	if state == State.DEAD:
		return
	is_stunned = true
	# take_damage() flashes modulate white then reverts it ~0.1s after a hit;
	# delay the stun tint past that so it isn't immediately overwritten.
	await get_tree().create_timer(STUN_TINT_DELAY).timeout
	if state == State.DEAD:
		return
	modulate = Color(1, 1, 0.5, 1)
	await get_tree().create_timer(maxf(duration - STUN_TINT_DELAY, 0.0)).timeout
	if state == State.DEAD:
		return
	is_stunned = false
	modulate = Color(1, 1, 1, 1)


func _on_wander_timer_timeout() -> void:
	if state != State.IDLE:
		return
	if is_final_boss or gate_boss_id != "" or is_guardian:
		# Boss-tier enemies hold their placed position instead of wandering --
		# wander targets are picked blindly with no obstacle check, and a boss
		# arena's decor (rocks/mountains) sits close enough to a boss's small
		# wander_radius that it would repeatedly aim itself into a rock and
		# grind against it forever without ever reaching the target.
		_schedule_next_wander()
		return
	var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
	if offset.length() < 0.01:
		offset = Vector2.RIGHT
	wander_target = home_position + offset.normalized() * randf_range(10.0, wander_radius)
	is_wandering = true


func _update_facing(dir: Vector2) -> void:
	if absf(dir.x) >= absf(dir.y):
		facing_direction = Vector2.RIGHT if dir.x >= 0.0 else Vector2.LEFT
	else:
		facing_direction = Vector2.DOWN if dir.y >= 0.0 else Vector2.UP


func _update_animation() -> void:
	var action := "idle"
	if in_attack_range:
		action = "attack"
	elif velocity.length() > 1.0:
		action = "walk"

	var anim_name := _resolve_anim(action)
	sprite.flip_h = false
	if species_data["directional"]:
		if facing_direction == Vector2.LEFT or facing_direction == Vector2.RIGHT:
			sprite.flip_h = facing_direction == Vector2.LEFT
	else:
		sprite.flip_h = facing_direction.x < 0.0

	if sprite.animation != anim_name:
		sprite.play(anim_name)


func _has_line_of_sight(target: Node2D) -> bool:
	var space_state := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 2)
	query.exclude = [self]
	var result := space_state.intersect_ray(query)
	return result.is_empty()


func _on_detection_body_entered(body: Node) -> void:
	if state == State.DEAD:
		return
	if body.is_in_group("player"):
		potential_target = body


func _on_detection_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		state = State.IDLE
		target_player = null
		potential_target = null
		velocity = Vector2.ZERO
		_schedule_next_wander()
		# Boss-tier enemies reset to full HP once the player leaves detection
		# range too, not just on player death/respawn -- otherwise chipping
		# a boss down then retreating (to heal, reposition, or bail on a bad
		# pull) banks permanent progress on the fight for free.
		if is_final_boss or gate_boss_id != "" or is_guardian:
			restore_full_health()


func _on_attack_body_entered(body: Node) -> void:
	if state == State.DEAD:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		in_attack_range = true
		if not is_stunned:
			body.take_damage(attack_damage)
		attack_timer.start()


func _on_attack_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		in_attack_range = false
		attack_timer.stop()


func _on_attack_timer_timeout() -> void:
	if is_stunned:
		return
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.has_method("take_damage"):
		player.take_damage(attack_damage)


func take_damage(amount: int, is_crit: bool = false) -> void:
	if state == State.DEAD:
		return
	health -= amount
	print(animal_name, " hit! HP: ", health)
	health_bar_fill.scale.x = clamp(float(health) / float(max_health), 0.0, 1.0)
	_spawn_damage_number(amount, is_crit)
	AudioManager.play("hit")
	modulate = Color(2, 2, 2, 1)
	if state != State.CHASE:
		var attacker := get_tree().get_first_node_in_group("player")
		if is_instance_valid(attacker):
			target_player = attacker
			potential_target = attacker
			_stop_wandering()
			state = State.CHASE
	await get_tree().create_timer(0.1).timeout
	if state == State.DEAD:
		return
	modulate = Color(1, 1, 1, 1)
	if health <= 0:
		_die()


func restore_full_health() -> void:
	if state == State.DEAD:
		return
	health = max_health
	health_bar_fill.scale.x = 1.0


func _spawn_damage_number(amount: int, is_crit: bool) -> void:
	var number := preload("res://scenes/damage_number.tscn").instantiate()
	number.amount = amount
	number.is_crit = is_crit
	number.global_position = global_position + Vector2(0, -30)
	get_tree().current_scene.add_child(number)


func _die() -> void:
	state = State.DEAD
	attack_timer.stop()
	AudioManager.play("enemy_death")
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.has_method("gain_xp"):
		player.gain_xp(max_health, level)
		print(animal_name, " defeated! +", max_health, " XP (before any level-gap penalty)")
	if is_instance_valid(player) and player.has_method("add_camera_shake"):
		player.add_camera_shake(2.5)
	_try_drop_item()
	_try_bonus_drop()
	if is_final_boss:
		GlobalState.boss_defeated = true
		GlobalState.save_game()
		if is_instance_valid(player) and player.has_method("trigger_victory"):
			player.trigger_victory()
	if gate_boss_id != "":
		if not GlobalState.defeated_gate_bosses.has(gate_boss_id):
			GlobalState.defeated_gate_bosses.append(gate_boss_id)
		GlobalState.save_game()
	defeated.emit()
	queue_free()


func _try_drop_item() -> void:
	if randf() >= drop_chance:
		return
	var item_id := ItemDatabase.roll_guardian_drop(map_tier) if is_guardian else ItemDatabase.roll_random_drop(map_tier)
	if item_id == "":
		return
	var pickup := preload("res://scenes/item_pickup.tscn").instantiate()
	pickup.item_id = item_id
	pickup.global_position = global_position
	get_tree().current_scene.add_child(pickup)


func _try_bonus_drop() -> void:
	if bonus_drop_item_id == "" or bonus_drop_amount <= 0:
		return
	var pickup := preload("res://scenes/item_pickup.tscn").instantiate()
	pickup.item_id = bonus_drop_item_id
	pickup.amount = bonus_drop_amount
	pickup.global_position = global_position + Vector2(20, 0)
	get_tree().current_scene.add_child(pickup)
