extends GutTest

# Tests for data/crafting.gd - Crafting system

var craft: Node


func before_each():
	craft = load("res://data/crafting.gd").new()
	add_child_autofree(craft)
	# Reset inventory stash
	Inventory.base_stash.clear()
	craft.reset_workbenches()


func test_recipes_populated():
	assert_true(craft.recipes.size() > 0, "Should have recipes after _ready")


func test_get_recipe():
	var recipe = craft.get_recipe("craft_steel_plate")
	assert_false(recipe.is_empty(), "Should find steel plate recipe")
	assert_eq(recipe.result_id, "steel_plate")
	assert_eq(recipe.result_quantity, 2)


func test_get_available_recipes_level_1():
	var forge_recipes = craft.get_available_recipes(craft.WorkbenchType.FORGE, 1)
	assert_true(forge_recipes.size() > 0, "Should have level 1 forge recipes")
	for recipe in forge_recipes:
		assert_true(recipe.workbench_level <= 1, "Should only return level 1 recipes")


func test_get_available_recipes_level_2():
	var forge_recipes = craft.get_available_recipes(craft.WorkbenchType.FORGE, 2)
	var has_level_2 = false
	for recipe in forge_recipes:
		if recipe.workbench_level == 2:
			has_level_2 = true
	assert_true(has_level_2, "Should include level 2 recipes")


func test_can_craft_missing_ingredients():
	assert_false(craft.can_craft("craft_steel_plate"), "Should not craft without ingredients")


func test_can_craft_with_ingredients():
	Inventory.add_to_base_stash("iron_ore", 10)
	Inventory.add_to_base_stash("scrap_metal", 5)
	assert_true(craft.can_craft("craft_steel_plate"), "Should be able to craft with ingredients")


func test_craft_consumes_ingredients():
	Inventory.add_to_base_stash("iron_ore", 10)
	Inventory.add_to_base_stash("scrap_metal", 5)
	var result = craft.craft("craft_steel_plate")
	assert_true(result, "Crafting should succeed")
	assert_eq(Inventory.count_item_in_stash("iron_ore"), 6, "Should consume 4 iron ore")
	assert_eq(Inventory.count_item_in_stash("scrap_metal"), 3, "Should consume 2 scrap metal")
	assert_eq(Inventory.count_item_in_stash("steel_plate"), 2, "Should produce 2 steel plates")


func test_craft_fails_insufficient_ingredients():
	Inventory.add_to_base_stash("iron_ore", 2)
	var result = craft.craft("craft_steel_plate")
	assert_false(result, "Should fail with insufficient ingredients")


func test_workbench_levels_default():
	for type in craft.WorkbenchType.values():
		assert_eq(craft.workbench_levels[type], 1, "All workbenches should start at level 1")


func test_cant_craft_above_workbench_level():
	# mk3_helmet requires forge level 2
	assert_false(craft.can_craft("craft_mk3_helmet"), "Should not craft mk3 at level 1 forge")


func test_serialization_roundtrip():
	craft.workbench_levels[craft.WorkbenchType.FORGE] = 3
	craft.workbench_levels[craft.WorkbenchType.LAB] = 2
	var data = craft.to_dict()

	craft.reset_workbenches()
	assert_eq(craft.workbench_levels[craft.WorkbenchType.FORGE], 1)

	craft.from_dict(data)
	assert_eq(craft.workbench_levels[craft.WorkbenchType.FORGE], 3)
	assert_eq(craft.workbench_levels[craft.WorkbenchType.LAB], 2)


func test_all_recipes_reference_valid_items():
	for recipe_id in craft.recipes:
		var recipe = craft.recipes[recipe_id]
		var result_item = Items.get_item(recipe.result_id)
		assert_false(result_item.is_empty(), "Recipe %s result '%s' should exist in items db" % [recipe_id, recipe.result_id])
		for ingredient in recipe.ingredients:
			var ing_item = Items.get_item(ingredient.item_id)
			assert_false(ing_item.is_empty(), "Recipe %s ingredient '%s' should exist in items db" % [recipe_id, ingredient.item_id])
