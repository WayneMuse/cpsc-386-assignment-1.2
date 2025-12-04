extends CharacterBody2D

@onready var ray_cast_2d = $RayCast2D
@export var move_speed = 250
@export var sprint_mult = 4
var dead = false

#animations
@onready var anim_sprite: AnimatedSprite2D = $Graphics/AnimatedSprite2D

# Display variables
var zombie_kills := 0
@onready var zombie_kill_label := $"CanvasLayer2/VBoxContainer/ZombieKillLabel"
@onready var zombie_count_label := $"CanvasLayer2/VBoxContainer/ZombieCountLevel"
@onready var ammo_label := $"CanvasLayer2/AmmoLabel"
@onready var score_label := $"CanvasLayer/Death Screen/Panel/ScoreLabel"
@onready var wave_label := $"CanvasLayer2/VBoxContainer/CurrentWaveLabel"
@onready var zombie_count := get_tree().get_nodes_in_group("Zombie").size()
var player_ammo = 20

@onready var death_screen := $"CanvasLayer/Death Screen"

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
	
	anim_sprite.play("Idle") 
	
	update_kill_label()
	update_zombie_label()
	update_wave_label()
	update_ammo_label()
	update_score_label()

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

func update_score_label():
	if score_label:
		score_label.text = "Score: %d" % GameManager.score

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
	_update_animation()

func _update_animation() -> void:
	# If we're moving, play Walking, otherwise Idle
	if velocity.length() > 0.0001:
		#if anim_sprite.animation != "Walking":
		anim_sprite.play("Walking")
	else:
			#if anim_sprite.animation != "Idle":
		anim_sprite.play("Idle")

func kill():
	if dead: return
	dead = true
	
	# 1. Visuals: Show corpse, hide player
	$DeathSound.play()
	$Graphics/Dead.show()
	$Graphics/Shooter.hide()
	$Graphics/AnimatedSprite2D.hide()
	z_index = -1
	
	# 2. Prepare the Death Screen for fading
	# Set alpha to 0 (Invisible) so it doesn't pop in instantly
	death_screen.modulate.a = 0 
	death_screen.show()
	
	# 3. Create a Tween to animate the fade
	var tween = create_tween()
	
	# Animate "modulate:a" to 1.0 over 2.0 seconds
	tween.tween_property(death_screen, "modulate:a", 1.0, 2.0)
	
	# 4. Wait for the fade to finish
	await tween.finished

	$"CanvasLayer/Death Screen".show()
	$"CanvasLayer/Death Screen/Panel/Restart".pressed.connect(escapeToStartMenu)
	$"CanvasLayer/Death Screen/Panel/Scores".pressed.connect(highScores)
	$"CanvasLayer/Death Screen/Panel/Exit".pressed.connect(exitGame)
	update_score_label()
	
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
func highScores():
	GameManager.current_wave = 0
	get_tree().change_scene_to_file("res://Scenes/high_score.tscn")
func escapeToStartMenu():
	GameManager.current_wave = 0
	get_tree().change_scene_to_file("res://Scenes/Start.tscn")
