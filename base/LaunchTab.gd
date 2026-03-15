extends Control

func refresh():
	_update_summary()

func _ready():
	$LaunchButton.pressed.connect(_on_launch)

func _update_summary():
	var text = "=== LOADOUT SUMMARY ===\n\n"

	text += "-- Player Equipment --\n"
	for slot in Items.EquipSlot.values():
		var slot_name = Items.EquipSlot.keys()[slot]
		if Inventory.player_equipment.has(slot):
			var inst = Inventory.player_equipment[slot]
			var item_def = Items.get_item(inst.item_id)
			text += "  %s: %s" % [slot_name, item_def.get("name", "???")]
			if inst.current_durability >= 0:
				text += " [%d/%d]" % [inst.current_durability, item_def.get("durability", 1)]
			text += "\n"
		else:
			text += "  %s: [EMPTY]\n" % slot_name

	text += "\n-- Ship Equipment --\n"
	for slot in Items.ShipSlot.values():
		var slot_name = Items.ShipSlot.keys()[slot]
		if Inventory.ship_equipment.has(slot):
			var inst = Inventory.ship_equipment[slot]
			var item_def = Items.get_item(inst.item_id)
			text += "  %s: %s" % [slot_name, item_def.get("name", "???")]
			if inst.current_durability >= 0:
				text += " [%d/%d]" % [inst.current_durability, item_def.get("durability", 1)]
			text += "\n"
		else:
			text += "  %s: [EMPTY]\n" % slot_name

	text += "\n-- Derived Stats --\n"
	text += "  O2 Capacity: %d\n" % int(Inventory.get_player_stat("oxygen_capacity", 100))
	text += "  Ship Hull: %d HP\n" % int(Inventory.get_ship_stat("hull_hp", 5))
	text += "  Fuel Capacity: %d\n" % int(Inventory.get_ship_stat("fuel_capacity", 100))
	text += "  Inventory Slots: %d\n" % Inventory.get_inventory_capacity()
	text += "  Cargo Slots: %d\n" % Inventory.get_cargo_capacity()

	text += "\nWARNING: Non-starter gear loses durability during runs.\n"
	text += "Death = lose all carried items + durability penalty on equipment."

	$LoadoutSummary.text = text

func _on_launch():
	Game.startRun()
