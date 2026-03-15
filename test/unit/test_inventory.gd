extends GutTest

# Tests for data/inventory.gd - Inventory management system

var inv: Node


func before_each():
	inv = load("res://data/inventory.gd").new()
	add_child_autofree(inv)
	# Clear state
	inv.player_inventory.clear()
	inv.player_equipment.clear()
	inv.ship_cargo.clear()
	inv.ship_equipment.clear()
	inv.ship_safe_box.clear()
	inv.base_stash.clear()


func test_create_instance():
	var inst = inv.create_instance("iron_ore", 5)
	assert_false(inst.is_empty(), "Should create instance")
	assert_eq(inst.item_id, "iron_ore")
	assert_eq(inst.quantity, 5)
	assert_eq(inst.current_durability, -1, "Resources have no durability")
	assert_true(inst.instance_id != "", "Should have instance ID")


func test_create_instance_equipment():
	var inst = inv.create_instance("mk2_helmet")
	assert_eq(inst.item_id, "mk2_helmet")
	assert_eq(inst.quantity, 1)
	assert_eq(inst.current_durability, 20, "Mk2 helmet should have 20 durability")


func test_add_item_to_storage():
	var storage = []
	var result = inv.add_item_to(storage, "iron_ore", 5, 10)
	assert_true(result, "Should add successfully")
	assert_eq(storage.size(), 1)
	assert_eq(storage[0].item_id, "iron_ore")
	assert_eq(storage[0].quantity, 5)


func test_add_item_stacking():
	var storage = []
	inv.add_item_to(storage, "iron_ore", 5, 10)
	inv.add_item_to(storage, "iron_ore", 3, 10)
	assert_eq(storage.size(), 1, "Should stack into one slot")
	assert_eq(storage[0].quantity, 8)


func test_add_item_full_capacity():
	var storage = []
	inv.add_item_to(storage, "mk2_helmet", 1, 2)
	inv.add_item_to(storage, "mk2_suit", 1, 2)
	var result = inv.add_item_to(storage, "mk2_boots", 1, 2)
	assert_false(result, "Should fail when at capacity")
	assert_eq(storage.size(), 2)


func test_remove_item():
	var storage = []
	inv.add_item_to(storage, "iron_ore", 10, 30)
	var inst_id = storage[0].instance_id
	inv.remove_item_from(storage, inst_id, 3)
	assert_eq(storage[0].quantity, 7)


func test_remove_item_entire_stack():
	var storage = []
	inv.add_item_to(storage, "iron_ore", 5, 30)
	var inst_id = storage[0].instance_id
	inv.remove_item_from(storage, inst_id, 5)
	assert_eq(storage.size(), 0, "Should remove entire stack")


func test_remove_item_by_id():
	var storage = []
	inv.add_item_to(storage, "iron_ore", 10, 30)
	inv.add_item_to(storage, "bio_fiber", 5, 30)
	var result = inv.remove_item_by_id_from(storage, "iron_ore", 7)
	assert_true(result)
	assert_eq(inv.count_item_in(storage, "iron_ore"), 3)


func test_count_item_in():
	var storage = []
	inv.add_item_to(storage, "iron_ore", 15, 30)
	assert_eq(inv.count_item_in(storage, "iron_ore"), 15)
	assert_eq(inv.count_item_in(storage, "bio_fiber"), 0)


func test_transfer_item():
	var from = []
	var to = []
	inv.add_item_to(from, "iron_ore", 5, 30)
	var inst_id = from[0].instance_id
	var result = inv.transfer_item(from, to, inst_id, 30)
	assert_true(result)
	assert_eq(from.size(), 0)
	assert_eq(to.size(), 1)


func test_transfer_all():
	var from = []
	var to = []
	inv.add_item_to(from, "iron_ore", 5, 30)
	inv.add_item_to(from, "bio_fiber", 3, 30)
	inv.transfer_all(from, to, 30)
	assert_eq(from.size(), 0)
	assert_eq(to.size(), 2)


