extends Node

enum WorkbenchType { FORGE, LAB, ASSEMBLER, SHIPYARD }

const WORKBENCH_NAMES = {
	WorkbenchType.FORGE: "Forge",
	WorkbenchType.LAB: "Lab",
	WorkbenchType.ASSEMBLER: "Assembler",
	WorkbenchType.SHIPYARD: "Shipyard",
}

# Workbench levels (1-3)
var workbench_levels: Dictionary = {
	WorkbenchType.FORGE: 1,
	WorkbenchType.LAB: 1,
	WorkbenchType.ASSEMBLER: 1,
	WorkbenchType.SHIPYARD: 1,
}

# All recipes keyed by id
var recipes: Dictionary = {}

func _ready():
	_register_refined_material_recipes()
	_register_forge_recipes()
	_register_lab_recipes()
	_register_assembler_recipes()
	_register_shipyard_recipes()
	_register_workbench_upgrade_recipes()

func reset_workbenches():
	for type in WorkbenchType.values():
		workbench_levels[type] = 1

# ============================================================
# RECIPE MANAGEMENT
# ============================================================
func _register_recipe(recipe: Dictionary):
	recipes[recipe.id] = recipe

func get_recipe(recipe_id: String) -> Dictionary:
	return recipes.get(recipe_id, {})

func get_available_recipes(workbench_type: int, workbench_level: int = -1) -> Array:
	if workbench_level < 0:
		workbench_level = workbench_levels.get(workbench_type, 1)
	var result = []
	for recipe in recipes.values():
		if recipe.workbench == workbench_type and recipe.workbench_level <= workbench_level:
			result.append(recipe)
	return result

func can_craft(recipe_id: String) -> bool:
	var recipe = get_recipe(recipe_id)
	if recipe.is_empty():
		return false
	# Check workbench level
	var wb_level = workbench_levels.get(recipe.workbench, 0)
	if wb_level < recipe.workbench_level:
		return false
	# Check ingredients in stash
	for ingredient in recipe.ingredients:
		if Inventory.count_item_in_stash(ingredient.item_id) < ingredient.quantity:
			return false
	return true

func craft(recipe_id: String) -> bool:
	if not can_craft(recipe_id):
		return false
	var recipe = get_recipe(recipe_id)
	# Consume ingredients
	for ingredient in recipe.ingredients:
		Inventory.remove_item_by_id_from(Inventory.base_stash, ingredient.item_id, ingredient.quantity)
	# Produce result
	Inventory.add_to_base_stash(recipe.result_id, recipe.result_quantity)
	Game.items_crafted = Game.get("items_crafted", 0) + 1
	return true

func upgrade_workbench(type: int) -> bool:
	var current_level = workbench_levels.get(type, 1)
	if current_level >= 3:
		return false
	# Find upgrade recipe
	var upgrade_recipe_id = "upgrade_" + WorkbenchType.keys()[type].to_lower()
	if not can_craft(upgrade_recipe_id):
		return false
	craft(upgrade_recipe_id)
	workbench_levels[type] = current_level + 1
	return true

# ============================================================
# SERIALIZATION
# ============================================================
func to_dict() -> Dictionary:
	var levels = {}
	for type in workbench_levels:
		levels[str(type)] = workbench_levels[type]
	return { workbench_levels = levels }

func from_dict(data: Dictionary):
	if data.has("workbench_levels"):
		for type_str in data.workbench_levels:
			workbench_levels[int(type_str)] = data.workbench_levels[type_str]

