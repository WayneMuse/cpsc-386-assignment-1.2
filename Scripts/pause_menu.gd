extends Control

var MainMenu
var SaveGame
var LoadGame
var NextLevel
var QuitGame
var SaveNameInput
var Wave = GameManager.current_wave

func _ready():
	# Assign buttons manually
	MainMenu 		= $Background/VBoxContainer/MainMenuButton
	SaveGame 		= $Background/VBoxContainer/SaveGameButton
	LoadGame 		= $Background/VBoxContainer/LoadGameButton
	NextLevel 		= $Background/VBoxContainer/NextLevelButton
	QuitGame 		= $Background/VBoxContainer/QuitGameButton
	SaveNameInput 	= $Background/VBoxContainer/SaveNameInput


	
	# Connect button signals
	MainMenu.pressed.connect(_on_main_menu_pressed)
	LoadGame.pressed.connect(_on_load_game_pressed)
	SaveGame.pressed.connect(_on_save__game_pressed)
	QuitGame.pressed.connect(_on_quit_pressed)
	NextLevel.pressed.connect(_on_next_level_pressed)

func _on_next_level_pressed() -> void:
	# Hide menu and unpause the game
	$"/root/EscMenu".hide()
	GameManager.unpause()

	# Get current scene file name
	var current_scene := get_tree().current_scene
	if not current_scene:
		print("No current scene loaded!")
		return

	var _scene_name := current_scene.scene_file_path.get_file().get_basename()

# # # Update to wave structure, spawn (n + 4) zombies per wave
# # # Points = (zombies killed * min( 1, (wave / 5) ) )
	Wave += 1
	
	## Check which level we're in and go to the next one
	#if _scene_name == "level1":
		#get_tree().change_scene_to_file("res://Scenes/Levels/level2.tscn")
		#print("leaving scene ", _scene_name, " moving to level2")
	#elif _scene_name == "level2":
		#get_tree().change_scene_to_file("res://Scenes/Levels/level3.tscn")
		#print("leaving scene ", _scene_name, " moving to level3")
	#elif _scene_name == "level3 ":
		#get_tree().change_scene_to_file("res://Scenes/Levels/winscreen.tscn")
		#print("leaving scene", _scene_name, " moving to winscreen")
	#else:
		#print("No next level defined for: ", _scene_name)
##	increment level counter by 1 to have "level" + counter + ".tscn" transfer scenes properly
	##i couldve brite but this way is way easier lol

func _on_main_menu_pressed():
	$"/root/EscMenu".hide()
	GameManager.unpause()
	get_tree().change_scene_to_file("res://Scenes/Levels/main_menu.tscn")

func _on_load_game_pressed():
	GameManager.unpause()
	$"/root/EscMenu".hide()
	
	get_tree().change_scene_to_file("res://Scenes/Levels/load_menu.tscn")

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
	
	#get_tree().change_scene_to_file("res://Scenes/Levels/main_menu.tscn")

func _on_quit_pressed():
	get_tree().quit()
