extends Area2D

const STUN_DURATION := 1.0

@export var max_range: float = 300.0

var direction: Vector2 = Vector2.RIGHT
var speed: float = 500.0
var damage: int = 1
var stun_chance: float = 0.0
var is_crit: bool = false

var _has_hit := false
var _spawn_position: Vector2


func _ready() -> void:
	rotation = direction.angle()
	_spawn_position = global_position
	_setup_trail()
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(1.5).timeout.connect(_on_lifetime_expired)


func _setup_trail() -> void:
	var trail := Line2D.new()
	trail.width = 5.0
	trail.points = PackedVector2Array([Vector2(-32, 0), Vector2(-16, 0), Vector2(0, 0)])
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 0.0))
	gradient.set_color(1, Color(1, 1, 1, 0.55))
	trail.gradient = gradient
	add_child(trail)
	move_child(trail, 0)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	if global_position.distance_to(_spawn_position) >= max_range:
		_on_lifetime_expired()


func _on_area_entered(area: Area2D) -> void:
	if _has_hit:
		return
	var target := area.get_parent()
	if target and target.has_method("take_damage"):
		_has_hit = true
		target.take_damage(damage, is_crit)
		if randf() < stun_chance and target.has_method("apply_stun"):
			target.apply_stun(STUN_DURATION)
		queue_free()


func _on_body_entered(_body: Node) -> void:
	queue_free()


func _on_lifetime_expired() -> void:
	if not is_queued_for_deletion():
		queue_free()
