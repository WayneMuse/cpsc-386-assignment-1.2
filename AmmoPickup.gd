extends Area2D
@export var ammo_amount := 2

func _ready():
	connect("body_entered", _on_body_entered)

func _on_body_entered(body):
	print("ENTERED")
	if body.is_in_group("player"):
		body.add_ammo(ammo_amount)
		$AmmoSound.play()
		queue_free()
	
	

		
	
