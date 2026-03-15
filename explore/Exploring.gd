extends Node2D

const MAX_FUEL_SCALE = 3.96
const SHIP_ENTER_DISTANCE = 150

# Wormhole spawn chance: ~30% base, increases with toxicity/radius
const WORMHOLE_BASE_CHANCE = 0.30

var minimumLaunchFuel = 30

var fuelScene = load("res://explore/Fuel.tscn")
var repairScene = load("res://explore/Repair.tscn")
var airPocketScene = load("res://explore/AirPocket.tscn")
var lootPickupScene = load("res://explore/LootPickup.tscn")
var wormholeScene = load("res://explore/Wormhole.tscn")
var deathMarkerScene = load("res://multiplayer/DeathMarker.tscn")

var tileSource = 0
var openAtlasCoords = Vector2i(0, 0)
var closedAtlasCoords = Vector2i(1, 0)

var mouseOnShip = false
var playerStartPos = Vector2(0, 0)
var near_ship = false
var safe_box_open = false

var safe_box_layer: CanvasLayer
var sb_inv_container: VBoxContainer
var sb_box_container: VBoxContainer
var ship_prompt_label: Label
var inventory_open: bool = false
var inv_layer: CanvasLayer
var inv_container: VBoxContainer

func _ready():
	setTileSource()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	placeWorld()
	Game.oxygen = Game.maxOxygen
	Game.planetsLandedOn += 1
	Game.playerInAirPocket = false

	# Degrade landing system on crash landing
	var gravity_factor = clamp(Game.currentPlanet.gravity / 40.0, 1, 3)
	Inventory.degrade_ship_equipment(Items.ShipSlot.LANDING_SYSTEM, gravity_factor)

	_create_safe_box_ui()
	_create_ship_prompt()
	_create_inventory_overlay()

	if MP.weeklyMode:
		MP.death_markers_loaded.connect(_on_death_markers_loaded)
		MP.fetchDeathMarkers(2)

func _physics_process(delta):
	near_ship = $CharacterBody2D.global_position.distance_to($"World/ship-top".global_position) < SHIP_ENTER_DISTANCE
	if near_ship and mouseOnShip:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		$"World/ship-top".frame = 1
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		$"World/ship-top".frame = 0
	if ship_prompt_label:
		ship_prompt_label.visible = near_ship and not safe_box_open

func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			if safe_box_open:
				_close_safe_box()
			elif near_ship and not inventory_open:
				_open_safe_box()
		elif event.keycode == KEY_TAB:
			if inventory_open:
				_close_inventory()
			elif not safe_box_open:
				_open_inventory()

func _process(delta):
	$UI.global_position = $CharacterBody2D/Camera2D.get_screen_center_position()
	$UI.global_position.x -= get_viewport_rect().size.x/2
	$UI.global_position.y -= get_viewport_rect().size.y/2

	$"UI/fuel-icon/fuel-body".scale.x = Game.fuel / float(Game.maxFuel) * MAX_FUEL_SCALE
	$"UI/o2/o2-body".scale.x = Game.oxygen / float(Game.maxOxygen) * MAX_FUEL_SCALE

	if $"UI/fuel-icon/fuel-body".scale.x > MAX_FUEL_SCALE:
		$"UI/fuel-icon/fuel-body".scale.x = MAX_FUEL_SCALE
	if $"UI/o2/o2-body".scale.x > MAX_FUEL_SCALE:
		$"UI/o2/o2-body".scale.x = MAX_FUEL_SCALE

	if Game.playerInAirPocket:
		if Game.oxygen < Game.maxOxygen:
			Game.oxygen += delta * Game.AIR_POCKET_OXYGEN_RATE
	else:
		var drain = delta * Game.currentPlanet.atmosphereToxicity * Game.oxygenEfficiency
		Game.oxygen -= drain

		# Degrade helmet and suit based on toxicity
		var toxicity = Game.currentPlanet.atmosphereToxicity
		Inventory.degrade_player_equipment(Items.EquipSlot.HELMET, delta * toxicity * Inventory.HELMET_WEAR_RATE)
		Inventory.degrade_player_equipment(Items.EquipSlot.SUIT, delta * toxicity * Inventory.SUIT_WEAR_RATE)

	if MP.weeklyMode:
		MP.updatePosition(2, $CharacterBody2D.global_position)

	if Game.oxygen <= 0:
		Game.oxygen = 0
		$CharacterBody2D.die()

	# Auto-refresh inventory overlay if open (throttled to ~2 fps)
	if inventory_open and inv_layer.visible:
		if Engine.get_frames_drawn() % 30 == 0:
			_refresh_inventory_overlay()

