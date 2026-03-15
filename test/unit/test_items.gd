extends GutTest

# Tests for data/items.gd - Item database

var items_db: Node


func before_each():
	items_db = load("res://data/items.gd").new()
	# Items needs Game autoload for PlanetBiome enum, create a mock
	add_child_autofree(items_db)


func test_database_populated():
	assert_true(items_db.database.size() > 0, "Database should have items after _ready")


func test_get_item_returns_valid():
	var item = items_db.get_item("iron_ore")
	assert_false(item.is_empty(), "Should find iron_ore")
	assert_eq(item.id, "iron_ore")
	assert_eq(item.name, "Iron Ore")


func test_get_item_invalid_returns_empty():
	var item = items_db.get_item("nonexistent_item")
	assert_true(item.is_empty(), "Should return empty for invalid item")


func test_starter_gear_is_indestructible():
	var starter_ids = ["starter_helmet", "starter_suit", "starter_backpack", "starter_boots", "starter_tool",
		"starter_hull", "starter_reactor", "starter_jump_drive", "starter_landing", "starter_fuel_tank", "starter_cargo"]
	for id in starter_ids:
		var item = items_db.get_item(id)
		assert_false(item.is_empty(), "Should find starter item: " + id)
		assert_eq(item.get("durability", 0), -1, "Starter " + id + " should be indestructible (durability=-1)")


func test_crafted_gear_has_durability():
	var crafted_ids = ["mk2_helmet", "mk2_suit", "mk2_backpack", "mk2_boots", "mk2_hull", "mk2_reactor"]
	for id in crafted_ids:
		var item = items_db.get_item(id)
		assert_false(item.is_empty(), "Should find crafted item: " + id)
		assert_true(item.get("durability", -1) > 0, "Crafted " + id + " should have positive durability")


func test_biome_resources_exist():
	# Each biome should have at least 3 resources (common, uncommon, rare)
	var biome_map = {
		Game.PlanetBiome.Mountain: ["iron_ore", "titanium", "crystal_shard"],
		Game.PlanetBiome.Forest: ["bio_fiber", "organic_compound", "rare_spores"],
		Game.PlanetBiome.Fungal: ["mycelium", "spore_cluster", "neural_tissue"],
		Game.PlanetBiome.Gas: ["plasma_gel", "volatile_gas", "quantum_dust"],
		Game.PlanetBiome.Water: ["hydro_crystal", "coral_extract", "deep_pearl"],
		Game.PlanetBiome.Lava: ["magma_core", "obsidian_shard", "fusion_catalyst"],
	}
	for biome in biome_map:
		for item_id in biome_map[biome]:
			var item = items_db.get_item(item_id)
			assert_false(item.is_empty(), "Should find " + item_id)
			assert_true(item.biomes.has(biome), item_id + " should be in correct biome")


func test_get_items_for_biome():
	var mountain_items = items_db.get_items_for_biome(Game.PlanetBiome.Mountain, 0)
	assert_true(mountain_items.size() >= 1, "Should find mountain items")
	# Should include universal items (empty biomes array) too
	var has_scrap = false
	for item in mountain_items:
		if item.id == "scrap_metal":
			has_scrap = true
	assert_true(has_scrap, "Universal items should appear in biome queries")


func test_rarity_enum_values():
	assert_eq(items_db.Rarity.COMMON, 0)
	assert_eq(items_db.Rarity.UNCOMMON, 1)
	assert_eq(items_db.Rarity.RARE, 2)
	assert_eq(items_db.Rarity.EPIC, 3)
	assert_eq(items_db.Rarity.LEGENDARY, 4)


func test_item_type_enum_values():
	assert_eq(items_db.ItemType.RESOURCE, 0)
	assert_eq(items_db.ItemType.EQUIPMENT, 1)
	assert_eq(items_db.ItemType.SHIP_PART, 2)
	assert_eq(items_db.ItemType.CONSUMABLE, 3)


func test_stackable_items_have_max_stack():
	for item in items_db.database.values():
		if item.get("stackable", false):
			assert_true(item.max_stack > 1, item.id + " stackable item should have max_stack > 1")


func test_equipment_has_equip_slot():
	for item in items_db.database.values():
		if item.type == items_db.ItemType.EQUIPMENT:
			assert_true(item.has("equip_slot"), item.id + " equipment should have equip_slot")


func test_ship_parts_have_ship_slot():
	for item in items_db.database.values():
		if item.type == items_db.ItemType.SHIP_PART:
			assert_true(item.has("ship_slot"), item.id + " ship part should have ship_slot")