# ============================================================
# REFINED MATERIAL RECIPES (Lab)
# ============================================================
func _register_refined_material_recipes():
	_register_recipe({
		id = "craft_steel_plate", result_id = "steel_plate", result_quantity = 2,
		workbench = WorkbenchType.LAB, workbench_level = 1,
		ingredients = [{ item_id = "iron_ore", quantity = 4 }, { item_id = "scrap_metal", quantity = 2 }]
	})
	_register_recipe({
		id = "craft_titanium_weave", result_id = "titanium_weave", result_quantity = 1,
		workbench = WorkbenchType.LAB, workbench_level = 1,
		ingredients = [{ item_id = "titanium", quantity = 3 }, { item_id = "bio_fiber", quantity = 2 }]
	})
	_register_recipe({
		id = "craft_bio_mesh", result_id = "bio_mesh", result_quantity = 2,
		workbench = WorkbenchType.LAB, workbench_level = 1,
		ingredients = [{ item_id = "bio_fiber", quantity = 4 }, { item_id = "mycelium", quantity = 2 }]
	})
	_register_recipe({
		id = "craft_plasma_conduit", result_id = "plasma_conduit", result_quantity = 1,
		workbench = WorkbenchType.LAB, workbench_level = 2,
		ingredients = [{ item_id = "plasma_gel", quantity = 4 }, { item_id = "energy_cell", quantity = 1 }]
	})
	_register_recipe({
		id = "craft_quantum_chip", result_id = "quantum_chip", result_quantity = 1,
		workbench = WorkbenchType.LAB, workbench_level = 2,
		ingredients = [{ item_id = "quantum_dust", quantity = 3 }, { item_id = "crystal_shard", quantity = 2 }]
	})
	_register_recipe({
		id = "craft_fusion_core", result_id = "fusion_core", result_quantity = 1,
		workbench = WorkbenchType.LAB, workbench_level = 3,
		ingredients = [{ item_id = "fusion_catalyst", quantity = 2 }, { item_id = "plasma_conduit", quantity = 1 }, { item_id = "energy_cell", quantity = 2 }]
	})

# ============================================================
# FORGE RECIPES (Equipment)
# ============================================================
func _register_forge_recipes():
	# Mk2 gear
	_register_recipe({
		id = "craft_mk2_helmet", result_id = "mk2_helmet", result_quantity = 1,
		workbench = WorkbenchType.FORGE, workbench_level = 1,
		ingredients = [{ item_id = "steel_plate", quantity = 2 }, { item_id = "bio_mesh", quantity = 1 }]
	})
	_register_recipe({
		id = "craft_mk2_suit", result_id = "mk2_suit", result_quantity = 1,
		workbench = WorkbenchType.FORGE, workbench_level = 1,
		ingredients = [{ item_id = "steel_plate", quantity = 3 }, { item_id = "bio_mesh", quantity = 2 }]
	})
	_register_recipe({
		id = "craft_mk2_boots", result_id = "mk2_boots", result_quantity = 1,
		workbench = WorkbenchType.FORGE, workbench_level = 1,
		ingredients = [{ item_id = "steel_plate", quantity = 1 }, { item_id = "bio_mesh", quantity = 1 }]
	})

	# Mk3 gear
	_register_recipe({
		id = "craft_mk3_helmet", result_id = "mk3_helmet", result_quantity = 1,
		workbench = WorkbenchType.FORGE, workbench_level = 2,
		ingredients = [{ item_id = "titanium_weave", quantity = 2 }, { item_id = "quantum_chip", quantity = 1 }]
	})
	_register_recipe({
		id = "craft_mk3_suit", result_id = "mk3_suit", result_quantity = 1,
		workbench = WorkbenchType.FORGE, workbench_level = 2,
		ingredients = [{ item_id = "titanium_weave", quantity = 3 }, { item_id = "quantum_chip", quantity = 1 }, { item_id = "bio_mesh", quantity = 2 }]
	})
	_register_recipe({
		id = "craft_mk3_boots", result_id = "mk3_boots", result_quantity = 1,
		workbench = WorkbenchType.FORGE, workbench_level = 2,
		ingredients = [{ item_id = "titanium_weave", quantity = 2 }, { item_id = "crystal_shard", quantity = 1 }]
	})

	# Void gear
	_register_recipe({
		id = "craft_void_helmet", result_id = "void_helmet", result_quantity = 1,
		workbench = WorkbenchType.FORGE, workbench_level = 3,
		ingredients = [{ item_id = "void_essence", quantity = 2 }, { item_id = "alien_alloy", quantity = 3 }, { item_id = "quantum_chip", quantity = 2 }]
	})
	_register_recipe({
		id = "craft_void_suit", result_id = "void_suit", result_quantity = 1,
		workbench = WorkbenchType.FORGE, workbench_level = 3,
		ingredients = [{ item_id = "void_essence", quantity = 3 }, { item_id = "alien_alloy", quantity = 4 }, { item_id = "fusion_core", quantity = 1 }]
	})

