extends CanvasLayer

const SLOTS := ["weapon", "armor", "accessory"]
const CATEGORIES := ["heal", "throwable", "buff"]
const ICON_SIZE := 44
const ICON_PADDING := 6

@onready var player: Node = get_parent()
@onready var stats_label: Label = $Center/PanelBG/Margin/Content/BodyRow/LeftColumn/StatsLabel
@onready var equip_slots_container: VBoxContainer = $Center/PanelBG/Margin/Content/BodyRow/LeftColumn/EquipSlots
@onready var bag_section: VBoxContainer = $Center/PanelBG/Margin/Content/BodyRow/RightScroll/RightList/BagSection
@onready var quick_slots_container: VBoxContainer = $Center/PanelBG/Margin/Content/BodyRow/RightScroll/RightList/BagSection/QuickSlotContainer
@onready var inventory_list_container: VBoxContainer = $Center/PanelBG/Margin/Content/BodyRow/RightScroll/RightList/BagSection/InvList
@onready var craft_section: VBoxContainer = $Center/PanelBG/Margin/Content/BodyRow/RightScroll/RightList/CraftSection
@onready var craft_list_container: VBoxContainer = $Center/PanelBG/Margin/Content/BodyRow/RightScroll/RightList/CraftSection/CraftList
@onready var discard_confirm: ConfirmationDialog = $DiscardConfirm

var _pending_discard_id: String = ""
var _pending_discard_instance_id: String = ""
var _craft_mode: bool = false


func _ready() -> void:
	discard_confirm.confirmed.connect(_on_discard_confirmed)


func _unhandled_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_I:
		close()


func open() -> void:
	visible = true
	get_tree().paused = true
	_craft_mode = false
	refresh()


func _on_craft_toggle_pressed() -> void:
	_craft_mode = not _craft_mode
	refresh()


func close() -> void:
	visible = false
	get_tree().paused = false


func refresh() -> void:
	_update_stats_summary()

	_clear_children(equip_slots_container)
	for slot in SLOTS:
		var instance_id: String = GlobalState.equipped.get(slot, "")
		equip_slots_container.add_child(_build_equip_row(slot, instance_id))

	_clear_children(quick_slots_container)
	for category in CATEGORIES:
		var item_id: String = GlobalState.quick_slots.get(category, "")
		quick_slots_container.add_child(_build_quick_slot_row(category, item_id))

	bag_section.visible = not _craft_mode
	craft_section.visible = _craft_mode

	_clear_children(inventory_list_container)
	# Gear: one row per individual rolled copy (not grouped by item id) so
	# multiple copies of the same item can show their own distinct stats and
	# be compared/equipped independently.
	for item_id in GlobalState.gear_bag.keys():
		for instance_id in GlobalState.gear_bag_instances(item_id):
			inventory_list_container.add_child(_build_gear_row(instance_id))
	for item_id in GlobalState.storage.keys():
		var item := ItemDatabase.get_item(item_id)
		var item_type: String = item.get("item_type", "")
		if item_type == "consumable":
			inventory_list_container.add_child(_build_consumable_row(item_id))
		else:
			inventory_list_container.add_child(_build_material_row(item_id))

	_clear_children(craft_list_container)
	for item_id in ItemDatabase.CRAFTING_RECIPES.keys():
		craft_list_container.add_child(_build_craft_row(item_id))


func _update_stats_summary() -> void:
	var total_atk: int = player.total_attack_damage()
	var lines := [
		"ATK: %d (weapon bonus +%d)" % [total_atk, player.weapon_atk_bonus],
		"DEF: %d" % player.defense,
		"Max HP: %d" % player.max_health,
		"Crit Chance: %d%%" % roundi(player.crit_chance * 100),
		"Stun Chance: %d%%" % roundi(player.stun_chance * 100),
		"Attack Speed: +%d%%" % roundi(player.attack_speed_bonus * 100),
		"Move Speed Bonus: +%d" % player.accessory_speed_bonus,
	]
	stats_label.text = "\n".join(lines)


