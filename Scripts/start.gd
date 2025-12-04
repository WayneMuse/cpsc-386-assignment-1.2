extends Control

@onready var start_button = $Panel/PanelBackground/VBoxContainer/Start
@onready var quit_button = $Panel/PanelBackground/VBoxContainer/Exit
@onready var controls_button = $Panel/PanelBackground/VBoxContainer/Controls
@onready var load_button = $Panel/PanelBackground/VBoxContainer/Load
@onready var settings_button = $Panel/PanelBackground/VBoxContainer/Settings
@onready var high_score_button = $Panel/PanelBackground/VBoxContainer/HighScores

var load_menu_popup = preload("res://Scenes/LoadMenu.tscn")

func _ready():
	start_button.pressed.connect(_on_start_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	controls_button.pressed.connect(_on_control_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	if high_score_button:
		high_score_button.pressed.connect(_on_high_score_pressed)

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
	var load_menu = load_menu_popup.instantiate()
	add_child(load_menu)
	load_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Reset any offsets so it doesn't drift
	load_menu.offset_left = 0
	load_menu.offset_top = 0
	load_menu.offset_right = 0
	load_menu.offset_bottom = 0

func _on_high_score_pressed():
	get_tree().change_scene_to_file("res://Scenes/high_score.tscn")
