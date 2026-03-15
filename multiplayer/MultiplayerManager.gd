extends Node

# Multiplayer server configuration
const MULTIPLAYER_URL = "https://ld45.garrettallen.dev/mp"
#const MULTIPLAYER_URL = "http://localhost:3001"

var weeklyMode = false
var weeklySeed = 0
var weekId = ""
var playerName = ""

# Cached death markers for the current week, keyed by phase
var deathMarkers = {1: [], 2: [], 3: []}
var deathMarkersLoaded = false

# Position tracking for death submission
var lastPhase = 1
var lastPosition = Vector2.ZERO

signal weekly_seed_loaded
signal death_markers_loaded(phase)
signal death_submitted

func fetchWeeklySeed():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_seed_response.bind(http))
	http.request(MULTIPLAYER_URL + "/api/weekly-seed")

func _on_seed_response(result, response_code, headers, body, http):
	http.queue_free()
	if response_code == 200:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var data = json.get_data()
		weeklySeed = int(data.seed)
		weekId = data.weekId
		print("Weekly seed loaded: ", weeklySeed, " for week: ", weekId)
		weekly_seed_loaded.emit()
	else:
		print("Failed to fetch weekly seed: ", response_code)

func submitDeath():
	if !weeklyMode or playerName.length() < 1:
		return

	var deathCause = ""
	if Game.deathBy.cause == Game.DeathBy.Sun:
		deathCause = "Sun"
	elif Game.deathBy.cause == Game.DeathBy.Planet:
		deathCause = "Planet"
	elif Game.deathBy.cause == Game.DeathBy.AlienShip:
		deathCause = "AlienShip"

	var biome = ""
	if Game.deathBy.has("biome"):
		biome = Game.PlanetBiome.keys()[Game.deathBy.biome]

	var payload = {
		weekId = weekId,
		playerName = playerName,
		phase = lastPhase,
		positionX = lastPosition.x,
		positionY = lastPosition.y,
		distance = Game.getMilesTraveled(),
		fuel = Game.fuel,
		oxygen = Game.oxygen,
		shipHealth = Game.shipHealth,
		planetsLandedOn = Game.planetsLandedOn,
		deathCause = deathCause,
		planetBiome = biome,
		planetRadius = Game.currentPlanet.radius,
		planetGravity = Game.currentPlanet.gravity,
		planetToxicity = Game.currentPlanet.atmosphereToxicity
	}

	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_death_submit_response.bind(http))
	var jsonStr = JSON.stringify(payload)
	var hdrs = PackedStringArray()
	hdrs.append("Content-Type: application/json")
	http.request(MULTIPLAYER_URL + "/api/deaths", hdrs, HTTPClient.METHOD_POST, jsonStr)

func _on_death_submit_response(result, response_code, headers, body, http):
	http.queue_free()
	if response_code == 200:
		print("Death submitted successfully")
		death_submitted.emit()
	else:
		print("Failed to submit death: ", response_code)

func fetchDeathMarkers(phase):
	if !weeklyMode or weekId == "":
		return

	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_deaths_response.bind(http, phase))
	var url = MULTIPLAYER_URL + "/api/deaths/" + weekId + "?phase=" + str(phase)
	http.request(url)

func _on_deaths_response(result, response_code, headers, body, http, phase):
	http.queue_free()
	if response_code == 200:
		var json = JSON.new()
		json.parse(body.get_string_from_utf8())
		var data = json.get_data()
		deathMarkers[phase] = data
		print("Loaded ", data.size(), " death markers for phase ", phase)
		death_markers_loaded.emit(phase)
	else:
		print("Failed to fetch death markers: ", response_code)

func startWeeklyRun():
	weeklyMode = true
	Game.refresh()

func updatePosition(phase, pos):
	lastPhase = phase
	lastPosition = pos
