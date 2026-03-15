extends Node

# Item type classifications
enum ItemType { RESOURCE, EQUIPMENT, SHIP_PART, CONSUMABLE }
enum EquipSlot { HELMET, SUIT, BACKPACK, BOOTS, TOOL }
enum ShipSlot { HULL, REACTOR, JUMP_DRIVE, LANDING_SYSTEM, FUEL_TANK, WEAPONS, CARGO }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }

# Rarity colors for UI
const RARITY_COLORS = {
	Rarity.COMMON: Color(0.8, 0.8, 0.8),
	Rarity.UNCOMMON: Color(0.2, 0.8, 0.2),
	Rarity.RARE: Color(0.2, 0.4, 1.0),
	Rarity.EPIC: Color(0.6, 0.2, 0.8),
	Rarity.LEGENDARY: Color(1.0, 0.6, 0.0),
}

# All item definitions keyed by id
var database: Dictionary = {}

func _ready():
	_register_resources()
	_register_starter_gear()
	_register_crafted_equipment()
	_register_ship_parts()
	_register_consumables()
	_register_refined_materials()
	_register_workbench_upgrades()

func get_item(item_id: String) -> Dictionary:
	if database.has(item_id):
		return database[item_id]
	push_error("Item not found: " + item_id)
	return {}

func get_items_for_biome(biome: int, min_dist: float = 0.0) -> Array:
	var results = []
	for item in database.values():
		if item.type != ItemType.RESOURCE:
			continue
		if item.biomes.size() > 0 and not item.biomes.has(biome):
			continue
		if item.min_distance > min_dist:
			continue
		results.append(item)
	return results

func get_items_by_type(type: int) -> Array:
	var results = []
	for item in database.values():
		if item.type == type:
			results.append(item)
	return results

func get_items_by_equip_slot(slot: int) -> Array:
	var results = []
	for item in database.values():
		if item.has("equip_slot") and item.equip_slot == slot:
			results.append(item)
	return results

func get_items_by_ship_slot(slot: int) -> Array:
	var results = []
	for item in database.values():
		if item.has("ship_slot") and item.ship_slot == slot:
			results.append(item)
	return results

func _register(item: Dictionary):
	database[item.id] = item

