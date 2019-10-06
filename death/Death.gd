extends Node2D

var planetScene = load("res://launch/Planet1.tscn")
var sunScene = load("res://launch/Sun.tscn")
var alienScene = load("res://launch/AlienShip.tscn")

const RECORD_URL = Game.BASE_URL + "/record"

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if Game.deathBy.cause == Game.DeathBy.Sun:
		var newSun = sunScene.instance()
		$Exhibit.add_child(newSun)
		$DetailsLabel.text = "Planets in orbit: " + str(Game.deathBy.planetsOrbiting)
	elif Game.deathBy.cause == Game.DeathBy.Planet:
		var newPlanet = planetScene.instance()
		newPlanet.gravity = 0 # TODO - can we do some magic to turn this on after ship leaves?
		newPlanet.landable = false
		newPlanet.biome = Game.deathBy.biome
		newPlanet.planetRadius = Game.deathBy.radius
		newPlanet.atmosphereToxicity = Game.deathBy.atmosphereToxicity
		$Exhibit.add_child(newPlanet)
		$DetailsLabel.text = "- Planet Info -\n\nCircumference: " + str(floor(Game.deathBy.radius * 1000)) + " miles"
		$DetailsLabel.text += "\n\nAtmosphere Toxicity: " + str(Game.deathBy.atmosphereToxicity)
		$DetailsLabel.text += "\n\nGravity Rating: " + str(round(Game.deathBy.gravity))
	elif Game.deathBy.cause == Game.DeathBy.AlienShip:
		var alien = alienScene.instance()
		alien.stunned = true
		$Exhibit.add_child(alien)
		
	$DistanceLabel.text = str(Game.getMilesTraveled())
	
	if Game.cheaterMode:
		$Button.visible = false
		$PlanetNameInput.visible = false
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_PlanetNameInput_text_changed():
	if $PlanetNameInput.text.length() > 32:
		$PlanetNameInput.text = $PlanetNameInput.text.substr(0,32)


func _on_Button_button_up():
	if Game.cheaterMode:
		return #Extra safety
	if $PlanetNameInput.text.length() > 1:
		var request = JSON.print({deathBy = Game.deathBy, distance = Game.getMilesTraveled(), name = $PlanetNameInput.text, confirmer = Game.secret(Game.getMilesTraveled())})
		var headers = PoolStringArray()
		headers.append("Content-Type: application/json")
		$HTTPRequest.request(RECORD_URL, headers, false, HTTPClient.METHOD_POST, request)



func _on_LeaderboardButton_button_up():
	get_tree().change_scene("res://leaderboard/Leaderboard.tscn")


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	_on_LeaderboardButton_button_up()
