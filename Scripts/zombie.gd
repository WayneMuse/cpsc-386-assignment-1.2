extends CharacterBody2D

@onready var ray_cast_2d = $RayCast2D
@onready var detection_area: Area2D = $Area2D
@export var move_speed: float = 150

@export var use_pathfinding: bool = false
var nav_agent: NavigationAgent2D

var player: CharacterBody2D
var dead := false
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
		nav_agent.radius = 30.0 
		
		# --- CRITICAL FIX: Connect the signal to move! ---
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
				
	# --- DUMB ZOMBIE LOGIC ---
	else:
		var bodies := detection_area.get_overlapping_bodies()
		var player_in_range := bodies.has(player)

		if player_in_range:
			var dir_to_player = global_position.direction_to(player.global_position)
			velocity = dir_to_player * move_speed
			global_rotation = dir_to_player.angle() + PI / 2.0
		else:
			velocity = Vector2.ZERO
		
		move_and_slide()
		_check_stuck(delta)

	# Attack check
	if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider() == player:
		player.kill()

# --- Callback for Smart Zombies with Avoidance ---
func _on_nav_velocity_computed(safe_velocity):
	if dead: return
	
	velocity = safe_velocity
	move_and_slide()
	# We check for stuck blocks HERE because this is when the movement actually happens
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
	$DeathSound.play()
	$Graphics/Dead.show()
	$Graphics/Zombie.hide()
	$CollisionShape2D.disabled = true
	z_index = -1
	remove_from_group("Zombie")

	var rand = randi() % 100
	if rand < 33:
		drop_ammo()
		drop_ammo()
		drop_ammo()
	elif rand < 66:
		drop_ammo()

	
	die()

func die():
	emit_signal("died")
	print("Zombie dies")

func drop_ammo():
	var ammo_scene = preload("res://Scenes/ammo_pickup.tscn")
	var ammo = ammo_scene.instantiate()
	
	get_tree().current_scene.add_child(ammo)
	ammo.global_position = global_position + Vector2(0, -50)
