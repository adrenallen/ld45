extends Node2D

const MAX_FUEL_SCALE = 3.96
const WORMHOLE_BASE_CHANCE = 0.25

var planetScene = load("res://launch/Planet1.tscn")
var sunScene = load("res://launch/Sun.tscn")
var alienFighterScene = load("res://launch/AlienShip.tscn")
var spaceLootScene = load("res://launch/SpaceLoot.tscn")
var spaceWormholeScene = load("res://launch/SpaceWormhole.tscn")
var deathMarkerScene = load("res://multiplayer/DeathMarker.tscn")

var playBoxCoordinates = {
	minX = 0,
	minY = 0,
	maxX = 0,
	maxY = 0
}

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$LaunchPlanet.gravity = 0
	$LaunchPlanet.landable = false

	$LaunchPlanet.biome = Game.currentPlanet.biome
	$LaunchPlanet.planetRadius = Game.currentPlanet.radius
	$LaunchPlanet.atmosphereToxicity = Game.currentPlanet.atmosphereToxicity

	$LaunchPlanet._ready()

	$Ship.global_position = $LaunchPlanet/planet1.global_position
	$Ship.global_position.y -= $LaunchPlanet.planetRadius

	generateSpace($Ship.global_position)

	if MP.weeklyMode:
		MP.death_markers_loaded.connect(_on_death_markers_loaded)
		MP.fetchDeathMarkers(3)

func calculatePlayBox():
	playBoxCoordinates = {
		minX = 0,
		minY = 0,
		maxX = 0,
		maxY = 0
	}
	for p in $Planets.get_children():
		if p.global_position.x < playBoxCoordinates.minX:
			playBoxCoordinates.minX = p.global_position.x
		elif p.global_position.x > playBoxCoordinates.maxX:
			playBoxCoordinates.maxX = p.global_position.x

		if p.global_position.y < playBoxCoordinates.minY:
			playBoxCoordinates.minY = p.global_position.y
		elif p.global_position.y > playBoxCoordinates.maxY:
			playBoxCoordinates.maxY = p.global_position.y

func generateSpace(centralPosition):
	var ringsToGenerate = 1
	var ringDistance = 1000
	var maxGenerationDistance = ringDistance*ringsToGenerate
	var distance = ringDistance
	while distance <= maxGenerationDistance:
		var angleDeg = randi()%360
		var galaxyCount = 4 + floor(2 * distance / ringDistance)
		for i in range(galaxyCount):
			angleDeg += 360/galaxyCount*i
			var angleRad = deg_to_rad(angleDeg)
			var pos = centralPosition + (Vector2(cos(angleRad), sin(angleRad)) * distance)
			generateGalaxy(pos.x, pos.y, randi()%10+1)
		distance += ringDistance

	# Try spawning a wormhole in this generation
	_try_spawn_wormhole(centralPosition)

	calculatePlayBox()

func generateGalaxy(x,y,planets = 10, maxPlanetDistance = 500):
	var sun = sunScene.instantiate()
	sun.global_position = Vector2(x,y)
	sun.planetsOrbiting = planets
	$Planets.add_child(sun)

	if get_tree().get_nodes_in_group("alien-fighter").size() < Game.getMaxAlienFighters():
		var alien = alienFighterScene.instantiate()
		alien.global_position.x = x
		alien.global_position.y = y
		$AlienShips.add_child(alien)

	var lastPlanetDistance = 150
	for i in range(planets):
		var randomDegree = randi()%360
		var randomRad = deg_to_rad(randomDegree)
		var planetVector = Vector2(cos(randomRad), sin(randomRad))
		var newPlanet = newPlanetNode(x,y)
		var planetDistance = lastPlanetDistance + randf_range(2*newPlanet.planetRadius, 5*newPlanet.planetRadius)
		if planetDistance > maxPlanetDistance:
			planetDistance = maxPlanetDistance

		newPlanet.global_position += planetVector.normalized()*planetDistance
		$Planets.add_child(newPlanet)
		lastPlanetDistance = planetDistance

	# Spawn 1-3 space loot per galaxy
	_spawn_space_loot(x, y, maxPlanetDistance)

