extends Node

# Durability wear rates
const SUIT_WEAR_RATE = 0.05
const HELMET_WEAR_RATE = 0.05
const BOOT_WEAR_RATE = 0.002
const REACTOR_WEAR_RATE = 0.01
const DEATH_DURABILITY_PENALTY = 5

const SAFE_BOX_SLOTS = 3
const BASE_STASH_SLOTS = 30

# Storage containers
var player_inventory: Array = []   # Items on person during a run
var player_equipment: Dictionary = {}  # EquipSlot -> item_instance
var ship_cargo: Array = []         # Items in ship during a run
var ship_equipment: Dictionary = {}    # ShipSlot -> item_instance
var ship_safe_box: Array = []      # 3 slots, survives death
var base_stash: Array = []         # Home base storage

var _next_instance_id: int = 0

func _ready():
	pass

# ============================================================
# INSTANCE CREATION
# ============================================================
func create_instance(item_id: String, quantity: int = 1) -> Dictionary:
	var item_def = Items.get_item(item_id)
	if item_def.is_empty():
		return {}
	_next_instance_id += 1
	return {
		item_id = item_id,
		quantity = quantity,
		current_durability = item_def.get("durability", -1),
		instance_id = str(_next_instance_id)
	}

# ============================================================
# ADD / REMOVE
# ============================================================
func add_item_to(storage: Array, item_id: String, quantity: int = 1, capacity: int = -1) -> bool:
	var item_def = Items.get_item(item_id)
	if item_def.is_empty():
		return false

	# Try stacking first
	if item_def.get("stackable", false):
		for inst in storage:
			if inst.item_id == item_id and inst.quantity < item_def.max_stack:
				var space = item_def.max_stack - inst.quantity
				var to_add = min(quantity, space)
				inst.quantity += to_add
				quantity -= to_add
				if quantity <= 0:
					return true

	# Add new stacks
	while quantity > 0:
		if capacity >= 0 and storage.size() >= capacity:
			return false  # Full
		var stack_size = min(quantity, item_def.get("max_stack", 1))
		var inst = create_instance(item_id, stack_size)
		storage.append(inst)
		quantity -= stack_size

	return true

func add_to_player_inventory(item_id: String, quantity: int = 1) -> bool:
	return add_item_to(player_inventory, item_id, quantity, get_inventory_capacity())

func add_to_ship_cargo(item_id: String, quantity: int = 1) -> bool:
	return add_item_to(ship_cargo, item_id, quantity, get_cargo_capacity())

func add_to_base_stash(item_id: String, quantity: int = 1) -> bool:
	return add_item_to(base_stash, item_id, quantity, BASE_STASH_SLOTS)

func add_to_safe_box(item_id: String, quantity: int = 1) -> bool:
	return add_item_to(ship_safe_box, item_id, quantity, SAFE_BOX_SLOTS)

func remove_item_from(storage: Array, instance_id: String, quantity: int = 1) -> bool:
	for i in range(storage.size()):
		if storage[i].instance_id == instance_id:
			if storage[i].quantity <= quantity:
				storage.remove_at(i)
			else:
				storage[i].quantity -= quantity
			return true
	return false

func remove_item_by_id_from(storage: Array, item_id: String, quantity: int = 1) -> bool:
	var remaining = quantity
	var indices_to_remove = []
	for i in range(storage.size()):
		if storage[i].item_id == item_id and remaining > 0:
			if storage[i].quantity <= remaining:
				remaining -= storage[i].quantity
				indices_to_remove.append(i)
			else:
				storage[i].quantity -= remaining
				remaining = 0
	# Remove in reverse order to preserve indices
	indices_to_remove.reverse()
	for idx in indices_to_remove:
		storage.remove_at(idx)
	return remaining <= 0

func count_item_in(storage: Array, item_id: String) -> int:
	var total = 0
	for inst in storage:
		if inst.item_id == item_id:
			total += inst.quantity
	return total

func count_item_in_stash(item_id: String) -> int:
	return count_item_in(base_stash, item_id)

# ============================================================
# TRANSFER
# ============================================================
func transfer_item(from_storage: Array, to_storage: Array, instance_id: String, to_capacity: int = -1) -> bool:
	var item_inst = null
	var from_idx = -1
	for i in range(from_storage.size()):
		if from_storage[i].instance_id == instance_id:
			item_inst = from_storage[i]
			from_idx = i
			break
	if item_inst == null:
		return false

	# Check if destination has room
	if to_capacity >= 0 and to_storage.size() >= to_capacity:
		# Try stacking
		var item_def = Items.get_item(item_inst.item_id)
		if item_def.get("stackable", false):
			for inst in to_storage:
				if inst.item_id == item_inst.item_id and inst.quantity < item_def.max_stack:
					var space = item_def.max_stack - inst.quantity
					var to_add = min(item_inst.quantity, space)
					inst.quantity += to_add
					item_inst.quantity -= to_add
					if item_inst.quantity <= 0:
						from_storage.remove_at(from_idx)
						return true
		return false  # Can't fit

	from_storage.remove_at(from_idx)
	to_storage.append(item_inst)
	return true