func test_setup_starter_loadout():
	inv.setup_starter_loadout()
	assert_true(inv.player_equipment.has(Items.EquipSlot.HELMET))
	assert_true(inv.player_equipment.has(Items.EquipSlot.SUIT))
	assert_true(inv.player_equipment.has(Items.EquipSlot.BACKPACK))
	assert_true(inv.player_equipment.has(Items.EquipSlot.BOOTS))
	assert_true(inv.player_equipment.has(Items.EquipSlot.TOOL))
	assert_true(inv.ship_equipment.has(Items.ShipSlot.HULL))
	assert_true(inv.ship_equipment.has(Items.ShipSlot.REACTOR))
	assert_eq(inv.player_equipment[Items.EquipSlot.HELMET].item_id, "starter_helmet")


func test_get_inventory_capacity_starter():
	inv.setup_starter_loadout()
	assert_eq(inv.get_inventory_capacity(), 6, "Starter backpack should give 6 slots")


func test_get_cargo_capacity_starter():
	inv.setup_starter_loadout()
	assert_eq(inv.get_cargo_capacity(), 4, "Starter cargo should give 4 slots")


func test_degrade_equipment():
	inv.setup_starter_loadout()
	# Starter gear is indestructible
	inv.degrade_player_equipment(Items.EquipSlot.HELMET, 5)
	assert_eq(inv.player_equipment[Items.EquipSlot.HELMET].current_durability, -1, "Starter gear should not degrade")

	# Add crafted gear and degrade it
	var mk2 = inv.create_instance("mk2_helmet")
	inv.player_equipment[Items.EquipSlot.HELMET] = mk2
	assert_eq(mk2.current_durability, 20)
	inv.degrade_player_equipment(Items.EquipSlot.HELMET, 5)
	assert_eq(inv.player_equipment[Items.EquipSlot.HELMET].current_durability, 15)


func test_degrade_to_zero():
	var mk2 = inv.create_instance("mk2_helmet")
	inv.player_equipment[Items.EquipSlot.HELMET] = mk2
	inv.degrade_player_equipment(Items.EquipSlot.HELMET, 25)
	assert_eq(inv.player_equipment[Items.EquipSlot.HELMET].current_durability, 0)


func test_check_broken_equipment_replaces_with_starter():
	inv.setup_starter_loadout()
	var mk2 = inv.create_instance("mk2_helmet")
	mk2.current_durability = 0
	inv.player_equipment[Items.EquipSlot.HELMET] = mk2
	inv.check_broken_equipment()
	assert_eq(inv.player_equipment[Items.EquipSlot.HELMET].item_id, "starter_helmet", "Should replace broken gear with starter")


func test_on_death_clears_inventory():
	inv.setup_starter_loadout()
	inv.add_item_to(inv.player_inventory, "iron_ore", 10, 6)
	inv.add_item_to(inv.ship_cargo, "bio_fiber", 5, 4)
	inv.add_item_to(inv.ship_safe_box, "titanium", 3, 3)
	inv.on_death()
	assert_eq(inv.player_inventory.size(), 0, "Player inventory should be cleared")
	assert_eq(inv.ship_cargo.size(), 0, "Ship cargo should be cleared")
	# Safe box transferred to stash
	assert_true(inv.base_stash.size() > 0, "Safe box items should transfer to stash")


func test_on_extract_transfers_all():
	inv.setup_starter_loadout()
	inv.add_item_to(inv.player_inventory, "iron_ore", 5, 6)
	inv.add_item_to(inv.ship_cargo, "bio_fiber", 3, 4)
	inv.add_item_to(inv.ship_safe_box, "titanium", 2, 3)
	inv.on_extract()
	assert_eq(inv.player_inventory.size(), 0)
	assert_eq(inv.ship_cargo.size(), 0)
	assert_eq(inv.ship_safe_box.size(), 0)
	assert_true(inv.base_stash.size() > 0, "Everything should be in stash")


func test_serialization_roundtrip():
	inv.setup_starter_loadout()
	inv.add_item_to(inv.base_stash, "iron_ore", 10, 30)
	var data = inv.to_dict()

	# Clear and restore
	inv.player_equipment.clear()
	inv.base_stash.clear()
	inv.from_dict(data)

	assert_true(inv.player_equipment.has(Items.EquipSlot.HELMET))
	assert_eq(inv.count_item_in(inv.base_stash, "iron_ore"), 10)
