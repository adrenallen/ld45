extends Control

func refresh():
	_clear_grid()
	_populate_grid()

func _clear_grid():
	for child in $StashGrid.get_children():
		child.queue_free()

func _populate_grid():
	var capacity = Inventory.BASE_STASH_SLOTS
	for i in range(capacity):
		var slot = _create_slot(i)
		$StashGrid.add_child(slot)

	# Update counter
	var used = Inventory.base_stash.size()
	$StashLabel.text = "Base Stash  (%d / %d)" % [used, capacity]

func _create_slot(index: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(94, 94)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	if index < Inventory.base_stash.size():
		var inst = Inventory.base_stash[index]
		var item_def = Items.get_item(inst.item_id)
		var rarity = item_def.get("rarity", 0)
		var color = Items.RARITY_COLORS.get(rarity, Color.WHITE)

		panel.add_theme_stylebox_override("panel", Base.make_slot_panel(color, true))

		# Item name
		var name_label = Label.new()
		name_label.text = item_def.get("name", "???")
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", color)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(name_label)

		# Quantity
		if inst.quantity > 1:
			var qty_label = Label.new()
			qty_label.text = "x" + str(inst.quantity)
			qty_label.add_theme_font_size_override("font_size", 10)
			qty_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
			vbox.add_child(qty_label)

		# Durability bar
		if inst.current_durability >= 0:
			var max_dur = item_def.get("durability", 1)
			var ratio = float(inst.current_durability) / max(max_dur, 1)

			var bar_color = Color(0.3, 0.85, 0.3)
			if ratio < 0.25:
				bar_color = Color(0.95, 0.25, 0.2)
			elif ratio < 0.5:
				bar_color = Color(0.95, 0.7, 0.2)

			var bar_bg = ColorRect.new()
			bar_bg.custom_minimum_size = Vector2(70, 5)
			bar_bg.color = Color(0.15, 0.15, 0.2)
			vbox.add_child(bar_bg)

			var bar_fill = ColorRect.new()
			bar_fill.custom_minimum_size = Vector2(int(70 * ratio), 5)
			bar_fill.color = bar_color
			bar_bg.add_child(bar_fill)

			var dur_label = Label.new()
			dur_label.text = "%d/%d" % [inst.current_durability, max_dur]
			dur_label.add_theme_font_size_override("font_size", 8)
			dur_label.add_theme_color_override("font_color", bar_color)
			vbox.add_child(dur_label)

		# Item type indicator
		var type_label = Label.new()
		var type_text = ""
		match item_def.get("type", -1):
			Items.ItemType.RESOURCE: type_text = "Resource"
			Items.ItemType.EQUIPMENT: type_text = "Equipment"
			Items.ItemType.SHIP_PART: type_text = "Ship Part"
			Items.ItemType.CONSUMABLE: type_text = "Consumable"
		if type_text != "":
			type_label.text = type_text
			type_label.add_theme_font_size_override("font_size", 8)
			type_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
			vbox.add_child(type_label)
	else:
		# Empty slot
		panel.add_theme_stylebox_override("panel", Base.make_slot_panel(Color.WHITE, false))

	return panel