# ============================================================
# RESOURCES - biome-specific gathering materials
# ============================================================
func _register_resources():
	# Mountain resources
	_register({
		id = "iron_ore", name = "Iron Ore", type = ItemType.RESOURCE,
		rarity = Rarity.COMMON, stackable = true, max_stack = 20,
		biomes = [Game.PlanetBiome.Mountain], min_distance = 0.0,
		description = "Common metal ore found in mountainous terrain."
	})
	_register({
		id = "titanium", name = "Titanium", type = ItemType.RESOURCE,
		rarity = Rarity.UNCOMMON, stackable = true, max_stack = 15,
		biomes = [Game.PlanetBiome.Mountain], min_distance = 5000.0,
		description = "Lightweight, strong metal. Essential for advanced crafting."
	})
	_register({
		id = "crystal_shard", name = "Crystal Shard", type = ItemType.RESOURCE,
		rarity = Rarity.RARE, stackable = true, max_stack = 10,
		biomes = [Game.PlanetBiome.Mountain], min_distance = 20000.0,
		description = "Resonating crystal fragment with unusual energy properties."
	})

	# Forest resources
	_register({
		id = "bio_fiber", name = "Bio Fiber", type = ItemType.RESOURCE,
		rarity = Rarity.COMMON, stackable = true, max_stack = 20,
		biomes = [Game.PlanetBiome.Forest], min_distance = 0.0,
		description = "Strong organic fibers harvested from alien flora."
	})
	_register({
		id = "organic_compound", name = "Organic Compound", type = ItemType.RESOURCE,
		rarity = Rarity.UNCOMMON, stackable = true, max_stack = 15,
		biomes = [Game.PlanetBiome.Forest], min_distance = 5000.0,
		description = "Complex biochemical compound with many applications."
	})
	_register({
		id = "rare_spores", name = "Rare Spores", type = ItemType.RESOURCE,
		rarity = Rarity.RARE, stackable = true, max_stack = 10,
		biomes = [Game.PlanetBiome.Forest], min_distance = 20000.0,
		description = "Bioluminescent spores with regenerative properties."
	})

	# Fungal resources
	_register({
		id = "mycelium", name = "Mycelium", type = ItemType.RESOURCE,
		rarity = Rarity.COMMON, stackable = true, max_stack = 20,
		biomes = [Game.PlanetBiome.Fungal], min_distance = 0.0,
		description = "Dense fungal network material. Surprisingly durable."
	})
	_register({
		id = "spore_cluster", name = "Spore Cluster", type = ItemType.RESOURCE,
		rarity = Rarity.UNCOMMON, stackable = true, max_stack = 15,
		biomes = [Game.PlanetBiome.Fungal], min_distance = 5000.0,
		description = "Concentrated spore mass with unique chemical properties."
	})
	_register({
		id = "neural_tissue", name = "Neural Tissue", type = ItemType.RESOURCE,
		rarity = Rarity.RARE, stackable = true, max_stack = 10,
		biomes = [Game.PlanetBiome.Fungal], min_distance = 20000.0,
		description = "Bio-electric tissue from sentient fungal networks."
	})

	# Gas resources
	_register({
		id = "plasma_gel", name = "Plasma Gel", type = ItemType.RESOURCE,
		rarity = Rarity.COMMON, stackable = true, max_stack = 20,
		biomes = [Game.PlanetBiome.Gas], min_distance = 0.0,
		description = "Ionized gas condensed into a gel. Highly reactive."
	})
	_register({
		id = "volatile_gas", name = "Volatile Gas", type = ItemType.RESOURCE,
		rarity = Rarity.UNCOMMON, stackable = true, max_stack = 15,
		biomes = [Game.PlanetBiome.Gas], min_distance = 5000.0,
		description = "Compressed unstable gas. Handle with care."
	})
	_register({
		id = "quantum_dust", name = "Quantum Dust", type = ItemType.RESOURCE,
		rarity = Rarity.RARE, stackable = true, max_stack = 10,
		biomes = [Game.PlanetBiome.Gas], min_distance = 20000.0,
		description = "Subatomic particles suspended in a visible cloud."
	})

	# Water resources
	_register({
		id = "hydro_crystal", name = "Hydro Crystal", type = ItemType.RESOURCE,
		rarity = Rarity.COMMON, stackable = true, max_stack = 20,
		biomes = [Game.PlanetBiome.Water], min_distance = 0.0,
		description = "Crystallized water with unusual molecular structure."
	})
	_register({
		id = "coral_extract", name = "Coral Extract", type = ItemType.RESOURCE,
		rarity = Rarity.UNCOMMON, stackable = true, max_stack = 15,
		biomes = [Game.PlanetBiome.Water], min_distance = 5000.0,
		description = "Bio-mineral extracted from alien coral formations."
	})
	_register({
		id = "deep_pearl", name = "Deep Pearl", type = ItemType.RESOURCE,
		rarity = Rarity.RARE, stackable = true, max_stack = 10,
		biomes = [Game.PlanetBiome.Water], min_distance = 20000.0,
		description = "Formed under immense pressure in ocean trenches."
	})

	# Lava resources
	_register({
		id = "magma_core", name = "Magma Core", type = ItemType.RESOURCE,
		rarity = Rarity.COMMON, stackable = true, max_stack = 20,
		biomes = [Game.PlanetBiome.Lava], min_distance = 0.0,
		description = "Solidified magma with a still-molten center."
	})
	_register({
		id = "obsidian_shard", name = "Obsidian Shard", type = ItemType.RESOURCE,
		rarity = Rarity.UNCOMMON, stackable = true, max_stack = 15,
		biomes = [Game.PlanetBiome.Lava], min_distance = 5000.0,
		description = "Razor-sharp volcanic glass. Excellent for cutting tools."
	})
	_register({
		id = "fusion_catalyst", name = "Fusion Catalyst", type = ItemType.RESOURCE,
		rarity = Rarity.RARE, stackable = true, max_stack = 10,
		biomes = [Game.PlanetBiome.Lava], min_distance = 20000.0,
		description = "Rare element that can trigger sustained fusion reactions."
	})

	# Universal resources (drop in any biome)
	_register({
		id = "scrap_metal", name = "Scrap Metal", type = ItemType.RESOURCE,
		rarity = Rarity.COMMON, stackable = true, max_stack = 30,
		biomes = [], min_distance = 0.0,
		description = "Salvageable metal fragments. Always useful."
	})
	_register({
		id = "energy_cell", name = "Energy Cell", type = ItemType.RESOURCE,
		rarity = Rarity.UNCOMMON, stackable = true, max_stack = 10,
		biomes = [], min_distance = 3000.0,
		description = "Portable power source. Required for many advanced recipes."
	})
	_register({
		id = "alien_alloy", name = "Alien Alloy", type = ItemType.RESOURCE,
		rarity = Rarity.EPIC, stackable = true, max_stack = 5,
		biomes = [], min_distance = 50000.0,
		description = "Unknown metallic compound of extraterrestrial origin."
	})
	_register({
		id = "void_essence", name = "Void Essence", type = ItemType.RESOURCE,
		rarity = Rarity.LEGENDARY, stackable = true, max_stack = 3,
		biomes = [], min_distance = 100000.0,
		description = "Distilled energy from the spaces between stars."
	})

