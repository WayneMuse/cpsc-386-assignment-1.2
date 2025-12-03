extends Control

@onready var start_button = $Panel/PanelBackground/VBoxContainer/Start
@onready var quit_button = $Panel/PanelBackground/VBoxContainer/Exit
@onready var controls_button = $Panel/PanelBackground/VBoxContainer/Controls
@onready var load_button = $Panel/PanelBackground/VBoxContainer/Load
@onready var settings_button = $Panel/PanelBackground/VBoxContainer/Settings

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	controls_button.pressed.connect(_on_control_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

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

func _on_load_pressed():
	get_tree().change_scene_to_file("res://Scenes/LoadMenu.tscn")
