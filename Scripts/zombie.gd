extends CharacterBody2D

@onready var ray_cast_2d = $RayCast2D
@onready var detection_area: Area2D = $Area2D
@export var move_speed: float = 150

@export var use_pathfinding: bool = false
var nav_agent: NavigationAgent2D

var player: CharacterBody2D
var dead := false
var death_wave: int = 0

signal died

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

	if player:
		died.connect(player.add_kill)
	
	# Setup pathfinding if this is a Smart Zombie
	if use_pathfinding:
		nav_agent = NavigationAgent2D.new()
		
		# Tighter tolerances for smoother tracking
		nav_agent.path_desired_distance = 10.0 
		nav_agent.target_desired_distance = 10.0
		
		# Enable Avoidance
		nav_agent.avoidance_enabled = true 
		nav_agent.radius = 45.0 
		
		# --- CRITICAL: Connect the signal to move! ---
		nav_agent.velocity_computed.connect(_on_nav_velocity_computed)
		
		add_child(nav_agent)
		
		await get_tree().physics_frame

func _physics_process(delta: float) -> void:
	if dead: return
	if not player: return 
	
	# --- SMART ZOMBIE LOGIC ---
	if use_pathfinding and nav_agent:
		# 1. Update Target
		nav_agent.target_position = player.global_position
		
		# 2. Movement Calculation
		var next_path_pos = nav_agent.get_next_path_position()
		var dir = Vector2.ZERO
		
		# Fallback if very close (prevents stuttering)
		if global_position.distance_to(player.global_position) < 50.0:
			dir = global_position.direction_to(player.global_position)
		else:
			dir = global_position.direction_to(next_path_pos)
		
		var intended_velocity = dir * move_speed
		global_rotation = dir.angle() + PI / 2.0
		
		# 3. Apply Velocity
		if nav_agent.avoidance_enabled:
			# If avoidance is on, we send our velocity to the server.
			# The server will call '_on_nav_velocity_computed' with the safe result.
			nav_agent.set_velocity(intended_velocity)
		else:
			# If avoidance is off, we move immediately.
			velocity = intended_velocity
			move_and_slide()
			_check_stuck(delta) # Check collisions after moving
				
	# --- DUMB ZOMBIE (Vision Cone Logic) ---
	else:
		var bodies := detection_area.get_overlapping_bodies()
		var player_in_area := bodies.has(player)
		var should_chase := false

		if player_in_area:
			var dir_to_player = global_position.direction_to(player.global_position)
			var dist_to_player = global_position.distance_to(player.global_position)
			
			# 1. Calculate Facing Direction
			# Since your sprite faces UP, we adjust rotation by -90 degrees (-PI/2) to get the forward vector
			var facing_dir = Vector2.RIGHT.rotated(global_rotation - PI / 2.0)
			
			# 2. Check Vision Cone (Dot Product)
			# dot > 0.0 means 180 degree vision (Everything in front)
			# dot > 0.5 means 120 degree vision (Narrower cone)
			var in_vision_cone = facing_dir.dot(dir_to_player) > 0.2 
			
			# 3. Check Hearing (Proximity)
			# If player is VERY close (e.g. 100px), detect them even if behind
			var is_heard = dist_to_player < 100.0
			
			if in_vision_cone or is_heard:
				should_chase = true

		if should_chase:
			var dir_to_player = global_position.direction_to(player.global_position)
			velocity = dir_to_player * move_speed
			# Smooth rotation for dumb zombies looks better
			var target_rot = dir_to_player.angle() + PI / 2.0
			global_rotation = lerp_angle(global_rotation, target_rot, 10 * delta)
		else:
			velocity = Vector2.ZERO
		
		move_and_slide()
		_check_stuck(delta)

	if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider() == player:
		player.kill()

# --- Callback for Smart Zombies with Avoidance ---
func _on_nav_velocity_computed(safe_velocity):
	if dead: return
	
	velocity = safe_velocity
	move_and_slide()
	_check_stuck(get_physics_process_delta_time())

# --- Anti-Stuck Helper ---
func _check_stuck(delta):
	# If we hit something, check if it's a static block and push away
	if get_slide_collision_count() > 0:
		for i in get_slide_collision_count():
			var col = get_slide_collision(i)
			if col.get_collider() is StaticBody2D:
				# Force push out along the normal
				global_position += col.get_normal() * 100 * delta

func kill() -> void:
	if dead: return
	
	dead = true
	velocity = Vector2.ZERO 
	
	if nav_agent:
		nav_agent.set_velocity(Vector2.ZERO)
		nav_agent.avoidance_enabled = false # Other zombies will now ignore this node

	remove_from_group("Zombie") 
	add_to_group("Corpse")      
	death_wave = GameManager.current_wave 

	$DeathSound.play()
	$Graphics/Dead.show()
	$Graphics/Zombie.hide()
	
	# Disable physics collision so they can walk ON the corpse
	$CollisionShape2D.set_deferred("disabled", true)
	
	z_index = -1

	# Loot Logic
	var rand = randi() % 100
	
	if rand < 4:
		# Jackpot: Drop 10 items
		for i in 10:
			# Only the first one makes sound (i == 0)
			drop_ammo(i == 0) 
			
	elif rand < 15:
		# Medium Drop: Drop 5 items
		for i in 5:
			drop_ammo(i == 0)
			
	elif rand < 75:
		# Standard: Drop 1 item (Always sound)
		drop_ammo(true)

	die()

	
	die()

func die():
	emit_signal("died")
	print("Zombie dies")

func drop_ammo(play_sound: bool):
	var ammo_scene = preload("res://Scenes/ammo_pickup.tscn")
	var ammo = ammo_scene.instantiate()
	
	# Pass the boolean to the ammo instance
	ammo.sound = play_sound 
	
	get_tree().current_scene.add_child(ammo)
	ammo.global_position = global_position + Vector2(0, -50)
	
	# Optional: Add a little random scatter so they don't stack perfectly
	var scatter = Vector2(randf_range(-20, 20), randf_range(-20, 20))
	ammo.global_position += scatter