# ============================================================
# REFINED MATERIALS - crafted from raw resources
# ============================================================
func _register_refined_materials():
	_register({
		id = "steel_plate", name = "Steel Plate", type = ItemType.RESOURCE,
		rarity = Rarity.COMMON, stackable = true, max_stack = 15,
		biomes = [], min_distance = 0.0,
		description = "Refined iron pressed into durable plating."
	})
	_register({
		id = "titanium_weave", name = "Titanium Weave", type = ItemType.RESOURCE,
		rarity = Rarity.UNCOMMON, stackable = true, max_stack = 10,
		biomes = [], min_distance = 0.0,
		description = "Woven titanium threads. Lightweight yet incredibly strong."
	})
	_register({
		id = "bio_mesh", name = "Bio Mesh", type = ItemType.RESOURCE,
		rarity = Rarity.UNCOMMON, stackable = true, max_stack = 10,
		biomes = [], min_distance = 0.0,
		description = "Organic compound woven into a flexible mesh."
	})
	_register({
		id = "plasma_conduit", name = "Plasma Conduit", type = ItemType.RESOURCE,
		rarity = Rarity.RARE, stackable = true, max_stack = 5,
		biomes = [], min_distance = 0.0,
		description = "Channels plasma energy safely. Essential for reactors."
	})
	_register({
		id = "quantum_chip", name = "Quantum Chip", type = ItemType.RESOURCE,
		rarity = Rarity.RARE, stackable = true, max_stack = 5,
		biomes = [], min_distance = 0.0,
		description = "Computation at the quantum level. Powers advanced systems."
	})
	_register({
		id = "fusion_core", name = "Fusion Core", type = ItemType.RESOURCE,
		rarity = Rarity.EPIC, stackable = true, max_stack = 3,
		biomes = [], min_distance = 0.0,
		description = "Sustained fusion reaction contained in a portable core."
	})

