extends CharacterBody2D

@onready var ray_cast_2d = $RayCast2D
@export var move_speed: float = 100
var player: CharacterBody2D
var dead := false
signal died

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

	if player:
		died.connect(player.add_kill)

func _physics_process(delta: float) -> void:
	if dead:
		return
	
	if not player:
		return  # safety check 
	
	var dir_to_player = global_position.direction_to(player.global_position)
	velocity = dir_to_player * move_speed
	move_and_slide()
	global_rotation = dir_to_player.angle() + PI / 2.0
	
	if ray_cast_2d.is_colliding() and ray_cast_2d.get_collider() == player:
		player.kill()
		
func kill() -> void:
	if dead:
		return
	dead = true
	$DeathSound.play()
	$Graphics/Dead.show()
	$Graphics/Zombie.hide()
	$CollisionShape2D.disabled = true
	z_index = -1
	remove_from_group("Zombie")
	
	if randi() % 100 < 66:
		drop_ammo()
	
	die()

func die():
	emit_signal("died")
	print("Zombie dies")
	#create pickable ammo
	
	#queue_free()

func drop_ammo():
	var ammo_scene = preload("res://Scenes/ammo_pickup.tscn")
	var ammo = ammo_scene.instantiate()
	
	get_tree().current_scene.add_child(ammo)
	ammo.global_position = global_position + Vector2(0, -50)
	
