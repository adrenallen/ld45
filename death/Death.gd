extends Node2D

var planetScene = load("res://launch/Planet1.tscn")
var sunScene = load("res://launch/Sun.tscn")
var alienScene = load("res://launch/AlienShip.tscn")

const RECORD_URL = Game.BASE_URL + "/record"

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Auto-submit death marker in weekly mode
	if MP.weeklyMode:
		MP.submitDeath()
		$WeeklyLabel.visible = true
		$WeeklyLabel.text = "Weekly Challenge: " + MP.weekId
	else:
		$WeeklyLabel.visible = false

	if Game.deathBy.cause == Game.DeathBy.Sun:
		var newSun = sunScene.instantiate()
		$Exhibit.add_child(newSun)
		$DetailsLabel.text = "Planets in orbit: " + str(Game.deathBy.planetsOrbiting)
	elif Game.deathBy.cause == Game.DeathBy.Planet:
		var newPlanet = planetScene.instantiate()
		newPlanet.gravity = 0
		newPlanet.landable = false
		newPlanet.biome = Game.deathBy.biome
		newPlanet.planetRadius = Game.deathBy.radius
		newPlanet.atmosphereToxicity = Game.deathBy.atmosphereToxicity
		$Exhibit.add_child(newPlanet)
		$DetailsLabel.text = "- Planet Info -\n\nCircumference: " + str(floor(Game.deathBy.radius * 1000)) + " miles"
		$DetailsLabel.text += "\n\nAtmosphere Toxicity: " + str(Game.deathBy.atmosphereToxicity)
		$DetailsLabel.text += "\n\nGravity Rating: " + str(round(Game.deathBy.gravity))
	elif Game.deathBy.cause == Game.DeathBy.AlienShip:
		var alien = alienScene.instantiate()
		alien.stunned = true
		$Exhibit.add_child(alien)
	elif Game.deathBy.cause == Game.DeathBy.Suffocation:
		$DetailsLabel.text = "- Suffocated -\n\nAtmosphere Toxicity: " + str(Game.currentPlanet.atmosphereToxicity)

	$DistanceLabel.text = str(Game.getMilesTraveled())

	# Show loss summary
	_show_loss_summary()

	if Game.cheaterMode:
		$Button.visible = false
		$PlanetNameInput.visible = false

func _show_loss_summary():
	var summary = "\n\n-- Items Lost --\nAll carried inventory and ship cargo lost."
	summary += "\nEquipment durability penalty: -%d" % Inventory.DEATH_DURABILITY_PENALTY
	if Inventory.ship_safe_box.size() > 0:
		summary += "\n\nSafe box items preserved: %d" % Inventory.ship_safe_box.size()
	$DetailsLabel.text += summary

func _on_PlanetNameInput_text_changed():
	if $PlanetNameInput.text.length() > 32:
		$PlanetNameInput.text = $PlanetNameInput.text.substr(0,32)


func _on_Button_button_up():
	if Game.cheaterMode:
		return
	if $PlanetNameInput.text.length() > 1:
		var request = JSON.stringify({deathBy = Game.deathBy, distance = Game.getMilesTraveled(), name = $PlanetNameInput.text, confirmer = Game.secret(Game.getMilesTraveled())})
		var headers = PackedStringArray()
		headers.append("Content-Type: application/json")
		$HTTPRequest.request(RECORD_URL, headers, HTTPClient.METHOD_POST, request)


func _on_LeaderboardButton_button_up():
	if MP.weeklyMode:
		get_tree().change_scene_to_file("res://multiplayer/WeeklyLeaderboard.tscn")
	else:
		get_tree().change_scene_to_file("res://leaderboard/Leaderboard.tscn")

func _on_BaseButton_pressed():
	get_tree().change_scene_to_file("res://base/Base.tscn")

func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	_on_LeaderboardButton_button_up()
