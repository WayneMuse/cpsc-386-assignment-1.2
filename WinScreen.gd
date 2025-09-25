extends Control

@onready var main_menu_button = $Panel/MainMenu
@onready var quit_button = $Panel/Escape


func _ready():
	main_menu_button.pressed.connect(_on_main_menu_button)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_main_menu_button():
	# Load your main game scene
	get_tree().change_scene_to_file("res://Scenes/Start.tscn")

func _on_quit_pressed():
	get_tree().quit()
