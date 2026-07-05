extends Area2D

const LIFETIME := 30.0
const TARGET_ICON_SIZE := 28.0
const BASE_GLOW_ALPHA := 0.35
const BASE_BEAM_ALPHA := 0.3
const RARITY_HIGHLIGHT_SCALE := {"common": 1.0, "rare": 1.25, "epic": 1.55}

@export var item_id: String = ""
@export var amount: int = 1

@onready var glow: Polygon2D = $Glow
@onready var light_beam: Polygon2D = $LightBeam
@onready var icon_sprite: Sprite2D = $Icon

var _time := 0.0


func _ready() -> void:
	var item := ItemDatabase.get_item(item_id)
	var color: Color = item.get("color", Color.WHITE)
	var rarity: String = item.get("rarity", "common")
	var highlight_scale: float = RARITY_HIGHLIGHT_SCALE.get(rarity, 1.0)

	glow.color = Color(color, BASE_GLOW_ALPHA)
	glow.scale = Vector2(highlight_scale, highlight_scale)

	light_beam.color = Color(color, BASE_BEAM_ALPHA)
	light_beam.scale = Vector2(highlight_scale, highlight_scale)

	var icon_path: String = item.get("icon", "")
	if icon_path != "":
		var tex: Texture2D = load(icon_path)
		icon_sprite.texture = tex
		var max_dim: float = maxf(tex.get_width(), tex.get_height())
		if max_dim > 0.0:
			var scale_factor := TARGET_ICON_SIZE / max_dim
			icon_sprite.scale = Vector2(scale_factor, scale_factor)
	body_entered.connect(_on_body_entered)
	get_tree().create_timer(LIFETIME).timeout.connect(_on_lifetime_expired)


func _process(delta: float) -> void:
	_time += delta
	icon_sprite.position.y = -4.0 + sin(_time * 3.0) * 3.0
	glow.color.a = clampf(BASE_GLOW_ALPHA + sin(_time * 4.0) * 0.12, 0.05, 1.0)
	light_beam.color.a = clampf(BASE_BEAM_ALPHA + sin(_time * 4.0 + 1.0) * 0.1, 0.05, 1.0)
	light_beam.rotation = sin(_time * 1.5) * 0.05


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("add_item_to_inventory"):
		var collected: bool = body.add_item_to_inventory(item_id, amount)
		if not collected:
			return
	AudioManager.play("pickup")
	queue_free()


func _on_lifetime_expired() -> void:
	if not is_queued_for_deletion():
		queue_free()
