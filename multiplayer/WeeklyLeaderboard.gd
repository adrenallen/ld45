extends Node2D

func _ready():
	$WeekLabel.text = "Weekly Challenge: " + MP.weekId
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed.bind(http))
	http.request(MP.MULTIPLAYER_URL + "/api/weekly-leaderboard/" + MP.weekId)

func _on_request_completed(result, response_code, headers, body, http):
	http.queue_free()
	if response_code != 200:
		$StatusLabel.text = "Failed to load leaderboard"
		return

	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var data = json.get_data()

	if data.size() == 0:
		$StatusLabel.text = "No runs yet this week!"
		return

	$StatusLabel.text = ""
	var pos = 0
	for entry in data:
		var label = Label.new()
		var rank = pos + 1
		var cause = entry.get("deathCause", "Unknown")
		label.text = str(rank) + ". " + str(entry.playerName) + " - " + str(round(entry.distance)) + " miles (Killed by: " + cause + ")"
		label.position.y = 30 * pos
		label.add_theme_font_override("font", load("res://death/Aero.ttf"))
		label.add_theme_font_size_override("font_size", 16)
		label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
		$Top10.add_child(label)
		pos += 1

func _on_BackButton_pressed():
	get_tree().change_scene_to_file("res://Menu.tscn")
