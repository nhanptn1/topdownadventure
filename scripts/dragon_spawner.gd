extends Node2D

const DragonScene := preload("res://scenes/enemy.tscn")
const BODY_QUERY_RADIUS := 45.0
const MAX_PLACEMENT_ATTEMPTS := 24

@export var map_size: Vector2 = Vector2(1920, 1200)
@export var spawn_margin: float = 100.0
@export var dragon_count: int = 8
@export var respawn_delay: float = 10.0
@export var min_player_distance: float = 220.0
@export var species: String = "dragon"
@export var animal_name: String = "Dragon"
@export var is_aggressive: bool = true
@export var min_level: int = 1
@export var max_level: int = 5
@export var body_tint: Color = Color(1, 1, 1, 1)
@export var wander_radius: float = 60.0
@export var drop_chance: float = 0.35
@export var is_guardian: bool = false
@export var enemy_scale: float = 1.0


func _ready() -> void:
	await get_tree().physics_frame
	for i in range(dragon_count):
		_spawn_dragon()
		await get_tree().physics_frame


func _spawn_dragon() -> void:
	if not is_inside_tree():
		return
	var dragon := DragonScene.instantiate()
	dragon.species = species
	dragon.animal_name = animal_name
	dragon.is_aggressive = is_aggressive
	dragon.min_level = min_level
	dragon.max_level = max_level
	dragon.body_tint = body_tint
	dragon.wander_radius = wander_radius
	dragon.drop_chance = drop_chance
	dragon.is_guardian = is_guardian
	dragon.scale = Vector2(enemy_scale, enemy_scale)
	dragon.global_position = _find_spawn_position()
	add_child(dragon)
	dragon.defeated.connect(_on_dragon_defeated)


func _on_dragon_defeated() -> void:
	get_tree().create_timer(respawn_delay).timeout.connect(_spawn_dragon)


func _find_spawn_position() -> Vector2:
	var space_state := get_world_2d().direct_space_state
	var player := get_tree().get_first_node_in_group("player")
	for attempt in range(MAX_PLACEMENT_ATTEMPTS):
		var candidate := global_position + Vector2(
			randf_range(spawn_margin, map_size.x - spawn_margin),
			randf_range(spawn_margin, map_size.y - spawn_margin)
		)
		if is_instance_valid(player) and candidate.distance_to(player.global_position) < min_player_distance:
			continue
		var shape := CircleShape2D.new()
		shape.radius = BODY_QUERY_RADIUS
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = shape
		query.transform = Transform2D(0, candidate)
		query.collision_mask = 3
		var result := space_state.intersect_shape(query, 1)
		if result.is_empty():
			return candidate
	return global_position + map_size * 0.5
