extends Area2D
@export var ammo_amount := 2
@export var sound := false

func _ready():
	connect("body_entered", _on_body_entered)
	print($AmmoSound)
	
func _on_body_entered(body):
	if body.is_in_group("player"):
		# 1. Give Ammo
		body.add_ammo(ammo_amount)
		
		# 2. Disable Object immediately (so it looks picked up)
		hide() 
		$CollisionShape2D.set_deferred("disabled", true)
		
		# 3. Play sound if allowed
		if sound:
			$AmmoSound.play()
			# Wait for the sound to finish properly
			await $AmmoSound.finished
		
		# 4. Delete
		queue_free()
