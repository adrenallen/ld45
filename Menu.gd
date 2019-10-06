extends Control

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


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