# ============================================================
# STARTER GEAR - indestructible, always available
# ============================================================
func _register_starter_gear():
	_register({
		id = "starter_helmet", name = "Starter Helmet", type = ItemType.EQUIPMENT,
		rarity = Rarity.COMMON, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.HELMET, durability = -1,
		stats = { oxygen_capacity = 100, oxygen_efficiency = 1.0 },
		biomes = [], min_distance = 0.0,
		description = "Basic space helmet. Gets the job done."
	})
	_register({
		id = "starter_suit", name = "Starter Suit", type = ItemType.EQUIPMENT,
		rarity = Rarity.COMMON, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.SUIT, durability = -1,
		stats = { damage_resistance = 0, speed_modifier = 1.0 },
		biomes = [], min_distance = 0.0,
		description = "Standard-issue space suit. No frills."
	})
	_register({
		id = "starter_backpack", name = "Starter Backpack", type = ItemType.EQUIPMENT,
		rarity = Rarity.COMMON, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.BACKPACK, durability = -1,
		stats = { inventory_slots = 6 },
		biomes = [], min_distance = 0.0,
		description = "Small storage pack. Better than nothing."
	})
	_register({
		id = "starter_boots", name = "Starter Boots", type = ItemType.EQUIPMENT,
		rarity = Rarity.COMMON, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.BOOTS, durability = -1,
		stats = { speed_modifier = 1.0 },
		biomes = [], min_distance = 0.0,
		description = "Basic mag-boots. They keep you grounded."
	})
	_register({
		id = "starter_tool", name = "Starter Multi-Tool", type = ItemType.EQUIPMENT,
		rarity = Rarity.COMMON, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.TOOL, durability = -1,
		stats = { gathering_bonus = 1.0 },
		biomes = [], min_distance = 0.0,
		description = "All-purpose tool. Slow but reliable."
	})

	# Starter ship parts
	_register({
		id = "starter_hull", name = "Starter Hull", type = ItemType.SHIP_PART,
		rarity = Rarity.COMMON, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.HULL, durability = -1,
		stats = { hull_hp = 5 },
		biomes = [], min_distance = 0.0,
		description = "Basic ship hull. Held together with hope."
	})
	_register({
		id = "starter_reactor", name = "Starter Reactor", type = ItemType.SHIP_PART,
		rarity = Rarity.COMMON, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.REACTOR, durability = -1,
		stats = { fuel_efficiency = 1.0 },
		biomes = [], min_distance = 0.0,
		description = "Basic power reactor. Burns fuel at standard rate."
	})
	_register({
		id = "starter_jump_drive", name = "Starter Jump Drive", type = ItemType.SHIP_PART,
		rarity = Rarity.COMMON, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.JUMP_DRIVE, durability = -1,
		stats = { jump_range = 1.0 },
		biomes = [], min_distance = 0.0,
		description = "Gets you from A to B. Eventually."
	})
	_register({
		id = "starter_landing", name = "Starter Landing System", type = ItemType.SHIP_PART,
		rarity = Rarity.COMMON, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.LANDING_SYSTEM, durability = -1,
		stats = { landing_speed_reduction = 0.0 },
		biomes = [], min_distance = 0.0,
		description = "More of a crash system, really."
	})
	_register({
		id = "starter_fuel_tank", name = "Starter Fuel Tank", type = ItemType.SHIP_PART,
		rarity = Rarity.COMMON, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.FUEL_TANK, durability = -1,
		stats = { fuel_capacity = 100 },
		biomes = [], min_distance = 0.0,
		description = "Standard fuel tank. Holds 100 units."
	})
	_register({
		id = "starter_cargo", name = "Starter Cargo Bay", type = ItemType.SHIP_PART,
		rarity = Rarity.COMMON, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.CARGO, durability = -1,
		stats = { cargo_slots = 4 },
		biomes = [], min_distance = 0.0,
		description = "Small cargo hold. Fits the essentials."
	})

