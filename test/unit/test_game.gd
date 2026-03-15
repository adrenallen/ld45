extends GutTest

# Tests for Game.gd autoload - core game logic

var game: Node


func before_each():
	game = load("res://Game.gd").new()
	add_child_autofree(game)


func test_initial_state_after_refresh():
	game.refresh()
	assert_eq(game.dead, false, "Should not be dead after refresh")
	assert_eq(game.fuel, 20, "Should start with 20 fuel")
	assert_eq(game.oxygen, 100, "Should start with 100 oxygen")
	assert_eq(game.shipHealth, game.MAX_SHIP_HEALTH, "Should start with max ship health")
	assert_eq(game.planetsLandedOn, 0, "Should have 0 planets landed on")
	assert_eq(game.distance, 0, "Distance should be 0")
	assert_eq(game.currentDistance, 0, "Current distance should be 0")
	assert_eq(game.playerInAirPocket, false, "Should not be in air pocket")


func test_max_ship_health_constant():
	assert_eq(game.MAX_SHIP_HEALTH, 5, "Max ship health should be 5")


func test_max_atmo_toxic_constant():
	assert_eq(game.MAX_ATMO_TOXIC, 5, "Max atmosphere toxicity should be 5")


func test_air_pocket_oxygen_rate_constant():
	assert_eq(game.AIR_POCKET_OXYGEN_RATE, 5, "Air pocket oxygen rate should be 5")


func test_enums_exist():
	# PlanetBiome enum
	assert_eq(game.PlanetBiome.Forest, 0, "Forest should be biome 0")
	assert_eq(game.PlanetBiome.Mountain, 1, "Mountain should be biome 1")
	assert_eq(game.PlanetBiome.Fungal, 2, "Fungal should be biome 2")
	assert_eq(game.PlanetBiome.Gas, 3, "Gas should be biome 3")
	assert_eq(game.PlanetBiome.Water, 4, "Water should be biome 4")
	assert_eq(game.PlanetBiome.Lava, 5, "Lava should be biome 5")

	# DeathBy enum
	assert_eq(game.DeathBy.Sun, 0, "Sun should be death cause 0")
	assert_eq(game.DeathBy.Planet, 1, "Planet should be death cause 1")
	assert_eq(game.DeathBy.AlienShip, 2, "AlienShip should be death cause 2")


func test_add_fuel():
	game.fuel = 50
	game.addFuel(10)
	assert_eq(game.fuel, 60, "Fuel should increase by 10")


func test_add_fuel_does_not_exceed_100():
	game.fuel = 100
	game.addFuel(10)
	assert_eq(game.fuel, 100, "Fuel should not increase when at 100")


func test_add_fuel_at_boundary():
	game.fuel = 99
	game.addFuel(10)
	assert_eq(game.fuel, 109, "Fuel can go over 100 if added when below")


func test_repair_ship():
	game.shipHealth = 3
	game.repairShip()
	assert_eq(game.shipHealth, 4, "Ship health should increase by 1")


func test_repair_ship_at_max():
	game.shipHealth = game.MAX_SHIP_HEALTH
	game.repairShip()
	assert_eq(game.shipHealth, game.MAX_SHIP_HEALTH, "Ship health should not exceed max")


func test_generate_planet():
	var planet = game.generatePlanet()
	assert_has(planet, "radius", "Planet should have radius")
	assert_has(planet, "gravity", "Planet should have gravity")
	assert_has(planet, "biome", "Planet should have biome")
	assert_has(planet, "atmosphereToxicity", "Planet should have atmosphereToxicity")


func test_generate_planet_radius_range():
	# Generate many planets and check ranges
	for i in range(100):
		var planet = game.generatePlanet()
		assert_true(planet.radius >= 16 and planet.radius <= 64,
			"Planet radius should be between 16 and 64, got: %s" % planet.radius)


func test_generate_planet_gravity_range():
	for i in range(100):
		var planet = game.generatePlanet()
		assert_true(planet.gravity >= 20 and planet.gravity <= 80,
			"Planet gravity should be between 20 and 80, got: %s" % planet.gravity)


