extends Node

const SAVE_PATH = "user://savegame.dat"
const ENCRYPTION_KEY = "PlanetJumpers_v2_k3y!@#$%"
const SAVE_VERSION = 1

var has_save: bool = false

func _ready():
	has_save = FileAccess.file_exists(SAVE_PATH)

func save_game():
	var data = _build_save_data()
	var json_string = JSON.stringify(data)

	# Generate checksum for integrity
	var checksum = json_string.md5_text()
	var wrapper = {
		version = SAVE_VERSION,
		checksum = checksum,
		data = data
	}
	var wrapper_json = JSON.stringify(wrapper)

	var file = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.WRITE, ENCRYPTION_KEY)
	if file == null:
		push_error("SaveManager: Failed to open save file for writing: " + str(FileAccess.get_open_error()))
		return false

	file.store_string(wrapper_json)
	file.close()
	has_save = true
	print("SaveManager: Game saved successfully")
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		has_save = false
		return false

	var file = FileAccess.open_encrypted_with_pass(SAVE_PATH, FileAccess.READ, ENCRYPTION_KEY)
	if file == null:
		push_error("SaveManager: Failed to open save file for reading: " + str(FileAccess.get_open_error()))
		has_save = false
		return false

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		push_error("SaveManager: Failed to parse save data")
		has_save = false
		return false

	var wrapper = json.data
	if not wrapper is Dictionary:
		push_error("SaveManager: Invalid save format")
		has_save = false
		return false

	# Version check
	if wrapper.get("version", 0) != SAVE_VERSION:
		push_error("SaveManager: Incompatible save version")
		has_save = false
		return false

	# Integrity check
	var data = wrapper.get("data", {})
	var expected_checksum = wrapper.get("checksum", "")
	var actual_checksum = JSON.stringify(data).md5_text()
	if expected_checksum != actual_checksum:
		push_error("SaveManager: Save file integrity check failed")
		has_save = false
		return false

	_apply_save_data(data)
	has_save = true
	print("SaveManager: Game loaded successfully")
	return true

func new_game():
	Inventory.setup_starter_loadout()
	Crafting.reset_workbenches()
	save_game()

func delete_save():
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	has_save = false

func _build_save_data() -> Dictionary:
	return {
		inventory = Inventory.to_dict(),
		crafting = Crafting.to_dict(),
		stats = {
			runs_completed = Game.runs_completed,
			runs_died = Game.runs_died,
			items_crafted = Game.items_crafted,
			successful_extractions = Game.successful_extractions,
		}
	}

func _apply_save_data(data: Dictionary):
	if data.has("inventory"):
		Inventory.from_dict(data.inventory)
	if data.has("crafting"):
		Crafting.from_dict(data.crafting)
	if data.has("stats"):
		var stats = data.stats
		Game.runs_completed = stats.get("runs_completed", 0)
		Game.runs_died = stats.get("runs_died", 0)
		Game.items_crafted = stats.get("items_crafted", 0)
		Game.successful_extractions = stats.get("successful_extractions", 0)