# ============================================================
# CRAFTED EQUIPMENT - has durability, better stats
# ============================================================
func _register_crafted_equipment():
	# Mk2 gear
	_register({
		id = "mk2_helmet", name = "Mk2 Helmet", type = ItemType.EQUIPMENT,
		rarity = Rarity.UNCOMMON, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.HELMET, durability = 20,
		stats = { oxygen_capacity = 150, oxygen_efficiency = 0.7 },
		biomes = [], min_distance = 0.0,
		description = "Enhanced helmet with improved O2 recycling."
	})
	_register({
		id = "mk2_suit", name = "Mk2 Suit", type = ItemType.EQUIPMENT,
		rarity = Rarity.UNCOMMON, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.SUIT, durability = 15,
		stats = { damage_resistance = 1, speed_modifier = 1.1 },
		biomes = [], min_distance = 0.0,
		description = "Reinforced suit with servo-assisted movement."
	})
	_register({
		id = "mk2_backpack", name = "Mk2 Backpack", type = ItemType.EQUIPMENT,
		rarity = Rarity.UNCOMMON, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.BACKPACK, durability = 25,
		stats = { inventory_slots = 10 },
		biomes = [], min_distance = 0.0,
		description = "Expanded storage with reinforced straps."
	})
	_register({
		id = "mk2_boots", name = "Mk2 Boots", type = ItemType.EQUIPMENT,
		rarity = Rarity.UNCOMMON, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.BOOTS, durability = 20,
		stats = { speed_modifier = 1.2 },
		biomes = [], min_distance = 0.0,
		description = "Enhanced mag-boots with powered stride assist."
	})
	_register({
		id = "mk2_tool", name = "Mk2 Multi-Tool", type = ItemType.EQUIPMENT,
		rarity = Rarity.UNCOMMON, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.TOOL, durability = 20,
		stats = { gathering_bonus = 1.5 },
		biomes = [], min_distance = 0.0,
		description = "Improved tool with laser-assist gathering."
	})

	# Mk3 gear
	_register({
		id = "mk3_helmet", name = "Mk3 Helmet", type = ItemType.EQUIPMENT,
		rarity = Rarity.RARE, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.HELMET, durability = 35,
		stats = { oxygen_capacity = 200, oxygen_efficiency = 0.5 },
		biomes = [], min_distance = 0.0,
		description = "Advanced helmet with quantum O2 filtration."
	})
	_register({
		id = "mk3_suit", name = "Mk3 Suit", type = ItemType.EQUIPMENT,
		rarity = Rarity.RARE, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.SUIT, durability = 25,
		stats = { damage_resistance = 2, speed_modifier = 1.2 },
		biomes = [], min_distance = 0.0,
		description = "Powered exo-suit with active armor plating."
	})
	_register({
		id = "mk3_backpack", name = "Mk3 Backpack", type = ItemType.EQUIPMENT,
		rarity = Rarity.RARE, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.BACKPACK, durability = 40,
		stats = { inventory_slots = 16 },
		biomes = [], min_distance = 0.0,
		description = "Compression storage. Holds far more than it should."
	})
	_register({
		id = "mk3_boots", name = "Mk3 Boots", type = ItemType.EQUIPMENT,
		rarity = Rarity.RARE, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.BOOTS, durability = 30,
		stats = { speed_modifier = 1.4 },
		biomes = [], min_distance = 0.0,
		description = "Gravity-assist boots. Almost like flying."
	})
	_register({
		id = "mk3_tool", name = "Mk3 Multi-Tool", type = ItemType.EQUIPMENT,
		rarity = Rarity.RARE, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.TOOL, durability = 30,
		stats = { gathering_bonus = 2.0 },
		biomes = [], min_distance = 0.0,
		description = "Quantum extraction tool. Pulls resources from thin air."
	})

	# Legendary void gear
	_register({
		id = "void_helmet", name = "Void Walker Helmet", type = ItemType.EQUIPMENT,
		rarity = Rarity.LEGENDARY, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.HELMET, durability = 50,
		stats = { oxygen_capacity = 300, oxygen_efficiency = 0.3 },
		biomes = [], min_distance = 0.0,
		description = "Forged from void essence. Barely needs atmosphere."
	})
	_register({
		id = "void_suit", name = "Void Walker Suit", type = ItemType.EQUIPMENT,
		rarity = Rarity.LEGENDARY, stackable = false, max_stack = 1,
		equip_slot = EquipSlot.SUIT, durability = 40,
		stats = { damage_resistance = 3, speed_modifier = 1.4 },
		biomes = [], min_distance = 0.0,
		description = "Phase-shifting armor. Partly exists in another dimension."
	})