func _spawn_space_loot(galaxy_x: float, galaxy_y: float, max_dist: float):
	var num_loot = randi() % 3 + 1
	var dist = Game.getMilesTraveled()

	# Get items suitable for space loot (universal + ship parts)
	var available = Items.get_items_by_type(Items.ItemType.RESOURCE)
	available.append_array(Items.get_items_by_type(Items.ItemType.SHIP_PART))
	# Filter by distance
	available = available.filter(func(item): return item.get("min_distance", 0) <= dist)

	if available.size() == 0:
		return

	for i in range(num_loot):
		var angle = randf() * TAU
		var distance = randf_range(100, max_dist * 0.8)
		var pos = Vector2(galaxy_x + cos(angle) * distance, galaxy_y + sin(angle) * distance)

		var item = available[randi() % available.size()]
		var loot = spaceLootScene.instantiate()
		loot.global_position = pos
		loot.init(item.id, 1)
		$Planets.add_child(loot)

func _try_spawn_wormhole(centralPosition: Vector2):
	# Chance increases slightly with distance traveled
	var chance = WORMHOLE_BASE_CHANCE + Game.getMilesTraveled() / 1000000.0
	chance = min(chance, 0.6)  # Cap at 60%

	if randf() > chance:
		return

	# Place in a random direction from center
	var angle = randf() * TAU
	var dist = randf_range(400, 800)
	var pos = centralPosition + Vector2(cos(angle), sin(angle)) * dist

	var wormhole = spaceWormholeScene.instantiate()
	wormhole.global_position = pos
	$Planets.add_child(wormhole)

func newPlanetNode(x=0,y=0):
	var planetInfo = Game.generatePlanet()
	var newPlanet = planetScene.instantiate()
	newPlanet.gravity = planetInfo.gravity
	newPlanet.planetRadius = planetInfo.radius
	newPlanet.biome = planetInfo.biome
	newPlanet.atmosphereToxicity = planetInfo.atmosphereToxicity
	newPlanet.global_position.x = x
	newPlanet.global_position.y = y
	return newPlanet

func _process(delta):
	$UI.global_position = $Ship/Camera2D.get_screen_center_position()
	$UI.global_position.x -= get_viewport_rect().size.x/2
	$UI.global_position.y -= get_viewport_rect().size.y/2

	$"UI/fuel-icon/fuel-body".scale.x = Game.fuel / float(Game.maxFuel) * MAX_FUEL_SCALE
	if $"UI/fuel-icon/fuel-body".scale.x > MAX_FUEL_SCALE:
		$"UI/fuel-icon/fuel-body".scale.x = MAX_FUEL_SCALE

	Game.currentDistance = $Ship.global_position.length()

	if MP.weeklyMode:
		MP.updatePosition(3, $Ship.global_position)

	checkShipInPlaybox()


func checkShipInPlaybox():
	var oobMargin = 700
	var shipPos = $Ship.global_position
	if (shipPos.x < playBoxCoordinates.minX-oobMargin or
		shipPos.x > playBoxCoordinates.maxX+oobMargin or
		shipPos.y < playBoxCoordinates.minY-oobMargin or
		shipPos.y > playBoxCoordinates.maxY+oobMargin):
			newGeneration()

func newGeneration():
	destroyPlanets()
	generateSpace($Ship.global_position)

func destroyPlanets():
	for p in $Planets.get_children():
		p.queue_free()

func nextPhase():
	Game.setPhase(1)


func _on_death_markers_loaded(phase):
	if phase != 3:
		return
	for marker in MP.deathMarkers[3]:
		var dm = deathMarkerScene.instantiate()
		dm.global_position = Vector2(marker.positionX, marker.positionY)
		dm.init(marker)
		$Planets.add_child(dm)

func _on_TransitionIn_TransitionIn():
	$Ship/Camera2D.current = true
