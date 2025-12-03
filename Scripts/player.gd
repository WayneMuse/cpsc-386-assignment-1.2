extends CharacterBody2D

@onready var ray_cast_2d = $RayCast2D
@export var move_speed = 250
@export var sprint_mult = 4
var dead = false

# Display variables
var zombie_kills := 0
@onready var zombie_kill_label := $"CanvasLayer2/VBoxContainer/ZombieKillLabel"
@onready var zombie_count_label := $"CanvasLayer2/VBoxContainer/ZombieCountLevel"
@onready var ammo_label := $"CanvasLayer2/AmmoLabel"
@onready var wave_label := $"CanvasLayer2/VBoxContainer/CurrentWaveLabel"
@onready var zombie_count := get_tree().get_nodes_in_group("Zombie").size()
var player_ammo = 20

# UI Reference for the new indicator
var offscreen_indicator: Control

func _ready():
	# 1. Expand View (Zoom Out)
	var cam = get_node_or_null("Camera2D")
	if cam:
		cam.zoom = Vector2(0.4, 0.4) 
	else:
		var new_cam = Camera2D.new()
		new_cam.zoom = Vector2(0.4, 0.4)
		add_child(new_cam)

	# 2. Create the Off-Screen Radial Indicator
	_create_offscreen_indicator()

	update_kill_label()
	update_zombie_label()
	update_wave_label()
	update_ammo_label()

func _create_offscreen_indicator():
	# Check if we have the UI layer
	var canvas = get_node_or_null("CanvasLayer2")
	if not canvas: 
		print("Error: CanvasLayer2 not found")
		return

	# Create a full-screen Control node to handle drawing
	offscreen_indicator = Control.new()
	offscreen_indicator.name = "Radar"
	# CRITICAL FIX: Explicitly set size to viewport size
	offscreen_indicator.size = get_viewport_rect().size
	offscreen_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	offscreen_indicator.z_index = 10 # Ensure it draws on top
	
	# Add the drawing script
	var indicator_script = GDScript.new()
	indicator_script.source_code = """
extends Control

var player_ref = null
var draw_radius = 300.0 

func _process(_delta):
	# Keep the drawing layer the size of the screen if window resizes
	size = get_viewport_rect().size
	queue_redraw() 

func _draw():
	if not player_ref or not is_instance_valid(player_ref): return
	
	var viewport_rect = get_viewport_rect()
	
	# Get Player's position on the screen (Center of view usually)
	var player_screen_pos = player_ref.get_global_transform_with_canvas().origin
	
	var zombies = get_tree().get_nodes_in_group("Zombie")
	
	for zombie in zombies:
		if not is_instance_valid(zombie): continue
		if zombie.dead: continue 
		
		# Get Zombie's position on the screen
		var zombie_screen_pos = zombie.get_global_transform_with_canvas().origin
		
		# CHECK: Is zombie Off-Screen?
		# We check if the point is NOT inside the rectangle
		if not viewport_rect.has_point(zombie_screen_pos):
			
			# Calculate direction from Player to Zombie
			var dir = (zombie_screen_pos - player_screen_pos).normalized()
			
			# Draw Red Dot at the radius
			# We ensure the radius isn't larger than half the screen (clamping)
			var max_radius = min(size.x, size.y) / 2.0 - 50.0
			var actual_radius = min(draw_radius, max_radius)
			
			var draw_pos = player_screen_pos + (dir * actual_radius)
			
			draw_circle(draw_pos, 8, Color(1, 0, 0, 1))
"""
	offscreen_indicator.set_script(indicator_script)
	offscreen_indicator.set("player_ref", self)
	
	canvas.add_child(offscreen_indicator)

func ammo_use():
	if player_ammo == 0:
		return
	player_ammo -= 1
	update_ammo_label()

func add_kill():
	zombie_kills += 1
	var wave = GameManager.current_wave
	var multiplier = 1 + (wave / 5)
	GameManager.add_score(multiplier)
	update_kill_label()

func add_ammo(amount: int):
	player_ammo += amount
	update_ammo_label()

func update_ammo_label():
	if ammo_label:
		ammo_label.text = "Current Ammo: %d" % player_ammo

func update_zombie_label():
	zombie_count = get_tree().get_nodes_in_group("Zombie").size()
	if zombie_count_label:
		zombie_count_label.text = "Zombies remaining: %d" % zombie_count

func update_kill_label():
	if zombie_kill_label:
		zombie_kill_label.text = "Kills: %d | Score: %d" % [zombie_kills, GameManager.score]

func update_wave_label():
	if GameManager.current_wave != 0 and wave_label:
		wave_label.text = "Current Wave: %d" % GameManager.current_wave

func _process(_delta: float):
	if Input.is_action_just_pressed("restart"):
		dead=true
		restart()
	
	if dead: return
	
	# Rotation logic
	global_rotation = global_position.direction_to(get_global_mouse_position()).angle() + PI/2.0
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
		
	# Update UI elements
	update_zombie_label()
	update_wave_label() 

func _physics_process(_delta: float) -> void:
	if dead: return
	
	var move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var current_speed = move_speed
	
	if Input.is_action_pressed("sprint"):
		current_speed = move_speed * sprint_mult
	
	velocity = move_dir * current_speed
	move_and_slide()

func kill():
	if dead: return
	dead = true
	$DeathSound.play()
	$Graphics/Dead.show()
	$Graphics/Shooter.hide()
	$"CanvasLayer/Death Screen".show()
	$"CanvasLayer/Death Screen/Panel/Restart".pressed.connect(escapeToStartMenu)
	$"CanvasLayer/Death Screen/Panel/Exit".pressed.connect(exitGame)
	z_index = -1

func shoot():
	if player_ammo == 0:
		$EmptySound.play()
		return
		
	$Muzzleflash.show()
	$Muzzleflash/Timer.start()
	$ShootSound.play()
	ammo_use()
	
	if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider().has_method("kill"):
		ray_cast_2d.get_collider().kill()

func exitGame():
	GameManager.current_wave = 0
	get_tree().quit()
func restart():
	GameManager.current_wave = 0
	get_tree().reload_current_scene()
func escapeToStartMenu():
	GameManager.current_wave = 0
	get_tree().change_scene_to_file("res://Scenes/Start.tscn")
