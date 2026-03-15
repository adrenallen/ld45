extends Control

var current_tab = 0

func _ready():
	_show_tab(0)
	_update_stats()

	# Show extraction summary if just extracted
	if Game.extracted:
		$ExtractionPopup.visible = true
		Game.extracted = false

func _show_tab(tab_index: int):
	current_tab = tab_index
	$StashTab.visible = (tab_index == 0)
	$LoadoutTab.visible = (tab_index == 1)
	$CraftingTab.visible = (tab_index == 2)
	$LaunchTab.visible = (tab_index == 3)

	# Update tab button styles
	for i in range(4):
		var btn = $TabBar.get_child(i)
		btn.disabled = (i == tab_index)

	# Refresh the active tab
	match tab_index:
		0: $StashTab.refresh()
		1: $LoadoutTab.refresh()
		2: $CraftingTab.refresh()
		3: $LaunchTab.refresh()

func _update_stats():
	$StatsLabel.text = "Runs: %d | Extractions: %d | Deaths: %d | Crafted: %d" % [
		Game.runs_completed, Game.successful_extractions, Game.runs_died, Game.items_crafted
	]

func _on_stash_button_pressed():
	_show_tab(0)

func _on_loadout_button_pressed():
	_show_tab(1)

func _on_crafting_button_pressed():
	_show_tab(2)

func _on_launch_button_pressed():
	_show_tab(3)

func _on_menu_button_pressed():
	get_tree().change_scene_to_file("res://Menu.tscn")

func _on_extraction_popup_close():
	$ExtractionPopup.visible = false