# ============================================================
# SHIP PARTS - craftable upgrades
# ============================================================
func _register_ship_parts():
	# Mk2 ship parts
	_register({
		id = "mk2_hull", name = "Mk2 Hull", type = ItemType.SHIP_PART,
		rarity = Rarity.UNCOMMON, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.HULL, durability = 25,
		stats = { hull_hp = 8 },
		biomes = [], min_distance = 0.0,
		description = "Reinforced hull plating. Takes a beating."
	})
	_register({
		id = "mk2_reactor", name = "Mk2 Reactor", type = ItemType.SHIP_PART,
		rarity = Rarity.UNCOMMON, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.REACTOR, durability = 20,
		stats = { fuel_efficiency = 0.75 },
		biomes = [], min_distance = 0.0,
		description = "Improved reactor. 25% less fuel consumption."
	})
	_register({
		id = "mk2_jump_drive", name = "Mk2 Jump Drive", type = ItemType.SHIP_PART,
		rarity = Rarity.UNCOMMON, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.JUMP_DRIVE, durability = 20,
		stats = { jump_range = 1.5 },
		biomes = [], min_distance = 0.0,
		description = "Extended range jump drive. Go further, faster."
	})
	_register({
		id = "mk2_landing", name = "Mk2 Landing System", type = ItemType.SHIP_PART,
		rarity = Rarity.UNCOMMON, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.LANDING_SYSTEM, durability = 20,
		stats = { landing_speed_reduction = 0.2 },
		biomes = [], min_distance = 0.0,
		description = "Retro-thrusters for controlled descent."
	})
	_register({
		id = "mk2_fuel_tank", name = "Mk2 Fuel Tank", type = ItemType.SHIP_PART,
		rarity = Rarity.UNCOMMON, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.FUEL_TANK, durability = 25,
		stats = { fuel_capacity = 150 },
		biomes = [], min_distance = 0.0,
		description = "Expanded fuel storage. 50% more capacity."
	})
	_register({
		id = "mk2_weapons", name = "Mk2 Turret", type = ItemType.SHIP_PART,
		rarity = Rarity.UNCOMMON, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.WEAPONS, durability = 20,
		stats = { weapon_damage = 1, fire_rate = 1.0 },
		biomes = [], min_distance = 0.0,
		description = "Auto-targeting turret. Keeps aliens at bay."
	})
	_register({
		id = "mk2_cargo", name = "Mk2 Cargo Bay", type = ItemType.SHIP_PART,
		rarity = Rarity.UNCOMMON, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.CARGO, durability = 25,
		stats = { cargo_slots = 8 },
		biomes = [], min_distance = 0.0,
		description = "Doubled cargo capacity with smart shelving."
	})

	# Mk3 ship parts
	_register({
		id = "mk3_hull", name = "Mk3 Hull", type = ItemType.SHIP_PART,
		rarity = Rarity.RARE, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.HULL, durability = 40,
		stats = { hull_hp = 12 },
		biomes = [], min_distance = 0.0,
		description = "Titanium-alloy hull. Nearly impervious."
	})
	_register({
		id = "mk3_reactor", name = "Mk3 Reactor", type = ItemType.SHIP_PART,
		rarity = Rarity.RARE, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.REACTOR, durability = 35,
		stats = { fuel_efficiency = 0.5 },
		biomes = [], min_distance = 0.0,
		description = "Fusion reactor. Half the fuel, double the power."
	})
	_register({
		id = "mk3_fuel_tank", name = "Mk3 Fuel Tank", type = ItemType.SHIP_PART,
		rarity = Rarity.RARE, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.FUEL_TANK, durability = 40,
		stats = { fuel_capacity = 200 },
		biomes = [], min_distance = 0.0,
		description = "Compressed fuel storage. Double standard capacity."
	})
	_register({
		id = "mk3_cargo", name = "Mk3 Cargo Bay", type = ItemType.SHIP_PART,
		rarity = Rarity.RARE, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.CARGO, durability = 40,
		stats = { cargo_slots = 14 },
		biomes = [], min_distance = 0.0,
		description = "Compression cargo bay. Defies spatial logic."
	})
	_register({
		id = "mk3_weapons", name = "Mk3 Plasma Cannon", type = ItemType.SHIP_PART,
		rarity = Rarity.RARE, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.WEAPONS, durability = 30,
		stats = { weapon_damage = 2, fire_rate = 1.5 },
		biomes = [], min_distance = 0.0,
		description = "Plasma-based weapons system. Devastating."
	})
	_register({
		id = "mk3_landing", name = "Mk3 Landing System", type = ItemType.SHIP_PART,
		rarity = Rarity.RARE, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.LANDING_SYSTEM, durability = 30,
		stats = { landing_speed_reduction = 0.4 },
		biomes = [], min_distance = 0.0,
		description = "Gravity dampeners for a smooth touchdown."
	})
	_register({
		id = "mk3_jump_drive", name = "Mk3 Jump Drive", type = ItemType.SHIP_PART,
		rarity = Rarity.RARE, stackable = false, max_stack = 1,
		ship_slot = ShipSlot.JUMP_DRIVE, durability = 30,
		stats = { jump_range = 2.0 },
		biomes = [], min_distance = 0.0,
		description = "Quantum tunneling drive. Bends space itself."
	})

