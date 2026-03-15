extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const MAX_FUEL_SCALE = 3.96
var planetScene = load("res://launch/Planet1.tscn")
var sunScene = load("res://launch/Sun.tscn")
var alienFighterScene = load("res://launch/AlienShip.tscn")
var deathMarkerScene = load("res://multiplayer/DeathMarker.tscn")

var playBoxCoordinates = {
	minX = 0,
	minY = 0,
	maxX = 0,
	maxY = 0
}

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$LaunchPlanet.gravity = 0 # TODO - can we do some magic to turn this on after ship leaves?
	$LaunchPlanet.landable = false

	$LaunchPlanet.biome = Game.currentPlanet.biome
	$LaunchPlanet.planetRadius = Game.currentPlanet.radius
	$LaunchPlanet.atmosphereToxicity = Game.currentPlanet.atmosphereToxicity

	$LaunchPlanet._ready() # refresh now that we set the params

	$Ship.global_position = $LaunchPlanet/planet1.global_position
	$Ship.global_position.y -= $LaunchPlanet.planetRadius

	generateSpace($Ship.global_position)

	# Load death markers for weekly mode
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

	calculatePlayBox()

# Generate a galaxy with a center at point x,y
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
		print("Spawned alien")


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

	$"UI/fuel-icon/fuel-body".scale.x = Game.fuel / 100.0 * MAX_FUEL_SCALE
	if $"UI/fuel-icon/fuel-body".scale.x > MAX_FUEL_SCALE:
		$"UI/fuel-icon/fuel-body".scale.x = MAX_FUEL_SCALE

	Game.currentDistance = $Ship.global_position.length()

	# Track position for death marker submission
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
