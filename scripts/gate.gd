extends Area2D

@export var required_level: int = 10
@export var next_map_path: String = "res://scenes/map2.tscn"
@export var required_boss_id: String = ""
@export var locked_color: Color = Color(0.5, 0.5, 0.5, 0.7)
@export var unlocked_color: Color = Color(0.6, 0.3, 1.0, 0.9)
@export var label_text_override: String = ""

@onready var core: Polygon2D = $Core
@onready var glow1: Polygon2D = $Glow1
@onready var glow2: Polygon2D = $Glow2
@onready var label: Label = $Label

var _unlocked := false


func _ready() -> void:
	add_to_group("gate")
	label.text = label_text_override if label_text_override != "" else "Lv. %d Required" % required_level
	body_entered.connect(_on_body_entered)
	_apply_visual(false)


func _process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var meets_requirement := false
	if is_instance_valid(player):
		meets_requirement = _requirement_met(player)
	if meets_requirement != _unlocked:
		_unlocked = meets_requirement
		_apply_visual(_unlocked)


func _requirement_met(player: Node) -> bool:
	if player.level < required_level:
		return false
	if required_boss_id != "" and not GlobalState.has_defeated_gate_boss(required_boss_id):
		return false
	return true


func _apply_visual(unlocked: bool) -> void:
	var c := unlocked_color if unlocked else locked_color
	core.color = c
	glow1.color = Color(c.r, c.g, c.b, c.a * 0.35)
	glow2.color = Color(c.r, c.g, c.b, c.a * 0.15)


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if not _requirement_met(body):
		return
	AudioManager.play("gate")
	GlobalState.current_map_path = next_map_path
	GlobalState.save_game()
	get_tree().change_scene_to_file(next_map_path)
