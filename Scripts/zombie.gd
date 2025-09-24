extends CharacterBody2D

@onready var ray_cast_2d = $RayCast2D
@export var move_speed: float = 100
var player: CharacterBody2D
var dead := false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if dead:
		return
	
	if not player:
		return  # safety check in case player doesn't exist
	
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
