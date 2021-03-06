extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const MAX_FUEL_SCALE = 3.96

const SHIP_ENTER_DISTANCE = 150

var minimumLaunchFuel = 30 # TODO - change by gravity?

var fuelScene = load("res://explore/Fuel.tscn")
var repairScene = load("res://explore/Repair.tscn")
var airPocketScene = load("res://explore/AirPocket.tscn")

var openTileIdx = 0
var closedTileIdx = 1

var mouseOnShip = false


# Called when the node enters the scene tree for the first time.
func _ready():
	setTileIndex()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	placeWorld()
	Game.oxygen = 100
	Game.planetsLandedOn += 1
	Game.playerInAirPocket = false
	
func _physics_process(delta):
	if $KinematicBody2D.global_position.distance_to($"World/ship-top".global_position) < SHIP_ENTER_DISTANCE and mouseOnShip:
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		$"World/ship-top".frame =1
	else:
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
		$"World/ship-top".frame =0		
	
func _process(delta):
	
	# This is dumb :(
	$UI.global_position = $KinematicBody2D/Camera2D.get_camera_position()
	$UI.global_position.x -= get_viewport_rect().size.x/2
	$UI.global_position.y -= get_viewport_rect().size.y/2
	
	
	$"UI/fuel-icon/fuel-body".scale.x = Game.fuel / 100.0 * MAX_FUEL_SCALE
	$"UI/o2/o2-body".scale.x = Game.oxygen / 100 * MAX_FUEL_SCALE
	
	if $"UI/fuel-icon/fuel-body".scale.x > MAX_FUEL_SCALE:
		$"UI/fuel-icon/fuel-body".scale.x = MAX_FUEL_SCALE
	if $"UI/o2/o2-body".scale.x > MAX_FUEL_SCALE:
		$"UI/o2/o2-body".scale.x = MAX_FUEL_SCALE
	
	if Game.playerInAirPocket:
		if Game.oxygen < 100:
			Game.oxygen += delta*Game.AIR_POCKET_OXYGEN_RATE
	else:
		Game.oxygen -= delta*Game.currentPlanet.atmosphereToxicity
		
	
	if Game.oxygen <= 0:
		Game.oxygen = 0
		$KinematicBody2D.die()

func setTileIndex():
	if Game.currentPlanet.biome == Game.PlanetBiome.Forest:
		openTileIdx = 2
		closedTileIdx = 3
	elif Game.currentPlanet.biome == Game.PlanetBiome.Gas:
		openTileIdx = 4
		closedTileIdx = 5
	elif Game.currentPlanet.biome == Game.PlanetBiome.Water:
		openTileIdx = 6
		closedTileIdx = 7
	elif Game.currentPlanet.biome == Game.PlanetBiome.Fungal:
		openTileIdx = 8
		closedTileIdx = 9
	elif Game.currentPlanet.biome == Game.PlanetBiome.Lava:
		openTileIdx = 10
		closedTileIdx = 11

func nextPhase():
	Game.setPhase(3)

func _on_Transition_TransitionIn():
	$KinematicBody2D/Camera2D.current = true

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
#			print(x, y, map[y][x])
			var tile = closedTileIdx
			if map[y][x] == 0:
				tile = openTileIdx
			$TileMap.set_cell(x, y, tile)
			if map[y][x] == 0:
				openSpots.append(Vector2(x,y))
				playerStart.x = x
				playerStart.y = y
				
	for i in range(numberOfFuel):
		var randomLoc = randi()%openSpots.size()
		var randomSpot = openSpots[randomLoc]
		var loc = $TileMap.map_to_world(randomSpot)
		var fuel = fuelScene.instance()
		fuel.position = loc
		fuel.position.x += 32
		fuel.position.y += 32
		$World.add_child(fuel)
		
		openSpots.erase(randomSpot)
		
	for i in range(numberOfRepair):
		var randomLoc = randi()%openSpots.size()
		var randomSpot = openSpots[randomLoc]
		var loc = $TileMap.map_to_world(randomSpot)
		var rep = repairScene.instance()
		rep.position = loc
		rep.position.x += 32
		rep.position.y += 32
		$World.add_child(rep)
		
		openSpots.erase(randomSpot)
		
	for i in range(numberOfAirPockets):
		var randomLoc = randi()%openSpots.size()
		var randomSpot = openSpots[randomLoc]
		var loc = $TileMap.map_to_world(randomSpot)
		var ap = airPocketScene.instance()
		ap.position = loc
		ap.position.x += 32
		ap.position.y += 32
		$World.add_child(ap)
		
		openSpots.erase(randomSpot)
		
	
	# position player start
	$KinematicBody2D.global_position = $TileMap.map_to_world(playerStart)
	$KinematicBody2D.global_position.x += 32
	$KinematicBody2D.global_position.y += 32
	
	# make sure we dont open an out of world path
	for x in range(playerStart.x-9, playerStart.x+5):
		for y in range(playerStart.y-7, playerStart.y+7):
			if $TileMap.get_cell(x,y) < 0:
				$TileMap.set_cell(x,y,closedTileIdx)
	
	# make space for crash zone
	for x in range(playerStart.x-6, playerStart.x+2):
		for y in range(playerStart.y-4, playerStart.y+4):
			$TileMap.set_cell(x,y,openTileIdx)
	
			
	$"World/ship-top".global_position = $KinematicBody2D.global_position
	$"World/ship-top".global_position.x -= 128

func generateMapOpen(dimensions):
	var array = []
	for i in range(0, dimensions):
		array.append([])
		for j in range(0, dimensions):
			array[i].append(1)
	return array

func generateMap():
	var dimensions = int(floor(Game.currentPlanet.radius*4))
	var maxTunnels = int(floor(rand_range(dimensions*.75, dimensions*4)))
	var maxLength = int(floor(rand_range(2,20)))
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
	if $KinematicBody2D.dying:
		return
	if $KinematicBody2D.global_position.distance_to($"World/ship-top".global_position) < SHIP_ENTER_DISTANCE:
		if event is InputEventMouseButton:
			if Game.fuel >= minimumLaunchFuel:
				nextPhase()
			if Game.cheaterMode:
				nextPhase()

func _on_Area2D_mouse_entered():
	mouseOnShip = true

func _on_Area2D_mouse_exited():
	mouseOnShip = false
