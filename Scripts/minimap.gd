extends ColorRect

# Settings
var map_limit = 2500.0 # Your world boundary (+/-)
var map_size_px = Vector2(250, 250) # The size of this UI element
var padding = 5.0 # Padding inside the black box

# Calculated scale factor
var is_expanded = false
var scale_ratio: Vector2

# Storage for the "Mini" state
var mini_rect: Rect2
var mini_color: Color

func _ready():
	# 1. Save the initial "Mini" settings defined in the Editor
	mini_rect = get_rect() # Stores position and size
	mini_color = color
	
	# 2. Initial calculation
	recalculate_scale()

func _input(event):
	if event.is_action_pressed("map"):
		toggle_map()

func toggle_map():
	is_expanded = !is_expanded
	
	if is_expanded:
		# --- EXPAND MODE ---
		# Calculate a large square based on screen height (e.g., 80% of screen)
		var vp_size = get_viewport_rect().size
		var side_length = min(vp_size.x, vp_size.y) * 0.8
		
		# Set size
		size = Vector2(side_length, side_length)
		
		# Center on screen
		position = (vp_size / 2) - (size / 2)
		
		# Darker background for better visibility
		color = Color(0, 0, 0, 0.9)
		
		# Optional: Pause game while map is open?
		# get_tree().paused = true 
		
	else:
		# --- MINI MODE ---
		# Restore original position, size, and color
		position = mini_rect.position
		size = mini_rect.size
		color = mini_color
		
		# get_tree().paused = false

	# CRITICAL: Recalculate scale because 'size' changed
	recalculate_scale()
	queue_redraw()

func recalculate_scale():
	var world_size = Vector2(map_limit * 2, map_limit * 2)
	# Use current 'size' (whether mini or expanded)
	var usable_ui_size = size - Vector2(padding * 2, padding * 2)
	scale_ratio = usable_ui_size / world_size

func _process(_delta):
	# Request a redraw every frame to update positions
	queue_redraw()

func _draw():
	# 1. Draw Map Borders (White Outline)
	# Draw this first so it's behind everything
	var tl = world_to_map(Vector2(-map_limit, -map_limit))
	var tr = world_to_map(Vector2(map_limit, -map_limit))
	var br = world_to_map(Vector2(map_limit, map_limit))
	var bl = world_to_map(Vector2(-map_limit, map_limit))
	draw_polyline(PackedVector2Array([tl, tr, br, bl, tl]), Color.WHITE, 1.0)

	# 2. Draw Blocks (Grey Rects)
	var main_scene = get_tree().current_scene
	if main_scene and "generated_blocks" in main_scene:
		for block in main_scene.generated_blocks:
			if not is_instance_valid(block): continue
			
			var b_pos = world_to_map(block.global_position)
			
			var real_world_size = Vector2(128, 128) # Default fallback
			
			# Try to get the CollisionShape size (Most Accurate)
			var col = block.get_node_or_null("CollisionShape2D")
			if col and col.shape is RectangleShape2D:
				# Shape Size * Internal Scale * Root Scale
				real_world_size = col.shape.size * col.scale * block.scale
			# Else try to get Sprite size
			elif block.has_node("Block"):
				var sprite = block.get_node("Block")
				if sprite is Sprite2D and sprite.texture:
					real_world_size = sprite.texture.get_size() * sprite.scale * block.scale
			
			# Convert world size to Map Pixels
			var b_size_px = real_world_size * scale_ratio
			
			var b_rect = Rect2(b_pos - (b_size_px / 2), b_size_px)
			draw_rect(b_rect, Color.LIGHT_SLATE_GRAY)

	# 3. Draw Ammo (Yellow Dots) - NEW!
	var ammo_list = get_tree().get_nodes_in_group("Ammo")
	for ammo in ammo_list:
		if not is_instance_valid(ammo): continue
		
		var a_pos = world_to_map(ammo.global_position)
		if get_local_rect().has_point(a_pos):
			# Draw small yellow dot
			draw_circle(a_pos, 2, Color.YELLOW)

	# 4. Draw Zombies (Red Dots)
	var zombies = get_tree().get_nodes_in_group("Zombie")
	for zombie in zombies:
		if not is_instance_valid(zombie) or zombie.dead: continue
		var z_pos = world_to_map(zombie.global_position)
		if get_local_rect().has_point(z_pos):
			draw_circle(z_pos, 2, Color.RED)
			
			# Calculate Facing Direction
			var dir = Vector2.RIGHT.rotated(zombie.global_rotation - PI/2)
			
			# Settings for size
			var arrow_len = 14 if is_expanded else 8
			var arrow_width = 4 if is_expanded else 2  # This is the "thickness" at the base
			
			# Calculate the 3 points of the triangle
			var tip = z_pos + (dir * arrow_len)
			
			# Calculate perpendicular vector for the base width
			# We rotate the direction by 90 degrees (PI/2) to find "Right" and "Left" relative to facing
			var right_vec = dir.rotated(PI/2) * arrow_width
			
			var base_left = z_pos - right_vec
			var base_right = z_pos + right_vec
			
			# Draw the filled triangle
			var points = PackedVector2Array([tip, base_right, base_left])
			draw_colored_polygon(points, Color.LIGHT_CORAL)

	# 5. Draw Player (Green Dot) - Draw last so it's on top
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var p_pos = world_to_map(player.global_position)
		if get_local_rect().has_point(p_pos):
			draw_circle(p_pos, 3, Color.GREEN)
			# Calculate Facing Direction
			var dir = Vector2.RIGHT.rotated(player.global_rotation - PI/2)
			
			# Make player arrow slightly larger/longer than zombies so it stands out
			var arrow_len = 18 if is_expanded else 10
			var arrow_width = 6 if is_expanded else 3
			
			var tip = p_pos + (dir * arrow_len)
			var right_vec = dir.rotated(PI/2) * arrow_width
			
			var base_left = p_pos - right_vec
			var base_right = p_pos + right_vec
			
			var points = PackedVector2Array([tip, base_right, base_left])
			draw_colored_polygon(points, Color.LIGHT_GREEN)

# Helper: Convert World Coordinates to UI Coordinates
func world_to_map(world_pos: Vector2) -> Vector2:
	# 1. Offset world pos so (0,0) is top-left of the world (0 to 5000)
	var offset_pos = world_pos + Vector2(map_limit, map_limit)
	
	# 2. Scale it down
	var scaled_pos = offset_pos * scale_ratio
	
	# 3. Add padding offset
	return scaled_pos + Vector2(padding, padding)

# Helper: Check bounds if you don't want dots drawing outside the box
func get_local_rect() -> Rect2:
	return Rect2(Vector2.ZERO, size)
