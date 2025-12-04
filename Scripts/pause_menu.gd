extends Control

var MainMenu
var SaveGame
var LoadGame
var NextLevel
var QuitGame
var SaveNameInput

var load_menu_popup = preload("res://Scenes/LoadMenu.tscn") # Adjust path if needed

# We don't need a local 'Wave' variable, we should modify GameManager directly

func _ready():
	# --- CRITICAL FIX: Allows buttons to work while game is paused ---
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Assign buttons manually
	MainMenu 		= $Panel/PanelContainer/VBoxContainer/MainMenuButton
	SaveGame 		= $Panel/PanelContainer/VBoxContainer/SaveGameButton
	LoadGame 		= $Panel/PanelContainer/VBoxContainer/LoadGameButton
	NextLevel 		= $Panel/PanelContainer/VBoxContainer/NextWaveButton
	QuitGame 		= $Panel/PanelContainer/VBoxContainer/QuitGameButton
	SaveNameInput 	= $Panel/PanelContainer/VBoxContainer/SaveNameInput
	
	# Connect button signals
	MainMenu.pressed.connect(_on_main_menu_pressed)
	LoadGame.pressed.connect(_on_load_game_pressed)
	SaveGame.pressed.connect(_on_save__game_pressed)
	QuitGame.pressed.connect(_on_quit_pressed)
	NextLevel.pressed.connect(_on_next_wave_pressed)
	
	pass

func _on_next_wave_pressed() -> void:
	# Hide menu and unpause
	GameManager.resume_game()

	# Logic to force next wave (Cheat/Debug)
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_method("start_next_wave"):
		print("Force starting next wave via Menu")
		current_scene.start_next_wave()
	else:
		print("Error: Could not find start_next_wave() on current scene.")


func _on_main_menu_pressed():
	GameManager.resume_game()
	GameManager.current_wave = 0
	get_tree().change_scene_to_file("res://Scenes/Start.tscn")

func _on_load_game_pressed():
	var load_menu = load_menu_popup.instantiate()
	add_child(load_menu)
	load_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Reset any offsets so it doesn't drift
	load_menu.offset_left = 0
	load_menu.offset_top = 0
	load_menu.offset_right = 0
	load_menu.offset_bottom = 0

func _on_save__game_pressed():	
	var save_name = SaveNameInput.text
	
	# Check if the name is empty
	if save_name.is_empty():
		print("Save name cannot be empty!")
		SaveNameInput.placeholder_text = "!EMPTY"
		return # Stop without saving

	# If the name is valid, proceed with saving
	GameManager.save_game(save_name)
	SaveNameInput.text = ""
	SaveNameInput.placeholder_text = "SAVED!"

func _on_quit_pressed():
	GameManager.resume_game()
	GameManager.current_wave = 0
	get_tree().quit()