func transfer_all(from_storage: Array, to_storage: Array, to_capacity: int = -1):
	var transferred = []
	for inst in from_storage:
		if to_capacity >= 0 and to_storage.size() >= to_capacity:
			break
		to_storage.append(inst)
		transferred.append(inst)
	for inst in transferred:
		from_storage.erase(inst)

# ============================================================
# EQUIP / UNEQUIP
# ============================================================
func equip_player_item(instance_id: String, slot: int) -> bool:
	# Find in base_stash
	var item_inst = _find_instance_in(base_stash, instance_id)
	if item_inst == null:
		item_inst = _find_instance_in(player_inventory, instance_id)
	if item_inst == null:
		return false

	var item_def = Items.get_item(item_inst.item_id)
	if not item_def.has("equip_slot") or item_def.equip_slot != slot:
		return false

	# Unequip current
	if player_equipment.has(slot):
		unequip_player_item(slot)

	# Remove from source storage and equip
	_remove_instance_from_all(instance_id)
	player_equipment[slot] = item_inst
	return true

func unequip_player_item(slot: int) -> Dictionary:
	if not player_equipment.has(slot):
		return {}
	var item_inst = player_equipment[slot]
	player_equipment.erase(slot)
	base_stash.append(item_inst)
	return item_inst

func equip_ship_part(instance_id: String, slot: int) -> bool:
	var item_inst = _find_instance_in(base_stash, instance_id)
	if item_inst == null:
		return false

	var item_def = Items.get_item(item_inst.item_id)
	if not item_def.has("ship_slot") or item_def.ship_slot != slot:
		return false

	if ship_equipment.has(slot):
		unequip_ship_part(slot)

	_remove_instance_from_all(instance_id)
	ship_equipment[slot] = item_inst
	return true

func unequip_ship_part(slot: int) -> Dictionary:
	if not ship_equipment.has(slot):
		return {}
	var item_inst = ship_equipment[slot]
	ship_equipment.erase(slot)
	base_stash.append(item_inst)
	return item_inst

# ============================================================
# EQUIPMENT STAT HELPERS
# ============================================================
func get_player_stat(stat_name: String, default_value = 0):
	for slot in player_equipment:
		var inst = player_equipment[slot]
		var item_def = Items.get_item(inst.item_id)
		var stats = item_def.get("stats", {})
		if stats.has(stat_name):
			return stats[stat_name]
	return default_value

func get_ship_stat(stat_name: String, default_value = 0):
	for slot in ship_equipment:
		var inst = ship_equipment[slot]
		var item_def = Items.get_item(inst.item_id)
		var stats = item_def.get("stats", {})
		if stats.has(stat_name):
			return stats[stat_name]
	return default_value

func get_inventory_capacity() -> int:
	return int(get_player_stat("inventory_slots", 6))

func get_cargo_capacity() -> int:
	return int(get_ship_stat("cargo_slots", 4))

func get_equipped_item_def(equip_slot: int) -> Dictionary:
	if player_equipment.has(equip_slot):
		return Items.get_item(player_equipment[equip_slot].item_id)
	return {}

func get_equipped_ship_def(ship_slot: int) -> Dictionary:
	if ship_equipment.has(ship_slot):
		return Items.get_item(ship_equipment[ship_slot].item_id)
	return {}

# ============================================================
# DURABILITY
# ============================================================
func degrade_player_equipment(slot: int, amount: float):
	if not player_equipment.has(slot):
		return
	var inst = player_equipment[slot]
	if inst.current_durability < 0:  # Indestructible
		return
	inst.current_durability -= amount
	if inst.current_durability < 0:
		inst.current_durability = 0

func degrade_ship_equipment(slot: int, amount: float):
	if not ship_equipment.has(slot):
		return
	var inst = ship_equipment[slot]
	if inst.current_durability < 0:  # Indestructible
		return
	inst.current_durability -= amount
	if inst.current_durability < 0:
		inst.current_durability = 0

func _check_and_replace_broken(equipment: Dictionary, starter_prefix: String, is_ship: bool):
	var broken_slots = []
	for slot in equipment:
		var inst = equipment[slot]
		if inst.current_durability == 0:
			broken_slots.append(slot)

	for slot in broken_slots:
		equipment.erase(slot)
		# Replace with starter gear
		var starter_id = _get_starter_id(slot, is_ship)
		if starter_id != "":
			equipment[slot] = create_instance(starter_id)

func check_broken_equipment():
	_check_and_replace_broken(player_equipment, "starter_", false)
	_check_and_replace_broken(ship_equipment, "starter_", true)

