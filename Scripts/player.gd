extends CharacterBody2D

@onready var ray_cast_2d = $RayCast2D
@export var move_speed = 200
var dead = false
var zombie_kills := 0
@onready var zombie_kill_label := $"CanvasLayer2/ZombieKillLabel"
@onready var zombie_count_label := $"CanvasLayer2/ZombieCountLevel"
@onready var ammo_label := $"CanvasLayer2/AmmoLabel"
@onready var zombie_count := get_tree().get_nodes_in_group("Zombie").size()
var player_ammo = 10
#var zombie_count = get_tree().get_nodes_in_group("Zombie").size() 
#zombie_count = get_tree().get_nodes_in_group("Zombie").size()

func _ready():
	
	update_kill_label()
	update_zombie_label()
	update_ammo_label()

func ammo_use():
	if player_ammo == 0:
		return
	
	player_ammo -= 1
	update_ammo_label()

func add_kill():
	zombie_kills += 1
	update_kill_label()

func update_ammo_label():
	if ammo_label:
		ammo_label.text = "Current Ammo: %d" % player_ammo

func update_zombie_label():
	#number of zombie - zombies killed
	
	zombie_count = get_tree().get_nodes_in_group("Zombie").size()
	if zombie_count_label:
		zombie_count_label.text = "Zombies remaining: %d" % zombie_count

func update_kill_label():
	if zombie_kill_label:
		zombie_kill_label.text = "Zombies killed: %d" % zombie_kills
#



func _process(delta: float):
	
	if Input.is_action_just_pressed("exit"):
		dead= true
		get_tree().change_scene_to_file("res://Scenes/Start.tscn")
		#global_rotation = 0
	if Input.is_action_just_pressed("restart"):
		restart()
	
	if dead:
		return
	else:
		global_rotation = global_position.direction_to(get_global_mouse_position()).angle() + PI/2.0
	
	
	if Input.is_action_just_pressed("shoot"):
		shoot()
	update_zombie_label()
	
	#check if player won
		#goto win screen	

func _physics_process(delta: float) -> void:
	if dead:
		return
	var move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	#
	velocity = move_dir * move_speed
	move_and_slide()

func kill():
	if dead:
		return
	dead = true
	print("PLAYER DEAD")
	$DeathSound.play()
	$Graphics/Dead.show()
	$Graphics/Shooter.hide()
	$"CanvasLayer/Death Screen".show()
	z_index = -1
	

func restart():
	get_tree().reload_current_scene()

func shoot():
	if player_ammo == 0:
		print("OUT OF AMMO")
		#play gun click noise
		
		return
		
	$Muzzleflash.show()
	$Muzzleflash/Timer.start()
	$ShootSound.play()
	print("FIRE")
	ammo_use()
	if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider().has_method("kill"):
		ray_cast_2d.get_collider().kill()
		
