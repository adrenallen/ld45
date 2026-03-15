extends Control

var musicVol = 100
var sfxVol = 100

var musicMute = false
var sfxMute = false

func _ready():
	sfxVol = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sound Effects"))
	musicVol = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Background"))

	sfxMute = AudioServer.is_bus_mute(AudioServer.get_bus_index("Sound Effects"))
	musicMute = AudioServer.is_bus_mute(AudioServer.get_bus_index("Background"))

	$Options/Control2/SFXMute.button_pressed = sfxMute
	$Options/Control/MusicMute.button_pressed = musicMute

	$Options/Control2/SFXVolume.text = str(sfxVol)
	$Options/Control/MusicVolume.text = str(musicVol)

	$Options/Control3/QuickTransitionsButton.button_pressed = Game.quickTransitions
	$Options/Control4/CheaterMode.button_pressed = Game.cheaterMode

	# Show/hide continue button based on save state
	if $ContinueButton:
		$ContinueButton.visible = SaveManager.has_save

func _on_NewGameButton_pressed():
	SaveManager.new_game()
	get_tree().change_scene_to_file("res://base/Base.tscn")

func _on_ContinueButton_pressed():
	if SaveManager.load_game():
		get_tree().change_scene_to_file("res://base/Base.tscn")

func _on_StartButton_button_up():
	MP.weeklyMode = false
	Game.refresh()
	Game.tutorialsCompleted = [1,2,3]
	Game.setPhase(1)

func _on_StartTutButton_pressed():
	MP.weeklyMode = false
	Game.refresh()
	Game.tutorialsCompleted = []
	Game.setPhase(1)

func _on_WeeklyChallengeButton_pressed():
	var name = $WeeklyOptions/PlayerNameInput.text.strip_edges()
	if name.length() < 1:
		$WeeklyOptions/WeeklyStatusLabel.text = "Enter a player name first!"
		return
	MP.playerName = name
	$WeeklyOptions/WeeklyStatusLabel.text = "Loading weekly seed..."
	MP.weekly_seed_loaded.connect(_on_weekly_seed_ready, CONNECT_ONE_SHOT)
	MP.fetchWeeklySeed()

func _on_weekly_seed_ready():
	$WeeklyOptions/WeeklyStatusLabel.text = "Week: " + MP.weekId + " - Starting..."
	MP.weeklyMode = true
	Game.tutorialsCompleted = [1,2,3]
	MP.startWeeklyRun()
	Game.setPhase(1)


func _on_LeaderboardButton_pressed():
	get_tree().change_scene_to_file("res://leaderboard/Leaderboard.tscn")


func _on_QuitButton_pressed():
	get_tree().quit()


func _on_SFXVolume_text_changed():
	sfxVol = float($Options/Control2/SFXVolume.text)
	if !sfxMute:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound Effects"), sfxVol)
	else:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sound Effects"), 0)

func _on_MusicVolume_text_changed():
	musicVol = float($Options/Control/MusicVolume.text)
	print(musicMute)
	if !musicMute:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Background"), musicVol)
	else:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Background"), 0)

func _on_MusicMute_toggled(button_pressed):
	musicMute = button_pressed
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Background"), musicMute)


func _on_SFXMute_toggled(button_pressed):
	sfxMute = button_pressed
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Sound Effects"), sfxMute)


func _on_QuickTransitionsButton_toggled(button_pressed):
	Game.quickTransitions = button_pressed


func _on_CheaterMode_toggled(button_pressed):
	Game.cheaterMode = button_pressed
