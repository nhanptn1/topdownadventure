extends Node2D

const RISE_DISTANCE := 40.0
const DURATION := 0.7
const NORMAL_COLOR := Color(1, 1, 1, 1)
const CRIT_COLOR := Color(1, 0.6, 0.15, 1)
const PLAYER_HURT_COLOR := Color(1, 0.3, 0.3, 1)

@export var amount: int = 0
@export var is_crit: bool = false
@export var is_player_damage: bool = false

@onready var label: Label = $Label


func _ready() -> void:
	label.text = str(amount)
	if is_player_damage:
		label.add_theme_color_override("font_color", PLAYER_HURT_COLOR)
	elif is_crit:
		label.add_theme_color_override("font_color", CRIT_COLOR)
		label.add_theme_font_size_override("font_size", 22)
	else:
		label.add_theme_color_override("font_color", NORMAL_COLOR)

	position += Vector2(randf_range(-6.0, 6.0), 0.0)

	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - RISE_DISTANCE, DURATION) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, DURATION * 0.5).set_delay(DURATION * 0.5)
	tween.tween_callback(queue_free)
