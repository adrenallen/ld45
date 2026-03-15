extends Control

const EQUIP_SLOT_NAMES = {
	Items.EquipSlot.HELMET: "Helmet",
	Items.EquipSlot.SUIT: "Suit",
	Items.EquipSlot.BACKPACK: "Backpack",
	Items.EquipSlot.BOOTS: "Boots",
	Items.EquipSlot.TOOL: "Tool",
}

const SHIP_SLOT_NAMES = {
	Items.ShipSlot.HULL: "Hull",
	Items.ShipSlot.REACTOR: "Reactor",
	Items.ShipSlot.JUMP_DRIVE: "Jump Drive",
	Items.ShipSlot.LANDING_SYSTEM: "Landing System",
	Items.ShipSlot.FUEL_TANK: "Fuel Tank",
	Items.ShipSlot.WEAPONS: "Weapons",
	Items.ShipSlot.CARGO: "Cargo Bay",
}

func refresh():
	_populate_player_slots()
	_populate_ship_slots()
	_update_stats()

func _populate_player_slots():
	for child in $PlayerSlots.get_children():
		child.queue_free()

	for slot in Items.EquipSlot.values():
		var row = _make_equip_row(
			EQUIP_SLOT_NAMES.get(slot, "?"),
			Inventory.player_equipment.get(slot),
			slot, false
		)
		$PlayerSlots.add_child(row)

func _populate_ship_slots():
	for child in $ShipSlots.get_children():
		child.queue_free()

	for slot in Items.ShipSlot.values():
		var row = _make_equip_row(
			SHIP_SLOT_NAMES.get(slot, "?"),
			Inventory.ship_equipment.get(slot),
			slot, true
		)
		$ShipSlots.add_child(row)

func _make_equip_row(slot_name: String, inst, slot: int, is_ship: bool) -> PanelContainer:
	var panel = PanelContainer.new()
	var item_def = {}
	var rarity_color = Color.WHITE

	if inst:
		item_def = Items.get_item(inst.item_id)
		rarity_color = Items.RARITY_COLORS.get(item_def.get("rarity", 0), Color.WHITE)
		panel.add_theme_stylebox_override("panel", Base.make_slot_panel(rarity_color, true))
	else:
		panel.add_theme_stylebox_override("panel", Base.make_slot_panel(Color.WHITE, false))

	var hbox = HBoxContainer.new()
	panel.add_child(hbox)

	# Slot name
	var slot_lbl = Label.new()
	slot_lbl.text = slot_name
	slot_lbl.custom_minimum_size.x = 90
	slot_lbl.add_theme_font_size_override("font_size", 11)
	slot_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
	hbox.add_child(slot_lbl)

	if inst:
		# Item name
		var name_lbl = Label.new()
		name_lbl.text = item_def.get("name", "???")
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", rarity_color)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_lbl)

		# Durability
		if inst.current_durability >= 0:
			var dur = Label.new()
			var max_d = item_def.get("durability", 1)
			var ratio = float(inst.current_durability) / max(max_d, 1)
			dur.text = "%d/%d" % [inst.current_durability, max_d]
			dur.add_theme_font_size_override("font_size", 10)
			if ratio < 0.25:
				dur.add_theme_color_override("font_color", Color(0.95, 0.3, 0.2))
			elif ratio < 0.5:
				dur.add_theme_color_override("font_color", Color(0.95, 0.7, 0.2))
			else:
				dur.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
			hbox.add_child(dur)
		else:
			var inf = Label.new()
			inf.text = "Starter"
			inf.add_theme_font_size_override("font_size", 9)
			inf.add_theme_color_override("font_color", Color(0.45, 0.55, 0.45))
			hbox.add_child(inf)

		# Unequip button (non-starter only)
		if inst.current_durability != -1:
			var unbtn = Button.new()
			unbtn.text = "X"
			unbtn.custom_minimum_size = Vector2(24, 24)
			unbtn.add_theme_font_size_override("font_size", 10)
			var s = slot
			if is_ship:
				unbtn.pressed.connect(_on_unequip_ship.bind(s))
			else:
				unbtn.pressed.connect(_on_unequip_player.bind(s))
			# Style the X button red
			var xstyle = StyleBoxFlat.new()
			xstyle.bg_color = Color(0.25, 0.08, 0.08, 0.8)
			xstyle.border_color = Color(0.6, 0.2, 0.2, 0.5)
			xstyle.set_border_width_all(1)
			xstyle.set_corner_radius_all(2)
			unbtn.add_theme_stylebox_override("normal", xstyle)
			unbtn.add_theme_color_override("font_color", Color(0.9, 0.35, 0.3))
			hbox.add_child(unbtn)
	else:
		var empty = Label.new()
		empty.text = "-- empty --"
		empty.add_theme_font_size_override("font_size", 11)
		empty.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(empty)

	# Equip from stash button
	var equip_btn = Button.new()
	equip_btn.text = "Equip"
	equip_btn.custom_minimum_size = Vector2(55, 24)
	equip_btn.add_theme_font_size_override("font_size", 10)
	equip_btn.pressed.connect(_on_equip_from_stash.bind(slot, is_ship))
	var eq_style = StyleBoxFlat.new()
	eq_style.bg_color = Color(0.08, 0.12, 0.2, 0.8)
	eq_style.border_color = Color(0.25, 0.4, 0.6, 0.5)
	eq_style.set_border_width_all(1)
	eq_style.set_corner_radius_all(2)
	equip_btn.add_theme_stylebox_override("normal", eq_style)
	equip_btn.add_theme_color_override("font_color", Color(0.4, 0.65, 0.9))
	hbox.add_child(equip_btn)

	return panel

func _update_stats():
	var stats_text = ""
	stats_text += "O2 Capacity: %d\n" % int(Inventory.get_player_stat("oxygen_capacity", 100))
	stats_text += "O2 Efficiency: %.0f%%\n" % (Inventory.get_player_stat("oxygen_efficiency", 1.0) * 100)
	stats_text += "Damage Resist: %d\n" % int(Inventory.get_player_stat("damage_resistance", 0))
	stats_text += "Inventory Slots: %d\n" % Inventory.get_inventory_capacity()
	stats_text += "Ship Hull: %d HP\n" % int(Inventory.get_ship_stat("hull_hp", 5))
	stats_text += "Fuel Capacity: %d\n" % int(Inventory.get_ship_stat("fuel_capacity", 100))
	stats_text += "Fuel Efficiency: %.0f%%\n" % (Inventory.get_ship_stat("fuel_efficiency", 1.0) * 100)
	stats_text += "Cargo Slots: %d" % Inventory.get_cargo_capacity()
	$StatsPanel/StatsText.text = stats_text

func _on_unequip_player(slot: int):
	Inventory.unequip_player_item(slot)
	SaveManager.save_game()
	refresh()

func _on_unequip_ship(slot: int):
	Inventory.unequip_ship_part(slot)
	SaveManager.save_game()
	refresh()

func _on_equip_from_stash(slot: int, is_ship: bool):
	for inst in Inventory.base_stash:
		var item_def = Items.get_item(inst.item_id)
		if is_ship:
			if item_def.has("ship_slot") and item_def.ship_slot == slot:
				Inventory.equip_ship_part(inst.instance_id, slot)
				SaveManager.save_game()
				refresh()
				return
		else:
			if item_def.has("equip_slot") and item_def.equip_slot == slot:
				Inventory.equip_player_item(inst.instance_id, slot)
				SaveManager.save_game()
				refresh()
				return