func _build_equip_row(slot: String, instance_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var item_id: String = GlobalState.gear_instance_item_id(instance_id) if instance_id != "" else ""
	row.add_child(_make_icon_slot(item_id))
	var label := Label.new()
	label.custom_minimum_size = Vector2(120, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if instance_id == "":
		label.text = "%s\n(empty)" % slot.capitalize()
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	else:
		var item := ItemDatabase.get_item(item_id)
		label.text = "%s\n%s (%s)" % [slot.capitalize(), item.get("name", "?"), _format_stats(GlobalState.gear_instance_stats(instance_id))]
		label.add_theme_color_override("font_color", item.get("color", Color.WHITE))
		label.tooltip_text = item.get("description", "")
	row.add_child(label)

	if instance_id != "":
		var button := Button.new()
		button.text = "Unequip"
		button.pressed.connect(func() -> void:
			player.unequip_slot(slot)
			refresh()
		)
		row.add_child(button)
	return row


func _build_quick_slot_row(category: String, item_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(_make_icon_slot(item_id))
	var label := Label.new()
	label.custom_minimum_size = Vector2(200, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.clip_text = true
	if item_id == "":
		label.text = "%s: (none)" % category.capitalize()
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	else:
		var item := ItemDatabase.get_item(item_id)
		label.text = "%s: %s" % [category.capitalize(), item.get("name", "?")]
		label.add_theme_color_override("font_color", item.get("color", Color.WHITE))
		label.tooltip_text = item.get("description", "")
	row.add_child(label)

	if item_id != "":
		var button := Button.new()
		button.text = "Unassign"
		button.pressed.connect(func() -> void:
			player.unassign_quick_slot(category)
			refresh()
		)
		row.add_child(button)
	return row


func _build_gear_row(instance_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var item_id := GlobalState.gear_instance_item_id(instance_id)
	row.add_child(_make_icon_slot(item_id))
	var item := ItemDatabase.get_item(item_id)
	var label := Label.new()
	label.custom_minimum_size = Vector2(220, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.text = "%s (%s)" % [item.get("name", "?"), _format_stats(GlobalState.gear_instance_stats(instance_id))]
	label.add_theme_color_override("font_color", item.get("color", Color.WHITE))
	label.tooltip_text = item.get("description", "")
	row.add_child(label)

	var button := Button.new()
	button.text = "Equip"
	button.pressed.connect(func() -> void:
		player.equip_item(instance_id)
		refresh()
	)
	row.add_child(button)
	row.add_child(_make_gear_discard_button(instance_id, item))
	return row


func _build_craft_row(item_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(_make_icon_slot(item_id))
	var item := ItemDatabase.get_item(item_id)
	var recipe := ItemDatabase.get_recipe(item_id)
	var label := Label.new()
	label.custom_minimum_size = Vector2(260, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var cost_parts: Array[String] = []
	var affordable := true
	for material_id in recipe.keys():
		var need: int = recipe[material_id]
		var have: int = GlobalState.storage.get(material_id, 0)
		if have < need:
			affordable = false
		var mat_name: String = ItemDatabase.get_item(material_id).get("name", material_id)
		cost_parts.append("%s %d/%d" % [mat_name, have, need])
	# Mythic recipes are listed but stay locked outside NG+, mirroring
	# player.gd's craft_item() gate -- shown rather than hidden so players
	# know it exists as a reason to start NG+.
	var is_locked_mythic: bool = item.get("rarity", "") == "mythic" and GlobalState.ng_plus_level <= 0
	if is_locked_mythic:
		cost_parts.append("Requires New Game+")
		affordable = false
	label.text = "%s (%s)\n%s" % [item.get("name", "?"), str(item.get("rarity", "common")).capitalize(), ", ".join(cost_parts)]
	label.add_theme_color_override("font_color", item.get("color", Color.WHITE))
	label.tooltip_text = item.get("description", "")
	row.add_child(label)

	var button := Button.new()
	button.text = "Craft"
	button.disabled = not affordable
	button.pressed.connect(func() -> void:
		player.craft_item(item_id)
		refresh()
	)
	row.add_child(button)
	return row


func _build_consumable_row(item_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(_make_icon_slot(item_id))
	var item := ItemDatabase.get_item(item_id)
	var count: int = GlobalState.storage.get(item_id, 0)
	var label := Label.new()
	label.custom_minimum_size = Vector2(200, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.clip_text = true
	label.text = "%s x%d" % [item.get("name", "?"), count]
	label.add_theme_color_override("font_color", item.get("color", Color.WHITE))
	label.tooltip_text = item.get("description", "")
	row.add_child(label)

	var category: String = item.get("category", "")
	var button := Button.new()
	button.text = "Assign"
	button.tooltip_text = "Assign to %s quick slot" % category
	button.pressed.connect(func() -> void:
		player.assign_quick_slot(category, item_id)
		refresh()
	)
	row.add_child(button)
	row.add_child(_make_discard_button(item_id, item))
	return row


func _build_material_row(item_id: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(_make_icon_slot(item_id))
	var item := ItemDatabase.get_item(item_id)
	var count: int = GlobalState.storage.get(item_id, 0)
	var label := Label.new()
	label.custom_minimum_size = Vector2(200, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	label.clip_text = true
	label.text = "%s x%d" % [item.get("name", "?"), count]
	label.add_theme_color_override("font_color", item.get("color", Color.WHITE))
	label.tooltip_text = item.get("description", "")
	row.add_child(label)
	if item.get("item_type", "") != "quest":
		row.add_child(_make_discard_button(item_id, item))
	return row


func _make_discard_button(item_id: String, item: Dictionary) -> Button:
	var button := Button.new()
	button.text = "Discard"
	button.pressed.connect(func() -> void:
		_pending_discard_id = item_id
		_pending_discard_instance_id = ""
		discard_confirm.dialog_text = "Discard %s?" % item.get("name", "this item")
		discard_confirm.popup_centered()
	)
	return button


func _make_gear_discard_button(instance_id: String, item: Dictionary) -> Button:
	var button := Button.new()
	button.text = "Discard"
	button.pressed.connect(func() -> void:
		_pending_discard_instance_id = instance_id
		_pending_discard_id = ""
		discard_confirm.dialog_text = "Discard %s?" % item.get("name", "this item")
		discard_confirm.popup_centered()
	)
	return button


func _on_discard_confirmed() -> void:
	if _pending_discard_instance_id != "":
		player.discard_gear_instance(_pending_discard_instance_id)
		_pending_discard_instance_id = ""
		refresh()
	elif _pending_discard_id != "":
		player.discard_item(_pending_discard_id)
		_pending_discard_id = ""
		refresh()


func _make_icon_slot(item_id: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.13, 0.9)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(ICON_PADDING)
	style.set_border_width_all(2)
	style.border_color = ItemDatabase.get_item(item_id).get("color", Color(0.35, 0.35, 0.4, 1.0)) if item_id != "" else Color(0.35, 0.35, 0.4, 1.0)
	panel.add_theme_stylebox_override("panel", style)

	if item_id != "":
		var rect := TextureRect.new()
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var icon_path: String = ItemDatabase.get_item(item_id).get("icon", "")
		if icon_path != "":
			rect.texture = load(icon_path)
		panel.add_child(rect)
	return panel


func _format_stats(stats: Dictionary) -> String:
	var parts: Array[String] = []
	if stats.has("atk"):
		parts.append("ATK +%d" % stats["atk"])
	if stats.has("def"):
		parts.append("DEF +%d" % stats["def"])
	if stats.has("hp"):
		parts.append("HP +%d" % stats["hp"])
	if stats.has("speed"):
		parts.append("SPD +%d" % stats["speed"])
	if stats.has("crit_chance"):
		parts.append("Crit +%d%%" % roundi(stats["crit_chance"] * 100))
	if stats.has("stun_chance"):
		parts.append("Stun %d%%" % roundi(stats["stun_chance"] * 100))
	if stats.has("attack_speed"):
		parts.append("Atk Spd +%d%%" % roundi(stats["attack_speed"] * 100))
	return ", ".join(parts)


func _clear_children(container: Node) -> void:
	for child in container.get_children():
		child.queue_free()
