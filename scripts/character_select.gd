extends Control

@onready var controls_popup: Control = $ControlsPopup
@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var overwrite_confirm: ConfirmationDialog = $OverwriteConfirm

var _pending_character: String = ""


func _ready() -> void:
	continue_button.visible = GlobalState.has_save()


func _on_warrior_pressed() -> void:
	_select_character("warrior")


func _on_mage_pressed() -> void:
	_select_character("mage")


func _select_character(character: String) -> void:
	if GlobalState.has_save():
		_pending_character = character
		overwrite_confirm.popup_centered()
		return
	GlobalState.selected_character = character
	controls_popup.visible = true


func _on_overwrite_confirmed() -> void:
	GlobalState.selected_character = _pending_character
	_pending_character = ""
	controls_popup.visible = true


func _on_continue_pressed() -> void:
	if GlobalState.load_game():
		get_tree().change_scene_to_file(GlobalState.current_map_path)
	else:
		continue_button.visible = false


func _on_start_game_pressed() -> void:
	GlobalState.current_map_path = "res://scenes/map.tscn"
	get_tree().change_scene_to_file("res://scenes/map.tscn")