# ============================================================
# LAB RECIPES (Consumables)
# ============================================================
func _register_lab_recipes():
	_register_recipe({
		id = "craft_repair_kit", result_id = "repair_kit", result_quantity = 1,
		workbench = WorkbenchType.LAB, workbench_level = 1,
		ingredients = [{ item_id = "scrap_metal", quantity = 3 }, { item_id = "iron_ore", quantity = 2 }]
	})
	_register_recipe({
		id = "craft_emergency_o2", result_id = "emergency_o2", result_quantity = 2,
		workbench = WorkbenchType.LAB, workbench_level = 1,
		ingredients = [{ item_id = "hydro_crystal", quantity = 2 }, { item_id = "bio_fiber", quantity = 1 }]
	})
	_register_recipe({
		id = "craft_fuel_cell", result_id = "fuel_cell", result_quantity = 1,
		workbench = WorkbenchType.LAB, workbench_level = 1,
		ingredients = [{ item_id = "plasma_gel", quantity = 2 }, { item_id = "energy_cell", quantity = 1 }]
	})

# ============================================================
# ASSEMBLER RECIPES (Backpacks, Tools)
# ============================================================
func _register_assembler_recipes():
	_register_recipe({
		id = "craft_mk2_backpack", result_id = "mk2_backpack", result_quantity = 1,
		workbench = WorkbenchType.ASSEMBLER, workbench_level = 1,
		ingredients = [{ item_id = "bio_fiber", quantity = 4 }, { item_id = "steel_plate", quantity = 2 }]
	})
	_register_recipe({
		id = "craft_mk2_tool", result_id = "mk2_tool", result_quantity = 1,
		workbench = WorkbenchType.ASSEMBLER, workbench_level = 1,
		ingredients = [{ item_id = "iron_ore", quantity = 3 }, { item_id = "energy_cell", quantity = 1 }]
	})
	_register_recipe({
		id = "craft_mk3_backpack", result_id = "mk3_backpack", result_quantity = 1,
		workbench = WorkbenchType.ASSEMBLER, workbench_level = 2,
		ingredients = [{ item_id = "titanium_weave", quantity = 3 }, { item_id = "quantum_chip", quantity = 1 }]
	})
	_register_recipe({
		id = "craft_mk3_tool", result_id = "mk3_tool", result_quantity = 1,
		workbench = WorkbenchType.ASSEMBLER, workbench_level = 2,
		ingredients = [{ item_id = "titanium_weave", quantity = 2 }, { item_id = "crystal_shard", quantity = 2 }, { item_id = "energy_cell", quantity = 1 }]
	})

