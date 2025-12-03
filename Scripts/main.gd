extends Node2D

var check_interval := 1
# Preload scenes
var zombie_scene = preload("res://Scenes/zombie.tscn")
var smart_zombie_scene = preload("res://Scenes/zombie_smart.tscn")
var static_block_scene = preload("res://Scenes/static_block.tscn") 

var generated_blocks = []
const map_limit = 2500

func _ready():
	# Create Bounds
	create_bounds()
	
	# Random Gen Blocks
	update_blocks()
	
	var timer = Timer.new()
	timer.wait_time = check_interval
	timer.one_shot = false
	timer.timeout.connect(_on_check_zombies)
	add_child(timer)
	timer.start()

# --- BOUNDS LOGIC ---
func create_bounds():
	var thickness = 200
	
	var walls = [
		[Vector2(0, -map_limit), Vector2(map_limit * 2 + thickness, thickness)], 
		[Vector2(0, map_limit), Vector2(map_limit * 2 + thickness, thickness)], 
		[Vector2(-map_limit, 0), Vector2(thickness, map_limit * 2 + thickness)], 
		[Vector2(map_limit, 0), Vector2(thickness, map_limit * 2 + thickness)]  
	]
	
	var static_body = StaticBody2D.new()
	static_body.name = "MapBounds"
	
	add_child(static_body)
	
	for w in walls:
		var collision = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = w[1]
		collision.shape = rect
		collision.position = w[0]
		static_body.add_child(collision)
		
		var visual = ColorRect.new()
		visual.size = w[1]
		visual.position = w[0] - (w[1] / 2) 
		visual.color = Color(0.1, 0.1, 0.1) 
		static_body.add_child(visual)
	
	print("Map Bounds Created at +/- ", map_limit)

func _on_check_zombies():
	var zombies = get_tree().get_nodes_in_group("Zombie")
	
	if zombies.is_empty():
		start_next_wave()

func start_next_wave():
	GameManager.current_wave += 1
	var wave_n = GameManager.current_wave
	print("Starting Wave: ", wave_n)

	if wave_n % 5 == 0:
		update_blocks()

	var smart_count = int(floor(wave_n / 5.0) * 2)
	var total_count = wave_n + 4
	var regular_count = total_count - smart_count
	if regular_count < 0:
		regular_count = 0
		smart_count = total_count 
	
	spawn_zombies(regular_count, false)
	spawn_zombies(smart_count, true)

func update_blocks():
	print("Shifting blocks...")
	for block in generated_blocks:
		if is_instance_valid(block):
			block.queue_free()
	generated_blocks.clear()
	
	var num_blocks = randi_range(8, 24)
	var nav_region = find_child("NavigationRegion2D") # Get reference
	
	for i in range(num_blocks):
		var block = static_block_scene.instantiate()
		block.global_position = Vector2(randf_range(-2000, 2000), randf_range(-2000, 2000))
		block.scale = Vector2(randf_range(1.0, 4.0), randf_range(1.0, 4.0))
		add_child(block)
		generated_blocks.append(block)
	
	await get_tree().physics_frame
	build_nav_mesh()

func build_nav_mesh():
	var nav_region = find_child("NavigationRegion2D")
	if not nav_region:
		print("Error: NavigationRegion2D not found in Main scene!")
		return
		
	# 1. Create a new Navigation Polygon resource
	var nav_poly = NavigationPolygon.new()
	
	# Set settings (Agent Radius ensures zombies don't clip walls)
	nav_poly.agent_radius = 80.0 
	
	# 2. Define the "Floor" (The traversable 2500x2500 box)
	# This tells the system "This is the world, anything else inside here is a hole"
	var outline = PackedVector2Array([
		Vector2(-map_limit, -map_limit),
		Vector2(map_limit, -map_limit),
		Vector2(map_limit, map_limit),
		Vector2(-map_limit, map_limit)
	])
	nav_poly.add_outline(outline)
	
	# 3. Create Source Geometry Data
	var source_geometry = NavigationMeshSourceGeometryData2D.new()
	
	# 4. Parse specific nodes (Walls and Blocks)
	# This scans the Physics CollisionShapes of these nodes and marks them as obstacles
	
	# Parse Walls
	var map_bounds = find_child("MapBounds")
	if map_bounds:
		NavigationServer2D.parse_source_geometry_data(nav_poly, source_geometry, map_bounds)
		
	# Parse Blocks
	for block in generated_blocks:
		if is_instance_valid(block):
			NavigationServer2D.parse_source_geometry_data(nav_poly, source_geometry, block)

	# 5. Bake the Polygon
	# This generates the final navigation mesh based on the outline (Floor) and source geometry (Holes)
	NavigationServer2D.bake_from_source_geometry_data(nav_poly, source_geometry)
	
	# 6. Apply to Region
	nav_region.navigation_polygon = nav_poly
	print("NavMesh baked successfully via NavigationServer2D.")

func spawn_zombies(count: int, is_smart: bool):
	for i in range(count):
		var new_zombie
		
		if is_smart:
			new_zombie = smart_zombie_scene.instantiate()
			new_zombie.use_pathfinding = true 
		else:
			new_zombie = zombie_scene.instantiate()
			new_zombie.use_pathfinding = false
		
		var spawn_pos = Vector2(randf_range(-2000, 2000), randf_range(-2000, 2000))
		
		var player = get_tree().get_first_node_in_group("player")
		if player:
			while spawn_pos.distance_to(player.global_position) < 400:
				spawn_pos = Vector2(randf_range(-2000, 2000), randf_range(-2000, 2000))
		
		new_zombie.global_position = spawn_pos
		add_child(new_zombie)

func end_game():
	print("WIN")
	get_tree().change_scene_to_file("res://Scenes/Win Screen.tscn")
