extends Control

var selected_workbench: int = Crafting.WorkbenchType.FORGE

func refresh():
	_update_workbench_info()
	_populate_recipes()

func _ready():
	$WorkbenchSelector/ForgeBtn.pressed.connect(_on_workbench_selected.bind(Crafting.WorkbenchType.FORGE))
	$WorkbenchSelector/LabBtn.pressed.connect(_on_workbench_selected.bind(Crafting.WorkbenchType.LAB))
	$WorkbenchSelector/AssemblerBtn.pressed.connect(_on_workbench_selected.bind(Crafting.WorkbenchType.ASSEMBLER))
	$WorkbenchSelector/ShipyardBtn.pressed.connect(_on_workbench_selected.bind(Crafting.WorkbenchType.SHIPYARD))

func _on_workbench_selected(type: int):
	selected_workbench = type
	refresh()

func _update_workbench_info():
	var level = Crafting.workbench_levels.get(selected_workbench, 1)
	var bench_name = Crafting.WORKBENCH_NAMES.get(selected_workbench, "?")

	# Level pips
	var pips = ""
	for i in range(3):
		if i < level:
			pips += " [*]"
		else:
			pips += " [ ]"
	$WorkbenchInfo.text = "%s  Level %d%s" % [bench_name, level, pips]

	# Style workbench selector buttons
	var btns = [$WorkbenchSelector/ForgeBtn, $WorkbenchSelector/LabBtn, $WorkbenchSelector/AssemblerBtn, $WorkbenchSelector/ShipyardBtn]
	var types = [Crafting.WorkbenchType.FORGE, Crafting.WorkbenchType.LAB, Crafting.WorkbenchType.ASSEMBLER, Crafting.WorkbenchType.SHIPYARD]
	var colors = [Color(1, 0.5, 0.2), Color(0.3, 0.8, 1.0), Color(0.6, 0.85, 0.4), Color(0.8, 0.6, 1.0)]

	for i in range(4):
		btns[i].disabled = (selected_workbench == types[i])
		var c = colors[i]
		if selected_workbench == types[i]:
			var active = StyleBoxFlat.new()
			active.bg_color = Color(c.r * 0.15, c.g * 0.15, c.b * 0.15, 0.95)
			active.border_color = c
			active.border_width_bottom = 2
			active.set_border_width_all(1)
			active.set_corner_radius_all(3)
			active.set_content_margin_all(6)
			btns[i].add_theme_stylebox_override("disabled", active)
			btns[i].add_theme_color_override("font_disabled_color", c)

