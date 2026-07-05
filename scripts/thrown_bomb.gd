extends Area2D

const LIFETIME := 1.2
const ENEMY_HURTBOX_MASK := 8

var direction: Vector2 = Vector2.RIGHT
var speed: float = 260.0
var damage: int = 0
var radius: float = 60.0

var _detonated := false


func _ready() -> void:
	rotation = direction.angle()
	get_tree().create_timer(LIFETIME).timeout.connect(_detonate)


func _physics_process(delta: float) -> void:
	if _detonated:
		return
	position += direction * speed * delta


func _detonate() -> void:
	if _detonated:
		return
	_detonated = true
	_deal_area_damage()
	queue_free()


func _deal_area_damage() -> void:
	var space_state := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = ENEMY_HURTBOX_MASK
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var results := space_state.intersect_shape(query, 32)
	for result in results:
		var hurtbox: Area2D = result["collider"]
		var target := hurtbox.get_parent()
		if target and target.has_method("take_damage"):
			target.take_damage(damage)