func setTileSource():
	tileSource = 0
	if Game.currentPlanet.biome == Game.PlanetBiome.Forest:
		tileSource = 1
	elif Game.currentPlanet.biome == Game.PlanetBiome.Gas:
		tileSource = 2
	elif Game.currentPlanet.biome == Game.PlanetBiome.Water:
		tileSource = 3
	elif Game.currentPlanet.biome == Game.PlanetBiome.Fungal:
		tileSource = 4
	elif Game.currentPlanet.biome == Game.PlanetBiome.Lava:
		tileSource = 5

func nextPhase():
	Game.setPhase(3)

func _on_Transition_TransitionIn():
	$CharacterBody2D/Camera2D.make_current()

func placeWorld():
	var map = generateMap()

	var numberOfFuel = Game.currentPlanet.atmosphereToxicity * Game.currentPlanet.radius / 2.25
	var numberOfRepair = randi()%5
	var numberOfAirPockets = randi()%(3 + int(Game.currentPlanet.atmosphereToxicity))

	if Game.shipHealth > 3:
		numberOfRepair -= 1
	if Game.currentPlanet.atmosphereToxicity < (Game.MAX_ATMO_TOXIC/2):
		numberOfRepair -= 1

	var openSpots = []

	var playerStart = Vector2(0,0)
	for y in range(map.size()):
		for x in range(map[y].size()):
			if map[y][x] == 0:
				$TileMap.set_cell(0, Vector2i(x, y), tileSource, openAtlasCoords)
				openSpots.append(Vector2(x,y))
				playerStart.x = x
				playerStart.y = y
			else:
				$TileMap.set_cell(0, Vector2i(x, y), tileSource, closedAtlasCoords)

	playerStartPos = playerStart

	for i in range(numberOfFuel):
		_spawn_at_random(fuelScene, openSpots)

	for i in range(numberOfRepair):
		_spawn_at_random(repairScene, openSpots)

	for i in range(numberOfAirPockets):
		_spawn_at_random(airPocketScene, openSpots)

	# Spawn loot pickups
	_spawn_loot(openSpots)

	# Spawn wormhole (chance-based)
	_try_spawn_wormhole(openSpots)

	# position player start
	$CharacterBody2D.global_position = $TileMap.map_to_local(Vector2i(playerStart.x, playerStart.y))
	$CharacterBody2D.global_position.x += 32
	$CharacterBody2D.global_position.y += 32

	# make sure we dont open an out of world path
	for x in range(playerStart.x-9, playerStart.x+5):
		for y in range(playerStart.y-7, playerStart.y+7):
			if $TileMap.get_cell_source_id(0, Vector2i(x,y)) < 0:
				$TileMap.set_cell(0, Vector2i(x,y), tileSource, closedAtlasCoords)

	# make space for crash zone
	for x in range(playerStart.x-6, playerStart.x+2):
		for y in range(playerStart.y-4, playerStart.y+4):
			$TileMap.set_cell(0, Vector2i(x,y), tileSource, openAtlasCoords)

	$"World/ship-top".global_position = $CharacterBody2D.global_position
	$"World/ship-top".global_position.x -= 128

func _spawn_at_random(scene: PackedScene, openSpots: Array):
	if openSpots.size() == 0:
		return
	var randomLoc = randi() % openSpots.size()
	var randomSpot = openSpots[randomLoc]
	var loc = $TileMap.map_to_local(Vector2i(randomSpot.x, randomSpot.y))
	var instance = scene.instantiate()
	instance.position = loc
	instance.position.x += 32
	instance.position.y += 32
	$World.add_child(instance)
	openSpots.erase(randomSpot)

func _spawn_loot(openSpots: Array):
	var biome = Game.currentPlanet.biome
	var dist = Game.getMilesTraveled()
	var available_items = Items.get_items_for_biome(biome, dist)

	if available_items.size() == 0:
		return

	# Number of loot drops scales with radius and distance
	var base_loot = int(Game.currentPlanet.radius / 8.0)
	var distance_bonus = int(dist / 20000.0)
	var num_loot = max(2, base_loot + distance_bonus)
	num_loot = int(num_loot * Game.gatheringBonus)

	for i in range(num_loot):
		if openSpots.size() == 0:
			break

		# Weighted random selection - rarer items less likely
		var item = _pick_weighted_item(available_items)

		var randomLoc = randi() % openSpots.size()
		var randomSpot = openSpots[randomLoc]
		var loc = $TileMap.map_to_local(Vector2i(randomSpot.x, randomSpot.y))

		var loot = lootPickupScene.instantiate()
		loot.position = loc
		loot.position.x += 32
		loot.position.y += 32
		loot.init(item.id, 1)
		$World.add_child(loot)

		openSpots.erase(randomSpot)

