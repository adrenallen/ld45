extends GutTest

# Integration tests that verify scenes load correctly and have
# expected node types after the Godot 3 -> 4 migration.


func test_menu_scene_loads():
	var scene = load("res://Menu.tscn")
	assert_not_null(scene, "Menu.tscn should load")
	var instance = scene.instantiate()
	assert_not_null(instance, "Menu scene should instantiate")
	assert_true(instance is Control, "Menu root should be a Control")
	instance.free()


func test_crash_scene_loads():
	var scene = load("res://crash/Crashing.tscn")
	assert_not_null(scene, "Crashing.tscn should load")
	var instance = scene.instantiate()
	assert_not_null(instance, "Crashing scene should instantiate")
	assert_true(instance is Node2D, "Crashing root should be Node2D")
	instance.free()


func test_crash_ship_scene_loads():
	var scene = load("res://crash/ShipCrashing.tscn")
	assert_not_null(scene, "ShipCrashing.tscn should load")
	var instance = scene.instantiate()
	assert_not_null(instance, "ShipCrashing should instantiate")
	assert_true(instance is CharacterBody2D, "ShipCrashing root should be CharacterBody2D")
	instance.free()


func test_crash_tutorial_scene_loads():
	var scene = load("res://crash/Tutorial.tscn")
	assert_not_null(scene, "crash/Tutorial.tscn should load")
	var instance = scene.instantiate()
	assert_not_null(instance, "Crash tutorial should instantiate")
	instance.free()


func test_exploring_scene_loads():
	var scene = load("res://explore/Exploring.tscn")
	assert_not_null(scene, "Exploring.tscn should load")


func test_astro_scene_loads():
	var scene = load("res://explore/Astro.tscn")
	assert_not_null(scene, "Astro.tscn should load")
	var instance = scene.instantiate()
	assert_not_null(instance, "Astro should instantiate")
	assert_true(instance is CharacterBody2D, "Astro root should be CharacterBody2D")
	instance.free()


func test_fuel_scene_loads():
	var scene = load("res://explore/Fuel.tscn")
	assert_not_null(scene, "Fuel.tscn should load")
	var instance = scene.instantiate()
	assert_true(instance is Node2D, "Fuel root should be Node2D")
	instance.free()


func test_repair_scene_loads():
	var scene = load("res://explore/Repair.tscn")
	assert_not_null(scene, "Repair.tscn should load")


func test_air_pocket_scene_loads():
	var scene = load("res://explore/AirPocket.tscn")
	assert_not_null(scene, "AirPocket.tscn should load")


func test_launching_scene_loads():
	var scene = load("res://launch/Launching.tscn")
	assert_not_null(scene, "Launching.tscn should load")


func test_ship_launching_scene_loads():
	var scene = load("res://launch/ShipLaunching.tscn")
	assert_not_null(scene, "ShipLaunching.tscn should load")
	var instance = scene.instantiate()
	assert_true(instance is CharacterBody2D, "ShipLaunching root should be CharacterBody2D")
	instance.free()


func test_planet1_scene_loads():
	var scene = load("res://launch/Planet1.tscn")
	assert_not_null(scene, "Planet1.tscn should load")
	var instance = scene.instantiate()
	assert_true(instance is Node2D, "Planet1 root should be Node2D")
	instance.free()


func test_sun_scene_loads():
	var scene = load("res://launch/Sun.tscn")
	assert_not_null(scene, "Sun.tscn should load")


func test_alien_ship_scene_loads():
	var scene = load("res://launch/AlienShip.tscn")
	assert_not_null(scene, "AlienShip.tscn should load")
	var instance = scene.instantiate()
	assert_true(instance is CharacterBody2D, "AlienShip root should be CharacterBody2D")
	instance.free()


func test_alien_missile_scene_loads():
	var scene = load("res://launch/AlienMissile.tscn")
	assert_not_null(scene, "AlienMissile.tscn should load")
	var instance = scene.instantiate()
	assert_true(instance is CharacterBody2D, "AlienMissile root should be CharacterBody2D")
	instance.free()


func test_death_scene_loads():
	var scene = load("res://death/Death.tscn")
	assert_not_null(scene, "Death.tscn should load")


func test_leaderboard_scene_loads():
	var scene = load("res://leaderboard/Leaderboard.tscn")
	assert_not_null(scene, "Leaderboard.tscn should load")


func test_leaderboard_row_scene_loads():
	var scene = load("res://leaderboard/LeaderboardRow.tscn")
	assert_not_null(scene, "LeaderboardRow.tscn should load")


func test_transition_scene_loads():
	var scene = load("res://transition/Transition.tscn")
	assert_not_null(scene, "Transition.tscn should load")


func test_junk_scene_loads():
	var scene = load("res://crash/Junk.tscn")
	assert_not_null(scene, "Junk.tscn should load")
	var instance = scene.instantiate()
	assert_true(instance is Node2D, "Junk root should be Node2D")
	instance.free()


func test_biome_obstacle_scenes_load():
	var biome_scenes = [
		"res://crash/Mountain.tscn",
		"res://crash/Forest.tscn",
		"res://crash/Fungal.tscn",
		"res://crash/Gas.tscn",
		"res://crash/Water.tscn",
		"res://crash/Lava.tscn",
	]
	for path in biome_scenes:
		var scene = load(path)
		assert_not_null(scene, "%s should load" % path)


func test_ship_health_scene_loads():
	var scene = load("res://crash/ShipHealth.tscn")
	assert_not_null(scene, "ShipHealth.tscn should load")


func test_explore_tutorial_scene_loads():
	var scene = load("res://explore/Tutorial.tscn")
	assert_not_null(scene, "explore/Tutorial.tscn should load")


func test_launch_tutorial_scene_loads():
	var scene = load("res://launch/Tutorial.tscn")
	assert_not_null(scene, "launch/Tutorial.tscn should load")
