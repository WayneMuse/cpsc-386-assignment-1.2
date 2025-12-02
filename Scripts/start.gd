extends Control

@onready var start_button = $Panel/Start
@onready var quit_button = $Panel/Exit
@onready var Controls_button = $Panel/Controls
@onready var settings_button = $Panel/Settings
@onready var Saves_button = $Panel/Saves

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	Controls_button.pressed.connect(_on_control_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	Saves_button.pressed.connect(_on_saves_pressed)

func _on_start_pressed():
	# Load your main game scene
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _on_quit_pressed():
	get_tree().quit()

func _on_control_pressed():
	get_tree().change_scene_to_file("res://Scenes/controls.tscn")
	
func _on_settings_pressed():
	get_tree().change_scene_to_file("res://Scenes/settings.tscn")

#TODO: Takes user to save game menu
func _on_saves_pressed():
	print("Saves Pressed")
	#get_tree().change_scene_to_file("res://Scenes/saves.tscn")
