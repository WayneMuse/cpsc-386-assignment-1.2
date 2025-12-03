extends Node2D

var check_interval := 1
var wave = GameManager.lastLevel

func _ready():
	var timer = Timer.new()
	timer.wait_time = check_interval
	timer.one_shot = false
	timer.timeout.connect(_on_check_zombies)
	add_child(timer)
	timer.start()

func _on_check_zombies():
	var zombies = get_tree().get_nodes_in_group("Zombie")
	if zombies.is_empty():
		# wait 5 seconds with countdown, then spawn zombies
		wave += 1

func end_game():
	print("WIN")
	get_tree().change_scene_to_file("res://Scenes/Win Screen.tscn")
	# Optional: Show UI, play sound, transition scenes, etc.
	# Example:
	#$CanvasLayer/WinLabel.show()
	#get_tree().paused = true  # Pause the game if you want
