extends Area2D

# Fired by ultimate_boss.gd during its "enraged" cast animation. Separate from
# the player's own projectile.gd since that one hits enemies via area_entered
# against a Hurtbox Area2D -- the player has no such Hurtbox, so this instead
# detects the player's own physics body directly, the same way every enemy's
# melee AttackArea already does.

const LIFETIME := 4.0

var direction: Vector2 = Vector2.RIGHT
var speed: float = 260.0
var damage: int = 40

var _has_hit := false


func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(LIFETIME).timeout.connect(_on_lifetime_expired)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta


func _on_body_entered(body: Node) -> void:
	if _has_hit:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		_has_hit = true
		body.take_damage(damage)
		queue_free()


func _on_lifetime_expired() -> void:
	if not is_queued_for_deletion():
		queue_free()
