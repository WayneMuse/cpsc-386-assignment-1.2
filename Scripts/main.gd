extends Node2D

var check_interval := 1
var is_wave_transitioning := false
# Preload scenes
var zombie_scene = preload("res://Scenes/zombie.tscn")
var smart_zombie_scene = preload("res://Scenes/zombie_smart.tscn")
var static_block_scene = preload("res://Scenes/static_block.tscn") 
var minimap_scene = preload("res://Scenes/minimap.tscn") # Make sure path is correct

var generated_blocks = []
const map_limit = 2500

const player_safe_radius = 500.0
const min_block_dist = 300.0 

func _ready():
	# DEBUG: Enable this to SEE the navigation mesh (Light Green Overlay)
	# This helps confirm that holes are being cut around boxes.
	#NavigationServer2D.set_debug_enabled(true)
	
	var minimap = minimap_scene.instantiate()
	add_child(minimap)
	
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
	var thickness = 250
	
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
	if is_wave_transitioning:
		return

	var zombies = get_tree().get_nodes_in_group("Zombie")

	if zombies.is_empty():
		is_wave_transitioning = true
		await get_tree().create_timer(2.0).timeout
		start_next_wave()
		is_wave_transitioning = false

func start_next_wave():
	GameManager.current_wave += 1
	var wave_n = GameManager.current_wave
	print("Starting Wave: ", wave_n)

	if wave_n % 5 == 0:
		update_blocks()

	var total_count = wave_n + 4
	var smart_count = int(floor(wave_n / 5.0) * 2)
	#var smart_count = total_count # DEBUG
	print("Smart Count: %d" % smart_count)
	var regular_count = total_count - smart_count
	if regular_count < 0:
		regular_count = 0
		smart_count = total_count 

	spawn_zombies(regular_count, false)
	spawn_zombies(smart_count, true)
	
	# Remove old corpses
	cleanup_corpses()

func cleanup_corpses():
	var corpses = get_tree().get_nodes_in_group("Corpse")
	var current_wave = GameManager.current_wave
	
	for corpse in corpses:
		# If the difference is 2 or more (e.g. died in wave 1, current is 3), delete it
		if (current_wave - corpse.death_wave) >= 2:
			corpse.queue_free()

func update_blocks():
	print("Updating blocks and rebuilding NavMesh...")
	
	for block in generated_blocks:
		if is_instance_valid(block):
			block.queue_free()
	generated_blocks.clear()
	
	var player = get_tree().get_first_node_in_group("player")
	var player_pos = Vector2.ZERO
	if player:
		player_pos = player.global_position
	
	var num_blocks = randi_range(8, 48)
	var attempts = 0
	var max_attempts = 200
	
	while generated_blocks.size() < num_blocks and attempts < max_attempts:
		attempts += 1
	
	# 1. Randomize
		var rand_pos = Vector2(
			randf_range(-map_limit + 1000, map_limit - 1000), 
			randf_range(-map_limit + 1000, map_limit - 1000)
		)
		var rand_scale = Vector2(randf_range(0.5, 10.0), randf_range(0.5, 10.0))
		
		# 2. Check Player Safe Zone
		if player and rand_pos.distance_to(player_pos) < player_safe_radius:
			continue

		# 3. Create Candidate Rect for Intersection Checks
		var base_size = Vector2(128, 128)
		var cand_size = base_size * rand_scale
		var cand_rect = Rect2(rand_pos - (cand_size / 2), cand_size)
		
		var valid_placement = true
		
		# 4. Check against existing blocks
		for other_block in generated_blocks:
			# Reconstruct the other block's rect
			var other_size = base_size * other_block.scale
			var other_rect = Rect2(other_block.global_position - (other_size / 2), other_size)
			
			# A. DO THEY TOUCH? (Allowed -> Merging)
			if cand_rect.intersects(other_rect, true):
				continue 
			
			# B. IF NOT TOUCHING, ARE THEY TOO CLOSE? (Forbidden -> Gap too small)
			var expanded_rect = cand_rect.grow(min_block_dist)
			
			if expanded_rect.intersects(other_rect):
				valid_placement = false
				break # Reject
		
		if valid_placement:
			var block = static_block_scene.instantiate()
			block.global_position = rand_pos
			block.scale = rand_scale
			add_child(block)
			generated_blocks.append(block)
	
	# Rebuild Navigation
	await get_tree().physics_frame
	await get_tree().physics_frame
	build_nav_mesh()

