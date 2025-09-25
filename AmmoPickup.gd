extends Area2D
@export var ammo_amount := 2

func _ready():
	connect("body_entered", _on_body_entered)
	print($AmmoSound)
	
func _on_body_entered(body):
	print("ENTERED")
	$AmmoSound.play()
	if body.is_in_group("player"):
		body.add_ammo(ammo_amount)
		
		await get_tree().create_timer(0.2).timeout	#ends queue before sound can be played, thus needs to be delayed
		queue_free()
	
	

		
	