func _pick_weighted_item(available: Array) -> Dictionary:
	# Weight by inverse rarity: common=10, uncommon=5, rare=2, epic=1, legendary=0.5
	var weights = {
		Items.Rarity.COMMON: 10.0,
		Items.Rarity.UNCOMMON: 5.0,
		Items.Rarity.RARE: 2.0,
		Items.Rarity.EPIC: 1.0,
		Items.Rarity.LEGENDARY: 0.5,
	}
	var total = 0.0
	for item in available:
		total += weights.get(item.get("rarity", Items.Rarity.COMMON), 1.0)

	var roll = randf() * total
	var cumulative = 0.0
	for item in available:
		cumulative += weights.get(item.get("rarity", Items.Rarity.COMMON), 1.0)
		if roll <= cumulative:
			return item

	return available[0]

func _try_spawn_wormhole(openSpots: Array):
	if openSpots.size() < 3:
		return

	# Chance increases with toxicity and radius
	var chance = WORMHOLE_BASE_CHANCE
	chance += Game.currentPlanet.atmosphereToxicity * 0.03
	chance += Game.currentPlanet.radius / 200.0

	if randf() > chance:
		return  # No wormhole this time

	# Place far from player start (find the farthest open spot)
	var best_spot = openSpots[0]
	var best_dist = 0.0
	for spot in openSpots:
		var d = spot.distance_to(playerStartPos)
		if d > best_dist:
			best_dist = d
			best_spot = spot

	var loc = $TileMap.map_to_local(Vector2i(best_spot.x, best_spot.y))
	var wormhole = wormholeScene.instantiate()
	wormhole.position = loc
	wormhole.position.x += 32
	wormhole.position.y += 32
	$World.add_child(wormhole)
	openSpots.erase(best_spot)

func generateMapOpen(dimensions):
	var array = []
	for i in range(0, dimensions):
		array.append([])
		for j in range(0, dimensions):
			array[i].append(1)
	return array

func generateMap():
	var dimensions = int(floor(Game.currentPlanet.radius*4))
	var maxTunnels = int(floor(randf_range(dimensions*.75, dimensions*4)))
	var maxLength = int(floor(randf_range(2,20)))
	var map = generateMapOpen(dimensions)
	var currentRow = randi()%dimensions
	var currentCol = randi()%dimensions

	var directions = [Vector2(-1,0), Vector2(1,0), Vector2(0,-1), Vector2(0,1)]
	var lastDirection = Vector2(0, 0)
	var randomDirection

	while maxTunnels > 0:
		randomDirection = directions[randi()%directions.size()]
		while (randomDirection.x == -lastDirection.x and randomDirection.y == -lastDirection.y) or (randomDirection.x == lastDirection.x and randomDirection.y == lastDirection.y):
			randomDirection = directions[randi()%directions.size()]

		var randomLength = randi()%maxLength+1
		var tunnelLength = 0

		while tunnelLength < randomLength:
			if (
				((currentRow == 1) and (randomDirection.x == -1)) or
				((currentCol == 1) and (randomDirection.y == -1)) or
				((currentRow >= dimensions - 2) and (randomDirection.x == 1)) or
				((currentCol >= dimensions - 2) and (randomDirection.y == 1))
			):
				break
			else:
				map[currentRow][currentCol] = 0
				currentRow += randomDirection.x
				currentCol += randomDirection.y
				tunnelLength += 1

		if tunnelLength > 0:
			lastDirection = randomDirection
			maxTunnels -= 1

	return map

func _on_Area2D_input_event(viewport, event, shape_idx):
	if $CharacterBody2D.dying or safe_box_open:
		return
	if near_ship:
		if event is InputEventMouseButton and event.pressed:
			if Game.fuel >= minimumLaunchFuel:
				nextPhase()
			if Game.cheaterMode:
				nextPhase()

func _on_Area2D_mouse_entered():
	mouseOnShip = true

func _on_Area2D_mouse_exited():
	mouseOnShip = false