func build_nav_mesh():
	var nav_region = find_child("NavigationRegion2D")
	if not nav_region:
		print("Error: NavigationRegion2D not found in Main scene!")
		return
	
	var nav_poly = NavigationPolygon.new()
		
	# --- CRITICAL SETTINGS ---
	# 1. Tell Godot to look for COLLISION SHAPES, not Meshes
	nav_poly.parsed_geometry_type = NavigationPolygon.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_poly.parsed_collision_mask = 0xFFFFFFFF
	
	# 2. Agent Radius: Slightly larger than Zombie radius (keeps them off walls)
	nav_poly.agent_radius = 65.0 
	
	var outline = PackedVector2Array([
		Vector2(-map_limit, -map_limit),
		Vector2(map_limit, -map_limit),
		Vector2(map_limit, map_limit),
		Vector2(-map_limit, map_limit)
	])
	nav_poly.add_outline(outline)

	var source_geometry = NavigationMeshSourceGeometryData2D.new()
	
	# 3. Parse everything
	NavigationServer2D.parse_source_geometry_data(nav_poly, source_geometry, self)

	# 4. Bake Nav mesh
	NavigationServer2D.bake_from_source_geometry_data(nav_poly, source_geometry)

	nav_region.navigation_polygon = nav_poly
	print("NavMesh baked successfully.")

func spawn_zombies(count: int, is_smart: bool):
	var player = get_tree().get_first_node_in_group("player")
	
	var space_state = get_world_2d().direct_space_state
	
	for i in range(count):
		var new_zombie
		if is_smart:
			new_zombie = smart_zombie_scene.instantiate()
			new_zombie.use_pathfinding = true 
		else:
			new_zombie = zombie_scene.instantiate()
			new_zombie.use_pathfinding = false
		
		var spawn_pos = Vector2.ZERO
		var valid_spawn = false
		var attempts = 0
		
		# --- SPAWN VALIDATION LOOP ---
		while not valid_spawn and attempts < 50:
			attempts += 1
			
			# 1. Pick Random Point
			var candidate_pos = Vector2(randf_range(-map_limit, map_limit), randf_range(-map_limit, map_limit))
			
			# 2. Check Distance to Player (Don't spawn on screen/too close)
			if player and candidate_pos.distance_to(player.global_position) < 1000:
				continue # Too close to player
			
			# 3. Check Physics Intersection (Don't spawn inside blocks/walls)
			# We query a single point. collision_mask 1 usually covers blocks/walls.
			var query = PhysicsPointQueryParameters2D.new()
			query.position = candidate_pos
			query.collide_with_bodies = true # Check StaticBodies
			query.collide_with_areas = false
			
			var result = space_state.intersect_point(query)
			
			if result.size() == 0:
				# No collision found, this spot is empty!
				spawn_pos = candidate_pos
				valid_spawn = true
			# else: hit a wall/block, loop runs again
		
		# If loop failed 50 times, we might spawn in a default spot or skip (safety)
		if valid_spawn:
			new_zombie.global_position = spawn_pos
			new_zombie.rotation = randf_range(0, TAU)
			add_child(new_zombie)
		else:
			print("Warning: Could not find valid spawn position for zombie.")
			new_zombie.queue_free()

func end_game():
	print("WIN")
	GameManager.current_wave = 0
	get_tree().change_scene_to_file("res://Scenes/Win Screen.tscn")
