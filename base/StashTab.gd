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

func _create_slot(index: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(90, 90)

	var vbox = VBoxContainer.new()
	panel.add_child(vbox)

	if index < Inventory.base_stash.size():
		var inst = Inventory.base_stash[index]
		var item_def = Items.get_item(inst.item_id)

		var name_label = Label.new()
		name_label.text = item_def.get("name", "???")
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", Items.RARITY_COLORS.get(item_def.get("rarity", 0), Color.WHITE))
		vbox.add_child(name_label)

		if inst.quantity > 1:
			var qty_label = Label.new()
			qty_label.text = "x" + str(inst.quantity)
			qty_label.add_theme_font_size_override("font_size", 9)
			vbox.add_child(qty_label)

		if inst.current_durability >= 0:
			var dur_label = Label.new()
			var max_dur = item_def.get("durability", 1)
			dur_label.text = "Dur: %d/%d" % [inst.current_durability, max_dur]
			dur_label.add_theme_font_size_override("font_size", 9)
			if inst.current_durability <= max_dur * 0.25:
				dur_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
			vbox.add_child(dur_label)

		var desc_label = Label.new()
		desc_label.text = item_def.get("description", "")
		desc_label.add_theme_font_size_override("font_size", 8)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(desc_label)
	else:
		var empty = Label.new()
		empty.text = "[Empty]"
		empty.add_theme_font_size_override("font_size", 10)
		empty.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		vbox.add_child(empty)

	return panel
