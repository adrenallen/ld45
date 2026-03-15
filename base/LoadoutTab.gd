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
		var hbox = HBoxContainer.new()

		var slot_label = Label.new()
		slot_label.text = EQUIP_SLOT_NAMES.get(slot, "?") + ": "
		slot_label.custom_minimum_size.x = 80
		slot_label.add_theme_font_size_override("font_size", 11)
		hbox.add_child(slot_label)

		if Inventory.player_equipment.has(slot):
			var inst = Inventory.player_equipment[slot]
			var item_def = Items.get_item(inst.item_id)
			var item_label = Label.new()
			item_label.text = item_def.get("name", "???")
			item_label.add_theme_color_override("font_color", Items.RARITY_COLORS.get(item_def.get("rarity", 0), Color.WHITE))
			item_label.add_theme_font_size_override("font_size", 11)
			hbox.add_child(item_label)

			if inst.current_durability >= 0:
				var dur = Label.new()
				dur.text = " [%d/%d]" % [inst.current_durability, item_def.get("durability", 1)]
				dur.add_theme_font_size_override("font_size", 10)
				hbox.add_child(dur)

			# Unequip button (only if not starter)
			if inst.current_durability != -1:
				var btn = Button.new()
				btn.text = "X"
				btn.custom_minimum_size = Vector2(25, 25)
				btn.pressed.connect(_on_unequip_player.bind(slot))
				hbox.add_child(btn)
		else:
			var empty = Label.new()
			empty.text = "[Empty]"
			empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			empty.add_theme_font_size_override("font_size", 11)
			hbox.add_child(empty)

		# Equip from stash button
		var equip_btn = Button.new()
		equip_btn.text = "Equip..."
		equip_btn.custom_minimum_size = Vector2(60, 25)
		equip_btn.pressed.connect(_on_equip_from_stash.bind(slot, false))
		hbox.add_child(equip_btn)

		$PlayerSlots.add_child(hbox)

func _populate_ship_slots():
	for child in $ShipSlots.get_children():
		child.queue_free()

	for slot in Items.ShipSlot.values():
		var hbox = HBoxContainer.new()

		var slot_label = Label.new()
		slot_label.text = SHIP_SLOT_NAMES.get(slot, "?") + ": "
		slot_label.custom_minimum_size.x = 100
		slot_label.add_theme_font_size_override("font_size", 11)
		hbox.add_child(slot_label)

		if Inventory.ship_equipment.has(slot):
			var inst = Inventory.ship_equipment[slot]
			var item_def = Items.get_item(inst.item_id)
			var item_label = Label.new()
			item_label.text = item_def.get("name", "???")
			item_label.add_theme_color_override("font_color", Items.RARITY_COLORS.get(item_def.get("rarity", 0), Color.WHITE))
			item_label.add_theme_font_size_override("font_size", 11)
			hbox.add_child(item_label)

			if inst.current_durability >= 0:
				var dur = Label.new()
				dur.text = " [%d/%d]" % [inst.current_durability, item_def.get("durability", 1)]
				dur.add_theme_font_size_override("font_size", 10)
				hbox.add_child(dur)

			if inst.current_durability != -1:
				var btn = Button.new()
				btn.text = "X"
				btn.custom_minimum_size = Vector2(25, 25)
				btn.pressed.connect(_on_unequip_ship.bind(slot))
				hbox.add_child(btn)
		else:
			var empty = Label.new()
			empty.text = "[Empty]"
			empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			empty.add_theme_font_size_override("font_size", 11)
			hbox.add_child(empty)

		var equip_btn = Button.new()
		equip_btn.text = "Equip..."
		equip_btn.custom_minimum_size = Vector2(60, 25)
		equip_btn.pressed.connect(_on_equip_from_stash.bind(slot, true))
		hbox.add_child(equip_btn)

		$ShipSlots.add_child(hbox)

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
	# Find matching items in stash
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