func _populate_recipes():
	var recipe_list = $ScrollContainer/RecipeList
	for child in recipe_list.get_children():
		child.queue_free()

	var recipes = Crafting.get_available_recipes(selected_workbench)
	if recipes.size() == 0:
		var empty = Label.new()
		empty.text = "No recipes available at this workbench level."
		empty.add_theme_font_size_override("font_size", 12)
		empty.add_theme_color_override("font_color", Color(0.45, 0.45, 0.5))
		recipe_list.add_child(empty)
		return

	for recipe in recipes:
		var item_def = Items.get_item(recipe.result_id)
		if item_def.is_empty():
			continue

		var can = Crafting.can_craft(recipe.id)
		var rarity_color = Items.RARITY_COLORS.get(item_def.get("rarity", 0), Color.WHITE)

		# Recipe card
		var card = PanelContainer.new()
		if can:
			card.add_theme_stylebox_override("panel", Base.make_slot_panel(rarity_color, true))
		else:
			card.add_theme_stylebox_override("panel", Base.make_slot_panel(Color(0.4, 0.4, 0.4), false))

		var hbox = HBoxContainer.new()
		card.add_child(hbox)

		# Left: Result info
		var left = VBoxContainer.new()
		left.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl = Label.new()
		name_lbl.text = item_def.get("name", "???")
		if recipe.result_quantity > 1:
			name_lbl.text += " x%d" % recipe.result_quantity
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_color", rarity_color if can else Color(rarity_color.r * 0.5, rarity_color.g * 0.5, rarity_color.b * 0.5))
		left.add_child(name_lbl)

		# Ingredients row
		var ing_hbox = HBoxContainer.new()
		for ingredient in recipe.ingredients:
			var ing_def = Items.get_item(ingredient.item_id)
			var have = Inventory.count_item_in_stash(ingredient.item_id)
			var need = ingredient.quantity
			var enough = have >= need

			var ing_chip = Label.new()
			ing_chip.text = "%s %d/%d  " % [ing_def.get("name", "?"), have, need]
			ing_chip.add_theme_font_size_override("font_size", 10)
			ing_chip.add_theme_color_override("font_color", Color(0.3, 0.8, 0.3) if enough else Color(0.8, 0.3, 0.3))
			ing_hbox.add_child(ing_chip)
		left.add_child(ing_hbox)

		hbox.add_child(left)

		# Right: Craft button
		var craft_btn = Button.new()
		craft_btn.text = "Craft"
		craft_btn.custom_minimum_size = Vector2(70, 36)
		craft_btn.add_theme_font_size_override("font_size", 13)
		craft_btn.disabled = not can

		if can:
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.1, 0.2, 0.1, 0.9)
			btn_style.border_color = Color(0.3, 0.7, 0.3, 0.7)
			btn_style.set_border_width_all(1)
			btn_style.set_corner_radius_all(3)
			btn_style.set_content_margin_all(4)
			craft_btn.add_theme_stylebox_override("normal", btn_style)
			craft_btn.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))

		craft_btn.pressed.connect(_on_craft.bind(recipe.id))
		hbox.add_child(craft_btn)

		recipe_list.add_child(card)

	# Upgrade workbench option
	var level = Crafting.workbench_levels.get(selected_workbench, 1)
	if level < 3:
		var sep = HSeparator.new()
		sep.add_theme_constant_override("separation", 10)
		recipe_list.add_child(sep)

		var upgrade_card = PanelContainer.new()
		var ug_style = StyleBoxFlat.new()
		ug_style.bg_color = Color(0.15, 0.12, 0.05, 0.8)
		ug_style.border_color = Color(0.6, 0.5, 0.2, 0.5)
		ug_style.set_border_width_all(1)
		ug_style.set_corner_radius_all(4)
		ug_style.set_content_margin_all(8)
		upgrade_card.add_theme_stylebox_override("panel", ug_style)

		var ug_hbox = HBoxContainer.new()
		upgrade_card.add_child(ug_hbox)

		var ug_label = Label.new()
		ug_label.text = "Upgrade to Level %d" % (level + 1)
		ug_label.add_theme_font_size_override("font_size", 14)
		ug_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
		ug_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ug_hbox.add_child(ug_label)

		var upgrade_id = "upgrade_" + Crafting.WorkbenchType.keys()[selected_workbench].to_lower()
		var can_upgrade = Crafting.can_craft(upgrade_id)

		var ug_btn = Button.new()
		ug_btn.text = "Upgrade"
		ug_btn.custom_minimum_size = Vector2(80, 30)
		ug_btn.add_theme_font_size_override("font_size", 13)
		ug_btn.disabled = not can_upgrade
		ug_btn.pressed.connect(_on_upgrade_workbench)

		if can_upgrade:
			var btn_style = StyleBoxFlat.new()
			btn_style.bg_color = Color(0.18, 0.15, 0.05, 0.9)
			btn_style.border_color = Color(0.7, 0.6, 0.2, 0.7)
			btn_style.set_border_width_all(1)
			btn_style.set_corner_radius_all(3)
			ug_btn.add_theme_stylebox_override("normal", btn_style)
			ug_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))

		ug_hbox.add_child(ug_btn)
		recipe_list.add_child(upgrade_card)

func _on_craft(recipe_id: String):
	if Crafting.craft(recipe_id):
		SaveManager.save_game()
		refresh()

func _on_upgrade_workbench():
	if Crafting.upgrade_workbench(selected_workbench):
		SaveManager.save_game()
		refresh()