func _create_inventory_overlay():
	# Always-visible TAB hint
	var hint_layer = CanvasLayer.new()
	hint_layer.layer = 89
	add_child(hint_layer)
	var hint = Label.new()
	hint.text = "[TAB] Inventory"
	hint.add_theme_font_size_override("font_size", 11)
	hint.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 0.6))
	hint.position = Vector2(10, 10)
	hint_layer.add_child(hint)

	inv_layer = CanvasLayer.new()
	inv_layer.layer = 93
	inv_layer.visible = false
	add_child(inv_layer)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	panel.offset_left = -260
	panel.offset_top = -220
	panel.offset_right = -10
	panel.offset_bottom = 220
	inv_layer.add_child(panel)

	var title = Label.new()
	title.text = "Inventory (TAB to close)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(5, 5)
	title.size = Vector2(240, 20)
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	panel.add_child(title)

	# Equipment summary
	var equip_label = Label.new()
	equip_label.name = "EquipLabel"
	equip_label.position = Vector2(5, 30)
	equip_label.size = Vector2(240, 80)
	equip_label.add_theme_font_size_override("font_size", 11)
	equip_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
	panel.add_child(equip_label)

	var sep = HSeparator.new()
	sep.position = Vector2(10, 110)
	sep.size = Vector2(230, 4)
	panel.add_child(sep)

	var items_title = Label.new()
	items_title.text = "Carried Items"
	items_title.position = Vector2(5, 118)
	items_title.size = Vector2(240, 18)
	items_title.add_theme_font_size_override("font_size", 12)
	items_title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.6))
	panel.add_child(items_title)

	inv_container = VBoxContainer.new()
	inv_container.position = Vector2(5, 138)
	inv_container.size = Vector2(240, 280)
	panel.add_child(inv_container)

func _open_inventory():
	inventory_open = true
	_refresh_inventory_overlay()
	inv_layer.visible = true

func _close_inventory():
	inventory_open = false
	inv_layer.visible = false

func _refresh_inventory_overlay():
	# Equipment summary
	var equip_text = ""
	var slot_names = {
		Items.EquipSlot.HELMET: "Helmet",
		Items.EquipSlot.SUIT: "Suit",
		Items.EquipSlot.BACKPACK: "Backpack",
		Items.EquipSlot.BOOTS: "Boots",
		Items.EquipSlot.TOOL: "Tool",
	}
	for slot in slot_names:
		var name = slot_names[slot]
		if Inventory.player_equipment.has(slot):
			var inst = Inventory.player_equipment[slot]
			var def = Items.get_item(inst.item_id)
			var dur_str = ""
			if inst.current_durability >= 0:
				dur_str = " [%d]" % inst.current_durability
			equip_text += "%s: %s%s\n" % [name, def.get("name", "?"), dur_str]
		else:
			equip_text += "%s: (none)\n" % name

	var panel = inv_layer.get_child(0)
	panel.get_node("EquipLabel").text = equip_text

	# Items list
	for child in inv_container.get_children():
		child.queue_free()

	var cap = Inventory.get_inventory_capacity()
	var cap_label = Label.new()
	cap_label.text = "%d / %d slots" % [Inventory.player_inventory.size(), cap]
	cap_label.add_theme_font_size_override("font_size", 10)
	cap_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	inv_container.add_child(cap_label)

	for inst in Inventory.player_inventory:
		var item_def = Items.get_item(inst.item_id)
		var rarity = item_def.get("rarity", Items.Rarity.COMMON)
		var color = Items.RARITY_COLORS.get(rarity, Color.WHITE)
		var lbl = Label.new()
		lbl.text = "%s x%d" % [item_def.get("name", inst.item_id), inst.quantity]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.add_theme_color_override("font_color", color)
		inv_container.add_child(lbl)

	if Inventory.player_inventory.size() == 0:
		var empty = Label.new()
		empty.text = "(empty)"
		empty.add_theme_font_size_override("font_size", 11)
		empty.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		inv_container.add_child(empty)

func _create_ship_prompt():
	ship_prompt_label = Label.new()
	ship_prompt_label.text = "[E] Safe Box  |  [Click] Launch"
	ship_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ship_prompt_label.visible = false
	ship_prompt_label.add_theme_font_size_override("font_size", 14)
	ship_prompt_label.add_theme_color_override("font_color", Color(1, 1, 0.6))
	# Position via CanvasLayer so it's screen-space
	var prompt_layer = CanvasLayer.new()
	prompt_layer.layer = 90
	add_child(prompt_layer)
	ship_prompt_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	ship_prompt_label.offset_top = -30
	ship_prompt_label.offset_bottom = 0
	ship_prompt_label.offset_left = -150
	ship_prompt_label.offset_right = 150
	prompt_layer.add_child(ship_prompt_label)