func test_generate_planet_toxicity_range():
	for i in range(100):
		var planet = game.generatePlanet()
		assert_true(planet.atmosphereToxicity >= 1 and planet.atmosphereToxicity <= game.MAX_ATMO_TOXIC,
			"Toxicity should be between 1 and %s, got: %s" % [game.MAX_ATMO_TOXIC, planet.atmosphereToxicity])


func test_generate_planet_biome_valid():
	var valid_biomes = game.PlanetBiome.values()
	for i in range(100):
		var planet = game.generatePlanet()
		assert_true(planet.biome in valid_biomes,
			"Biome should be a valid PlanetBiome value")


func test_first_planet_is_easy():
	game.refresh()
	assert_eq(game.currentPlanet.atmosphereToxicity, 1.0, "First planet toxicity should be 1.0")
	assert_eq(game.currentPlanet.radius, 16.0, "First planet radius should be 16.0")
	assert_eq(game.currentPlanet.biome, game.PlanetBiome.Mountain, "First planet should be Mountain")


func test_set_planet():
	var mock_planet = RefCounted.new()
	mock_planet.set_meta("planetRadius", 42)
	mock_planet.set_meta("gravity", 55)
	mock_planet.set_meta("biome", game.PlanetBiome.Lava)
	mock_planet.set_meta("atmosphereToxicity", 3)

	# setPlanet expects an object with properties, create a simple one
	var planet_node = Node2D.new()
	planet_node.set_script(load("res://test/unit/helper_planet_stub.gd"))
	planet_node.planetRadius = 42
	planet_node.gravity = 55
	planet_node.biome = game.PlanetBiome.Lava
	planet_node.atmosphereToxicity = 3
	add_child_autofree(planet_node)

	game.setPlanet(planet_node)
	assert_eq(game.currentPlanet.radius, 42, "Planet radius should be set")
	assert_eq(game.currentPlanet.gravity, 55, "Planet gravity should be set")
	assert_eq(game.currentPlanet.biome, game.PlanetBiome.Lava, "Planet biome should be Lava")
	assert_eq(game.currentPlanet.atmosphereToxicity, 3, "Toxicity should be set")


func test_get_current_biome_tint_returns_color():
	game.currentPlanet.biome = game.PlanetBiome.Mountain
	var color = game.getCurrentBiomeTint()
	assert_true(color is Color, "Should return a Color")
	assert_eq(color.a, 1.0, "Alpha should be 1.0")


func test_get_current_biome_tint_per_biome():
	# Just verify each biome returns a valid color without crashing
	for biome in game.PlanetBiome.values():
		game.currentPlanet.biome = biome
		var color = game.getCurrentBiomeTint()
		assert_true(color is Color, "Biome %s should return a Color" % biome)
		assert_true(color.a == 1.0, "Alpha should be 1.0 for biome %s" % biome)


func test_get_miles_traveled():
	game.cheaterMode = false
	game.distance = 5
	game.currentDistance = 3
	assert_eq(game.getMilesTraveled(), round(8 * 1000.0), "Miles should be (distance + currentDistance) * 1000")


func test_get_miles_traveled_cheater_mode():
	game.cheaterMode = true
	game.distance = 999
	game.currentDistance = 999
	assert_eq(game.getMilesTraveled(), 0, "Cheater mode should return 0 miles")


func test_get_max_alien_fighters():
	game.cheaterMode = false
	game.distance = 0
	game.currentDistance = 0
	var fighters = game.getMaxAlienFighters()
	assert_true(fighters >= 0, "Max alien fighters should be non-negative")


func test_secret_returns_distance():
	assert_eq(game.secret(42), 42, "Secret should return the distance unchanged")
	assert_eq(game.secret(0), 0, "Secret should return 0 for 0")


func test_death_by_info_default():
	game.refresh()
	assert_eq(game.deathBy.cause, null, "Death cause should be null after refresh")
