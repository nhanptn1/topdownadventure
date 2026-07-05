extends Control

const WORLD_SIZE := Vector2(1920, 1200)
const REFRESH_INTERVAL := 0.1
const PLAYER_COLOR := Color(0.3, 0.9, 1.0, 1.0)
const ENEMY_COLOR := Color(1.0, 0.3, 0.3, 0.9)
const GATE_COLOR := Color(0.7, 0.4, 1.0, 1.0)
const SPAWN_COLOR := Color(0.3, 0.9, 0.5, 1.0)
const BORDER_COLOR := Color(1, 1, 1, 0.6)
const BG_COLOR := Color(0, 0, 0, 0.5)

var _refresh_timer := 0.0


func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= REFRESH_INTERVAL:
		_refresh_timer = 0.0
		queue_redraw()


func _draw() -> void:
	var s := size
	draw_rect(Rect2(Vector2.ZERO, s), BG_COLOR, true)
	draw_rect(Rect2(Vector2.ZERO, s), BORDER_COLOR, false, 1.5)

	for spawn in get_tree().get_nodes_in_group("spawn_point"):
		if is_instance_valid(spawn):
			draw_circle(_to_minimap(spawn.global_position, s), 3.0, SPAWN_COLOR)

	for gate in get_tree().get_nodes_in_group("gate"):
		if is_instance_valid(gate):
			draw_circle(_to_minimap(gate.global_position, s), 3.0, GATE_COLOR)

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			draw_circle(_to_minimap(enemy.global_position, s), 2.0, ENEMY_COLOR)

	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		draw_circle(_to_minimap(player.global_position, s), 3.5, PLAYER_COLOR)


func _to_minimap(world_pos: Vector2, mini_size: Vector2) -> Vector2:
	return Vector2(
		clampf(world_pos.x / WORLD_SIZE.x, 0.0, 1.0) * mini_size.x,
		clampf(world_pos.y / WORLD_SIZE.y, 0.0, 1.0) * mini_size.y
	)
