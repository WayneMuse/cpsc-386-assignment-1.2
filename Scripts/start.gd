extends Control

@onready var start_button = $Panel/Start
@onready var quit_button = $Panel/Exit
@onready var Controls_button = $Panel/Controls

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	Controls_button.pressed.connect(_on_control_pressed)

func _on_start_pressed():
	# Load your main game scene
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_control_pressed():
	get_tree().change_scene_to_file("res://Scenes/controls.tscn")