# ============================================================
# CONSUMABLES
# ============================================================
func _register_consumables():
	_register({
		id = "repair_kit", name = "Repair Kit", type = ItemType.CONSUMABLE,
		rarity = Rarity.UNCOMMON, stackable = true, max_stack = 5,
		biomes = [], min_distance = 0.0,
		stats = { repair_amount = 5 },
		description = "Restores 5 durability to any equipped item."
	})
	_register({
		id = "emergency_o2", name = "Emergency O2 Tank", type = ItemType.CONSUMABLE,
		rarity = Rarity.COMMON, stackable = true, max_stack = 5,
		biomes = [], min_distance = 0.0,
		stats = { oxygen_restore = 50 },
		description = "Portable oxygen. Restores 50 O2."
	})
	_register({
		id = "fuel_cell", name = "Portable Fuel Cell", type = ItemType.CONSUMABLE,
		rarity = Rarity.UNCOMMON, stackable = true, max_stack = 5,
		biomes = [], min_distance = 0.0,
		stats = { fuel_restore = 30 },
		description = "Emergency fuel supply. Restores 30 fuel."
	})

# ============================================================
# WORKBENCH UPGRADES
# ============================================================
func _register_workbench_upgrades():
	_register({
		id = "forge_upgrade", name = "Forge Upgrade Kit", type = ItemType.RESOURCE,
		rarity = Rarity.RARE, stackable = true, max_stack = 1,
		biomes = [], min_distance = 0.0,
		description = "Upgrade materials to improve the Forge to the next level."
	})
	_register({
		id = "lab_upgrade", name = "Lab Upgrade Kit", type = ItemType.RESOURCE,
		rarity = Rarity.RARE, stackable = true, max_stack = 1,
		biomes = [], min_distance = 0.0,
		description = "Upgrade materials to improve the Lab to the next level."
	})
	_register({
		id = "assembler_upgrade", name = "Assembler Upgrade Kit", type = ItemType.RESOURCE,
		rarity = Rarity.RARE, stackable = true, max_stack = 1,
		biomes = [], min_distance = 0.0,
		description = "Upgrade materials to improve the Assembler to the next level."
	})
	_register({
		id = "shipyard_upgrade", name = "Shipyard Upgrade Kit", type = ItemType.RESOURCE,
		rarity = Rarity.RARE, stackable = true, max_stack = 1,
		biomes = [], min_distance = 0.0,
		description = "Upgrade materials to improve the Shipyard to the next level."
	})
