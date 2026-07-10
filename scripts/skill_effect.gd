extends Node2D

const POP_DURATION := 0.18
const HOLD_DURATION := 0.12
const FADE_DURATION := 0.25

@onready var sprite: Sprite2D = $Sprite


# Must be called after this node is already in the tree (add_child first) so
# @onready var sprite is valid. target_size is the sprite's desired on-
# screen diameter in pixels -- the source icon textures are sized for a
# small HUD slot, not world-space, so they're rescaled to roughly match the
# skill's actual damage radius.
func setup(texture: Texture2D, target_size: float) -> void:
	sprite.texture = texture
	var native := maxf(texture.get_width(), texture.get_height())
	var final_scale := target_size / native if native > 0.0 else 1.0
	sprite.modulate.a = 0.0
	sprite.scale = Vector2(final_scale, final_scale) * 0.4

	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 1.0, POP_DURATION)
	tween.parallel().tween_property(sprite, "scale", Vector2(final_scale, final_scale), POP_DURATION) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(HOLD_DURATION)
	tween.tween_property(sprite, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(queue_free)
