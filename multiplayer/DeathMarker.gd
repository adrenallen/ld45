extends Node2D

var markerData = {}
var showingInfo = false

func _ready():
	$InfoPanel.visible = false

func init(data):
	markerData = data
	# Set tooltip-style label
	$NameLabel.text = str(data.get("playerName", "Unknown"))

func _on_Area2D_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		toggleInfo()

func _on_Area2D_mouse_entered():
	$Cross.modulate = Color(1, 1, 0.5)
	$NameLabel.visible = true

func _on_Area2D_mouse_exited():
	$Cross.modulate = Color(1, 0.3, 0.3)
	if !showingInfo:
		$NameLabel.visible = false

func toggleInfo():
	showingInfo = !showingInfo
	$InfoPanel.visible = showingInfo
	if showingInfo:
		var info = ""
		info += "Player: " + str(markerData.get("playerName", "Unknown")) + "\n"
		info += "Distance: " + str(round(markerData.get("distance", 0))) + " miles\n"

		var cause = markerData.get("deathCause", "Unknown")
		info += "Killed by: " + cause + "\n"

		if markerData.get("planetBiome", "") != "":
			info += "Biome: " + str(markerData.get("planetBiome", "")) + "\n"

		info += "Fuel: " + str(round(markerData.get("fuel", 0))) + "\n"
		info += "Oxygen: " + str(round(markerData.get("oxygen", 0))) + "\n"
		info += "Ship HP: " + str(markerData.get("shipHealth", 0)) + "/" + str(Game.MAX_SHIP_HEALTH) + "\n"
		info += "Planets Visited: " + str(markerData.get("planetsLandedOn", 0))

		$InfoPanel/InfoLabel.text = info