func _get_starter_id(slot: int, is_ship: bool) -> String:
	if is_ship:
		match slot:
			Items.ShipSlot.HULL: return "starter_hull"
			Items.ShipSlot.REACTOR: return "starter_reactor"
			Items.ShipSlot.JUMP_DRIVE: return "starter_jump_drive"
			Items.ShipSlot.LANDING_SYSTEM: return "starter_landing"
			Items.ShipSlot.FUEL_TANK: return "starter_fuel_tank"
			Items.ShipSlot.WEAPONS: return ""  # No starter weapons
			Items.ShipSlot.CARGO: return "starter_cargo"
	else:
		match slot:
			Items.EquipSlot.HELMET: return "starter_helmet"
			Items.EquipSlot.SUIT: return "starter_suit"
			Items.EquipSlot.BACKPACK: return "starter_backpack"
			Items.EquipSlot.BOOTS: return "starter_boots"
			Items.EquipSlot.TOOL: return "starter_tool"
	return ""

# ============================================================
# DEATH / EXTRACTION
# ============================================================
func on_death():
	# Lose all carried items
	player_inventory.clear()
	ship_cargo.clear()

	# Apply death durability penalty to all equipped gear
	for slot in player_equipment:
		degrade_player_equipment(slot, DEATH_DURABILITY_PENALTY)
	for slot in ship_equipment:
		degrade_ship_equipment(slot, DEATH_DURABILITY_PENALTY)

	# Replace broken equipment with starter
	check_broken_equipment()

	# Transfer safe box to stash
	transfer_all(ship_safe_box, base_stash, BASE_STASH_SLOTS)

func on_extract():
	# Transfer all carried items to stash
	transfer_all(player_inventory, base_stash, BASE_STASH_SLOTS)
	transfer_all(ship_cargo, base_stash, BASE_STASH_SLOTS)
	transfer_all(ship_safe_box, base_stash, BASE_STASH_SLOTS)

	# Replace any broken equipment with starter
	check_broken_equipment()

# ============================================================
# SETUP
# ============================================================
func setup_starter_loadout():
	player_equipment.clear()
	ship_equipment.clear()
	player_inventory.clear()
	ship_cargo.clear()
	ship_safe_box.clear()
	base_stash.clear()

	# Equip starter gear
	player_equipment[Items.EquipSlot.HELMET] = create_instance("starter_helmet")
	player_equipment[Items.EquipSlot.SUIT] = create_instance("starter_suit")
	player_equipment[Items.EquipSlot.BACKPACK] = create_instance("starter_backpack")
	player_equipment[Items.EquipSlot.BOOTS] = create_instance("starter_boots")
	player_equipment[Items.EquipSlot.TOOL] = create_instance("starter_tool")

	# Equip starter ship
	ship_equipment[Items.ShipSlot.HULL] = create_instance("starter_hull")
	ship_equipment[Items.ShipSlot.REACTOR] = create_instance("starter_reactor")
	ship_equipment[Items.ShipSlot.JUMP_DRIVE] = create_instance("starter_jump_drive")
	ship_equipment[Items.ShipSlot.LANDING_SYSTEM] = create_instance("starter_landing")
	ship_equipment[Items.ShipSlot.FUEL_TANK] = create_instance("starter_fuel_tank")
	ship_equipment[Items.ShipSlot.CARGO] = create_instance("starter_cargo")

# ============================================================
# SERIALIZATION
# ============================================================
func to_dict() -> Dictionary:
	return {
		player_equipment = _serialize_equipment(player_equipment),
		ship_equipment = _serialize_equipment(ship_equipment),
		ship_safe_box = _serialize_storage(ship_safe_box),
		base_stash = _serialize_storage(base_stash),
		next_instance_id = _next_instance_id
	}

func from_dict(data: Dictionary):
	player_equipment = _deserialize_equipment(data.get("player_equipment", {}))
	ship_equipment = _deserialize_equipment(data.get("ship_equipment", {}))
	ship_safe_box = _deserialize_storage(data.get("ship_safe_box", []))
	base_stash = _deserialize_storage(data.get("base_stash", []))
	_next_instance_id = data.get("next_instance_id", 0)
	player_inventory.clear()
	ship_cargo.clear()

func _serialize_storage(storage: Array) -> Array:
	var result = []
	for inst in storage:
		result.append(inst.duplicate())
	return result

func _deserialize_storage(data: Array) -> Array:
	var result = []
	for d in data:
		result.append(d)
	return result

func _serialize_equipment(equipment: Dictionary) -> Dictionary:
	var result = {}
	for slot in equipment:
		result[str(slot)] = equipment[slot].duplicate()
	return result

func _deserialize_equipment(data: Dictionary) -> Dictionary:
	var result = {}
	for slot_str in data:
		result[int(slot_str)] = data[slot_str]
	return result

# ============================================================
# INTERNAL HELPERS
# ============================================================
func _find_instance_in(storage: Array, instance_id: String) -> Dictionary:
	for inst in storage:
		if inst.instance_id == instance_id:
			return inst
	return {}

func _remove_instance_from_all(instance_id: String):
	_remove_instance_from(base_stash, instance_id)
	_remove_instance_from(player_inventory, instance_id)
	_remove_instance_from(ship_cargo, instance_id)
	_remove_instance_from(ship_safe_box, instance_id)

func _remove_instance_from(storage: Array, instance_id: String):
	for i in range(storage.size()):
		if storage[i].instance_id == instance_id:
			storage.remove_at(i)
			return
