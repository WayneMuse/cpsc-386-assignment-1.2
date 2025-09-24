extends Control

@onready var start_button = $Panel/Start
@onready var quit_button = $Panel/Exit

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	# Load your main game scene
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_quit_pressed():
	get_tree().quit()
