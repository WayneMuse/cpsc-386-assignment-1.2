extends Control

@onready var back_button = $Panel/Back

func _ready():
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	# Load your main game scene
	get_tree().change_scene_to_file("res://Scenes/Start.tscn")
