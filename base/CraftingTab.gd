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
	var name = Crafting.WORKBENCH_NAMES.get(selected_workbench, "?")
	$WorkbenchInfo.text = "%s - Level %d/3" % [name, level]

	# Update button states
	$WorkbenchSelector/ForgeBtn.disabled = (selected_workbench == Crafting.WorkbenchType.FORGE)
	$WorkbenchSelector/LabBtn.disabled = (selected_workbench == Crafting.WorkbenchType.LAB)
	$WorkbenchSelector/AssemblerBtn.disabled = (selected_workbench == Crafting.WorkbenchType.ASSEMBLER)
	$WorkbenchSelector/ShipyardBtn.disabled = (selected_workbench == Crafting.WorkbenchType.SHIPYARD)

func _populate_recipes():
	for child in $RecipeList.get_children():
		child.queue_free()

	var recipes = Crafting.get_available_recipes(selected_workbench)
	if recipes.size() == 0:
		var empty = Label.new()
		empty.text = "No recipes available at this workbench level."
		$RecipeList.add_child(empty)
		return

	for recipe in recipes:
		var item_def = Items.get_item(recipe.result_id)
		if item_def.is_empty():
			continue

		var hbox = HBoxContainer.new()
		hbox.custom_minimum_size.y = 40

		# Result name
		var name_label = Label.new()
		name_label.text = item_def.get("name", "???")
		if recipe.result_quantity > 1:
			name_label.text += " x%d" % recipe.result_quantity
		name_label.custom_minimum_size.x = 160
		name_label.add_theme_color_override("font_color", Items.RARITY_COLORS.get(item_def.get("rarity", 0), Color.WHITE))
		name_label.add_theme_font_size_override("font_size", 11)
		hbox.add_child(name_label)

		# Ingredients
		var ingredients_text = ""
		for ingredient in recipe.ingredients:
			var ing_def = Items.get_item(ingredient.item_id)
			var have = Inventory.count_item_in_stash(ingredient.item_id)
			var need = ingredient.quantity
			var color_tag = "[color=green]" if have >= need else "[color=red]"
			if ingredients_text != "":
				ingredients_text += ", "
			ingredients_text += "%s %d/%d" % [ing_def.get("name", "?"), have, need]

		var ing_label = Label.new()
		ing_label.text = ingredients_text
		ing_label.custom_minimum_size.x = 300
		ing_label.add_theme_font_size_override("font_size", 10)
		ing_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		hbox.add_child(ing_label)

		# Craft button
		var can_craft = Crafting.can_craft(recipe.id)
		var craft_btn = Button.new()
		craft_btn.text = "Craft"
		craft_btn.custom_minimum_size = Vector2(60, 30)
		craft_btn.disabled = not can_craft
		craft_btn.pressed.connect(_on_craft.bind(recipe.id))
		hbox.add_child(craft_btn)

		$RecipeList.add_child(hbox)

	# Add upgrade workbench option if not max level
	var level = Crafting.workbench_levels.get(selected_workbench, 1)
	if level < 3:
		var separator = HSeparator.new()
		$RecipeList.add_child(separator)

		var upgrade_id = "upgrade_" + Crafting.WorkbenchType.keys()[selected_workbench].to_lower()
		var can_upgrade = Crafting.can_craft(upgrade_id)

		var upgrade_hbox = HBoxContainer.new()
		var upgrade_label = Label.new()
		upgrade_label.text = "Upgrade to Level %d" % (level + 1)
		upgrade_label.add_theme_font_size_override("font_size", 12)
		upgrade_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
		upgrade_hbox.add_child(upgrade_label)

		var upgrade_btn = Button.new()
		upgrade_btn.text = "Upgrade"
		upgrade_btn.disabled = not can_upgrade
		upgrade_btn.pressed.connect(_on_upgrade_workbench)
		upgrade_hbox.add_child(upgrade_btn)

		$RecipeList.add_child(upgrade_hbox)

func _on_craft(recipe_id: String):
	if Crafting.craft(recipe_id):
		SaveManager.save_game()
		refresh()

func _on_upgrade_workbench():
	if Crafting.upgrade_workbench(selected_workbench):
		SaveManager.save_game()
		refresh()