# ============================================================
# SHIPYARD RECIPES (Ship Parts)
# ============================================================
func _register_shipyard_recipes():
	# Mk2 ship parts
	_register_recipe({
		id = "craft_mk2_hull", result_id = "mk2_hull", result_quantity = 1,
		workbench = WorkbenchType.SHIPYARD, workbench_level = 1,
		ingredients = [{ item_id = "steel_plate", quantity = 5 }, { item_id = "scrap_metal", quantity = 4 }]
	})
	_register_recipe({
		id = "craft_mk2_reactor", result_id = "mk2_reactor", result_quantity = 1,
		workbench = WorkbenchType.SHIPYARD, workbench_level = 1,
		ingredients = [{ item_id = "plasma_gel", quantity = 3 }, { item_id = "energy_cell", quantity = 2 }]
	})
	_register_recipe({
		id = "craft_mk2_fuel_tank", result_id = "mk2_fuel_tank", result_quantity = 1,
		workbench = WorkbenchType.SHIPYARD, workbench_level = 1,
		ingredients = [{ item_id = "steel_plate", quantity = 3 }, { item_id = "plasma_gel", quantity = 2 }]
	})
	_register_recipe({
		id = "craft_mk2_cargo", result_id = "mk2_cargo", result_quantity = 1,
		workbench = WorkbenchType.SHIPYARD, workbench_level = 1,
		ingredients = [{ item_id = "steel_plate", quantity = 4 }, { item_id = "iron_ore", quantity = 3 }]
	})
	_register_recipe({
		id = "craft_mk2_jump_drive", result_id = "mk2_jump_drive", result_quantity = 1,
		workbench = WorkbenchType.SHIPYARD, workbench_level = 1,
		ingredients = [{ item_id = "energy_cell", quantity = 2 }, { item_id = "crystal_shard", quantity = 1 }, { item_id = "steel_plate", quantity = 2 }]
	})
	_register_recipe({
		id = "craft_mk2_landing", result_id = "mk2_landing", result_quantity = 1,
		workbench = WorkbenchType.SHIPYARD, workbench_level = 1,
		ingredients = [{ item_id = "steel_plate", quantity = 3 }, { item_id = "scrap_metal", quantity = 3 }]
	})
	_register_recipe({
		id = "craft_mk2_weapons", result_id = "mk2_weapons", result_quantity = 1,
		workbench = WorkbenchType.SHIPYARD, workbench_level = 1,
		ingredients = [{ item_id = "steel_plate", quantity = 2 }, { item_id = "plasma_gel", quantity = 2 }, { item_id = "energy_cell", quantity = 1 }]
	})

	# Mk3 ship parts
	_register_recipe({
		id = "craft_mk3_hull", result_id = "mk3_hull", result_quantity = 1,
		workbench = WorkbenchType.SHIPYARD, workbench_level = 2,
		ingredients = [{ item_id = "titanium_weave", quantity = 4 }, { item_id = "alien_alloy", quantity = 2 }]
	})
	_register_recipe({
		id = "craft_mk3_reactor", result_id = "mk3_reactor", result_quantity = 1,
		workbench = WorkbenchType.SHIPYARD, workbench_level = 2,
		ingredients = [{ item_id = "plasma_conduit", quantity = 2 }, { item_id = "fusion_catalyst", quantity = 1 }]
	})
	_register_recipe({
		id = "craft_mk3_fuel_tank", result_id = "mk3_fuel_tank", result_quantity = 1,
		workbench = WorkbenchType.SHIPYARD, workbench_level = 2,
		ingredients = [{ item_id = "titanium_weave", quantity = 3 }, { item_id = "plasma_conduit", quantity = 1 }]
	})
	_register_recipe({
		id = "craft_mk3_cargo", result_id = "mk3_cargo", result_quantity = 1,
		workbench = WorkbenchType.SHIPYARD, workbench_level = 2,
		ingredients = [{ item_id = "titanium_weave", quantity = 4 }, { item_id = "quantum_chip", quantity = 1 }]
	})
	_register_recipe({
		id = "craft_mk3_weapons", result_id = "mk3_weapons", result_quantity = 1,
		workbench = WorkbenchType.SHIPYARD, workbench_level = 2,
		ingredients = [{ item_id = "plasma_conduit", quantity = 2 }, { item_id = "quantum_chip", quantity = 1 }, { item_id = "alien_alloy", quantity = 1 }]
	})
	_register_recipe({
		id = "craft_mk3_landing", result_id = "mk3_landing", result_quantity = 1,
		workbench = WorkbenchType.SHIPYARD, workbench_level = 2,
		ingredients = [{ item_id = "titanium_weave", quantity = 2 }, { item_id = "quantum_chip", quantity = 1 }]
	})
	_register_recipe({
		id = "craft_mk3_jump_drive", result_id = "mk3_jump_drive", result_quantity = 1,
		workbench = WorkbenchType.SHIPYARD, workbench_level = 2,
		ingredients = [{ item_id = "quantum_chip", quantity = 2 }, { item_id = "fusion_catalyst", quantity = 1 }, { item_id = "alien_alloy", quantity = 1 }]
	})

# ============================================================
# WORKBENCH UPGRADE RECIPES
# ============================================================
func _register_workbench_upgrade_recipes():
	# Level 1 -> 2 upgrades
	_register_recipe({
		id = "upgrade_forge", result_id = "forge_upgrade", result_quantity = 1,
		workbench = WorkbenchType.FORGE, workbench_level = 1,
		ingredients = [{ item_id = "steel_plate", quantity = 8 }, { item_id = "energy_cell", quantity = 3 }]
	})
	_register_recipe({
		id = "upgrade_lab", result_id = "lab_upgrade", result_quantity = 1,
		workbench = WorkbenchType.LAB, workbench_level = 1,
		ingredients = [{ item_id = "bio_mesh", quantity = 5 }, { item_id = "energy_cell", quantity = 3 }]
	})
	_register_recipe({
		id = "upgrade_assembler", result_id = "assembler_upgrade", result_quantity = 1,
		workbench = WorkbenchType.ASSEMBLER, workbench_level = 1,
		ingredients = [{ item_id = "steel_plate", quantity = 5 }, { item_id = "energy_cell", quantity = 3 }, { item_id = "bio_fiber", quantity = 4 }]
	})
	_register_recipe({
		id = "upgrade_shipyard", result_id = "shipyard_upgrade", result_quantity = 1,
		workbench = WorkbenchType.SHIPYARD, workbench_level = 1,
		ingredients = [{ item_id = "steel_plate", quantity = 10 }, { item_id = "energy_cell", quantity = 4 }]
	})