func _create_safe_box_ui():
	safe_box_layer = CanvasLayer.new()
	safe_box_layer.layer = 95
	safe_box_layer.visible = false
	add_child(safe_box_layer)

	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -280
	panel.offset_top = -200
	panel.offset_right = 280
	panel.offset_bottom = 200
	safe_box_layer.add_child(panel)

	var title = Label.new()
	title.text = "Ship Safe Box  (Press E to close)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 10
	title.offset_bottom = 30
	title.add_theme_font_size_override("font_size", 16)
	panel.add_child(title)

	# Left side: inventory
	var inv_label = Label.new()
	inv_label.text = "Your Inventory"
	inv_label.position = Vector2(10, 35)
	inv_label.add_theme_font_size_override("font_size", 13)
	inv_label.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	panel.add_child(inv_label)

	sb_inv_container = VBoxContainer.new()
	sb_inv_container.position = Vector2(10, 55)
	sb_inv_container.size = Vector2(260, 320)
	panel.add_child(sb_inv_container)

	# Right side: safe box
	var sb_label = Label.new()
	sb_label.text = "Safe Box (3 slots - survives death)"
	sb_label.position = Vector2(290, 35)
	sb_label.add_theme_font_size_override("font_size", 13)
	sb_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	panel.add_child(sb_label)

	sb_box_container = VBoxContainer.new()
	sb_box_container.position = Vector2(290, 55)
	sb_box_container.size = Vector2(260, 320)
	panel.add_child(sb_box_container)

func _open_safe_box():
	safe_box_open = true
	$CharacterBody2D.set_physics_process(false)
	_refresh_safe_box_ui()
	safe_box_layer.visible = true

func _close_safe_box():
	safe_box_open = false
	$CharacterBody2D.set_physics_process(true)
	safe_box_layer.visible = false

func _refresh_safe_box_ui():
	# Clear old buttons
	for child in sb_inv_container.get_children():
		child.queue_free()
	for child in sb_box_container.get_children():
		child.queue_free()

	# Inventory items with "Move >" buttons
	for i in range(Inventory.player_inventory.size()):
		var inst = Inventory.player_inventory[i]
		var item_def = Items.get_item(inst.item_id)
		var btn = Button.new()
		btn.text = "%s x%d  [> Safe Box]" % [item_def.get("name", inst.item_id), inst.quantity]
		btn.add_theme_font_size_override("font_size", 11)
		var idx = i
		btn.pressed.connect(func(): _on_move_to_safebox_pressed(idx))
		sb_inv_container.add_child(btn)

	if Inventory.player_inventory.size() == 0:
		var lbl = Label.new()
		lbl.text = "(empty)"
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		sb_inv_container.add_child(lbl)

	# Safe box items with "< Move" buttons
	for i in range(Inventory.ship_safe_box.size()):
		var inst = Inventory.ship_safe_box[i]
		var item_def = Items.get_item(inst.item_id)
		var btn = Button.new()
		btn.text = "%s x%d  [< Inventory]" % [item_def.get("name", inst.item_id), inst.quantity]
		btn.add_theme_font_size_override("font_size", 11)
		var idx = i
		btn.pressed.connect(func(): _on_move_to_inventory_pressed(idx))
		sb_box_container.add_child(btn)

	if Inventory.ship_safe_box.size() == 0:
		var lbl = Label.new()
		lbl.text = "(empty)"
		lbl.add_theme_font_size_override("font_size", 11)
		lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		sb_box_container.add_child(lbl)

	# Capacity indicator
	var cap_lbl = Label.new()
	cap_lbl.text = "%d/3 slots used" % Inventory.ship_safe_box.size()
	cap_lbl.add_theme_font_size_override("font_size", 10)
	cap_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	sb_box_container.add_child(cap_lbl)

func _on_move_to_safebox_pressed(index: int):
	if index >= Inventory.player_inventory.size():
		return
	if Inventory.ship_safe_box.size() >= 3:
		return
	var inst = Inventory.player_inventory[index]
	Inventory.transfer_item(Inventory.player_inventory, Inventory.ship_safe_box, inst.instance_id, 3)
	_refresh_safe_box_ui()

func _on_move_to_inventory_pressed(index: int):
	if index >= Inventory.ship_safe_box.size():
		return
	var inst = Inventory.ship_safe_box[index]
	var cap = Inventory.get_inventory_capacity()
	Inventory.transfer_item(Inventory.ship_safe_box, Inventory.player_inventory, inst.instance_id, cap)
	_refresh_safe_box_ui()

func _on_death_markers_loaded(phase):
	if phase != 2:
		return
	for marker in MP.deathMarkers[2]:
		var dm = deathMarkerScene.instantiate()
		dm.global_position = Vector2(marker.positionX, marker.positionY)
		dm.init(marker)
		$World.add_child(dm)
