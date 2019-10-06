extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

var musicVol = 100
var sfxVol = 100

var musicMute = false
var sfxMute = false

# Called when the node enters the scene tree for the first time.
func _ready():
	sfxVol = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Sound Effects"))
	musicVol = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Background"))
	
	sfxMute = AudioServer.is_bus_mute(AudioServer.get_bus_index("Sound Effects"))
	musicMute = AudioServer.is_bus_mute(AudioServer.get_bus_index("Background"))
		
	$Options/Control2/SFXMute.pressed = sfxMute
	$Options/Control/MusicMute.pressed = musicMute
	
	$Options/Control2/SFXVolume.text = str(sfxVol)
	$Options/Control/MusicVolume.text = str(musicVol)


func _on_StartButton_button_up():
	Game.refresh()
	Game.tutorialsCompleted = [1,2,3]
	Game.setPhase(1)

func _on_StartTutButton_pressed():
	Game.refresh()
	Game.tutorialsCompleted = []
	Game.setPhase(1)


func _on_LeaderboardButton_pressed():
	get_tree().change_scene("res://leaderboard/Leaderboard.tscn")


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
