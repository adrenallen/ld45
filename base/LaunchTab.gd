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
	Items.ShipSlot.LANDING_SYSTEM: "Landing",
	Items.ShipSlot.FUEL_TANK: "Fuel Tank",
	Items.ShipSlot.WEAPONS: "Weapons",
	Items.ShipSlot.CARGO: "Cargo",
}

const SLOT_ICONS = {
	Items.EquipSlot.HELMET: "[H]",
	Items.EquipSlot.SUIT: "[S]",
	Items.EquipSlot.BACKPACK: "[B]",
	Items.EquipSlot.BOOTS: "[b]",
	Items.EquipSlot.TOOL: "[T]",
}

func refresh():
	_build_player_panel()
	_build_ship_panel()
	_build_stats_row()

func _ready():
	$LaunchButton.pressed.connect(_on_launch)

func _build_player_panel():
	var panel = $Content/PlayerPanel
	for c in panel.get_children():
		c.queue_free()

	var title = Label.new()
	title.text = "PILOT LOADOUT"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	panel.add_child(title)

	for slot in Items.EquipSlot.values():
		var slot_name = EQUIP_SLOT_NAMES.get(slot, "?")
		var has_item = Inventory.player_equipment.has(slot)

		var row = PanelContainer.new()
		var item_def = {}
		var inst = null
		var rarity_color = Color.WHITE

		if has_item:
			inst = Inventory.player_equipment[slot]
			item_def = Items.get_item(inst.item_id)
			rarity_color = Items.RARITY_COLORS.get(item_def.get("rarity", 0), Color.WHITE)
			row.add_theme_stylebox_override("panel", Base.make_slot_panel(rarity_color, true))
		else:
			row.add_theme_stylebox_override("panel", Base.make_slot_panel(Color.WHITE, false))

		var hbox = HBoxContainer.new()
		row.add_child(hbox)

		# Slot label
		var slot_lbl = Label.new()
		slot_lbl.text = slot_name
		slot_lbl.custom_minimum_size.x = 75
		slot_lbl.add_theme_font_size_override("font_size", 11)
		slot_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		hbox.add_child(slot_lbl)

		if has_item:
			var name_lbl = Label.new()
			name_lbl.text = item_def.get("name", "???")
			name_lbl.add_theme_font_size_override("font_size", 12)
			name_lbl.add_theme_color_override("font_color", rarity_color)
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(name_lbl)

			if inst.current_durability >= 0:
				var dur_bar = _make_durability_indicator(inst.current_durability, item_def.get("durability", 1))
				hbox.add_child(dur_bar)
			else:
				var inf = Label.new()
				inf.text = "INF"
				inf.add_theme_font_size_override("font_size", 9)
				inf.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4))
				hbox.add_child(inf)
		else:
			var empty = Label.new()
			empty.text = "-- empty --"
			empty.add_theme_font_size_override("font_size", 11)
			empty.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
			empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(empty)

		panel.add_child(row)

func _build_ship_panel():
	var panel = $Content/ShipPanel
	for c in panel.get_children():
		c.queue_free()

	var title = Label.new()
	title.text = "SHIP SYSTEMS"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	panel.add_child(title)

	for slot in Items.ShipSlot.values():
		var slot_name = SHIP_SLOT_NAMES.get(slot, "?")
		var has_item = Inventory.ship_equipment.has(slot)

		var row = PanelContainer.new()
		var item_def = {}
		var inst = null
		var rarity_color = Color.WHITE

		if has_item:
			inst = Inventory.ship_equipment[slot]
			item_def = Items.get_item(inst.item_id)
			rarity_color = Items.RARITY_COLORS.get(item_def.get("rarity", 0), Color.WHITE)
			row.add_theme_stylebox_override("panel", Base.make_slot_panel(rarity_color, true))
		else:
			row.add_theme_stylebox_override("panel", Base.make_slot_panel(Color.WHITE, false))

		var hbox = HBoxContainer.new()
		row.add_child(hbox)

		var slot_lbl = Label.new()
		slot_lbl.text = slot_name
		slot_lbl.custom_minimum_size.x = 75
		slot_lbl.add_theme_font_size_override("font_size", 11)
		slot_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6))
		hbox.add_child(slot_lbl)

		if has_item:
			var name_lbl = Label.new()
			name_lbl.text = item_def.get("name", "???")
			name_lbl.add_theme_font_size_override("font_size", 12)
			name_lbl.add_theme_color_override("font_color", rarity_color)
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(name_lbl)

			if inst.current_durability >= 0:
				var dur_bar = _make_durability_indicator(inst.current_durability, item_def.get("durability", 1))
				hbox.add_child(dur_bar)
			else:
				var inf = Label.new()
				inf.text = "INF"
				inf.add_theme_font_size_override("font_size", 9)
				inf.add_theme_color_override("font_color", Color(0.4, 0.7, 0.4))
				hbox.add_child(inf)
		else:
			var empty = Label.new()
			empty.text = "-- empty --"
			empty.add_theme_font_size_override("font_size", 11)
			empty.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
			empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(empty)

		panel.add_child(row)

func _build_stats_row():
	var row = $StatsRow
	for c in row.get_children():
		c.queue_free()

	var stats = [
		["O2", "%d" % int(Inventory.get_player_stat("oxygen_capacity", 100)), Color(0.4, 0.6, 1.0)],
		["Hull", "%d HP" % int(Inventory.get_ship_stat("hull_hp", 5)), Color(0.8, 0.6, 0.3)],
		["Fuel", "%d" % int(Inventory.get_ship_stat("fuel_capacity", 100)), Color(0.3, 0.8, 0.3)],
		["Inv", "%d slots" % Inventory.get_inventory_capacity(), Color(0.7, 0.7, 0.5)],
		["Cargo", "%d slots" % Inventory.get_cargo_capacity(), Color(0.6, 0.5, 0.7)],
	]

	for stat in stats:
		var chip = PanelContainer.new()
		chip.add_theme_stylebox_override("panel", Base.make_slot_panel(stat[2], true))

		var lbl = Label.new()
		lbl.text = "%s: %s" % [stat[0], stat[1]]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", stat[2])
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.add_child(lbl)

		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(chip)

func _make_durability_indicator(current: int, max_dur: int) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size.x = 100

	var ratio = float(current) / max(max_dur, 1)
	var bar_color = Color(0.3, 0.85, 0.3)
	if ratio < 0.25:
		bar_color = Color(0.95, 0.25, 0.2)
	elif ratio < 0.5:
		bar_color = Color(0.95, 0.7, 0.2)

	# Background bar
	var bg = ColorRect.new()
	bg.custom_minimum_size = Vector2(60, 8)
	bg.color = Color(0.15, 0.15, 0.2)
	hbox.add_child(bg)

	# Fill bar (overlaid via margin trick - use a Panel inside)
	var fill = ColorRect.new()
	fill.custom_minimum_size = Vector2(int(60 * ratio), 8)
	fill.color = bar_color
	fill.position = bg.position
	# We'll use a container for overlay
	bg.add_child(fill)

	var txt = Label.new()
	txt.text = " %d/%d" % [current, max_dur]
	txt.add_theme_font_size_override("font_size", 9)
	txt.add_theme_color_override("font_color", bar_color)
	hbox.add_child(txt)

	return hbox

func _on_launch():
	Game.startRun()
