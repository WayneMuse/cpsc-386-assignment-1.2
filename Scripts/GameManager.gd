extends Node

var score: int = 0
var game_paused: bool = false
var pause_ready: bool = true  
var current_wave: int = 1
var showingMenu 	= false

const LAST_SAVE_PATH = "user://last_save.json"
const SETTINGS_PATH = "user://settings.json"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	print("GameManager ready!")

func load_settings():
	if not FileAccess.file_exists(SETTINGS_PATH):
		print("No settings file found. Using defaults.")
		return # Nothing to load
	
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	
	if file == null:
		print("Error: Could not open settings file for reading.")
		return
	
	var json_string = file.get_as_text()
	file.close()
	var parse_result = JSON.parse_string(json_string)
	
	if parse_result == null:
		print("Error: Could not parse settings file JSON.")
		return
	
	var sfx_bus = AudioServer.get_bus_index("SFX")
	var music_bus = AudioServer.get_bus_index("Music")
	
	var sfx_vol_db = parse_result.get("sfx_volume_db", 0.0)
	var music_vol_db = parse_result.get("music_volume_db", 0.0)
	
	AudioServer.set_bus_volume_db(sfx_bus, sfx_vol_db)
	AudioServer.set_bus_volume_db(music_bus, music_vol_db)
	
	print("Audio settings loaded.")

func save_game(save_name: String):
	var save_path = "user://%s.json" % save_name
	
	# 1. Create a dictionary with the data to save
	var save_data = {
		"current_wave": current_wave,
		"score": score
	}
	
	# 2. Open the save file for writing
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		print("Error: Could not open save file for writing.")
		return
		
	# 3. Convert the dictionary to a JSON string
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	print("Game saved successfully to ", save_path)
	
	# 4. Store the string and close the file
	var last_save_file = FileAccess.open(LAST_SAVE_PATH, FileAccess.WRITE)
	if last_save_file == null:
		print("Error: Could not update last save file.")
		return
	
	var last_save_data = {"last_save_name": save_name}
	last_save_file.store_string(JSON.stringify(last_save_data))
	last_save_file.close()
	print("Set last save to: ", save_name)

func load_game_by_name(save_name: String):	
	var save_path = "user://%s.json" % save_name
	
	# 1. Check if the save file exists
	if not FileAccess.file_exists(save_path):
		print("Error: Save file not found: ", save_path)
		return
		
	# 2. Open the file for reading
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		print("Error: Could not open save file for reading: ", save_path)
		return
		
	# 3. Read, parse, and apply the data
	var json_string = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(json_string)
	
	if parse_result == null:
		print("Error: Could not parse save file JSON from ", save_path)
		return
		
	current_wave = parse_result.get("current_wave", "Main")
	score = parse_result.get("score", 0)
	
	# 4. Update the "last_save.json" to this newly loaded file
	var last_save_file = FileAccess.open(LAST_SAVE_PATH, FileAccess.WRITE)
	if last_save_file == null:
		print("Error: Could not update last save file.")
		return
		
	var last_save_data = {"last_save_name": save_name}
	last_save_file.store_string(JSON.stringify(last_save_data))
	last_save_file.close()
	
	print("Game loaded successfully from: ", save_path)
	print("Loaded data: ", parse_result)

func _input(event):
	if event.is_action_pressed("Pause") and pause_ready:
		pause()

	if event.is_action_released("Pause"):
		unpause()
	
	var excluded_scenes = [
		"res://Scenes/LoadMenu.tscn",
		"res://Scenes/controls.tscn",
		"res://Scenes/Start.tscn"
	]
	
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	if event.is_action_pressed("Menu") and not excluded_scenes.has(current_scene_path):
		if !showingMenu:
			print("Menu Open")
			$"/root/EscMenu".show()
			showingMenu = true
			
			pause()
		else:
			print("Menu Close")
			$"/root/EscMenu".hide()
			showingMenu = false
			
			unpause()

func pause_toggle():
		pause_ready = false
		game_paused = !game_paused
		get_tree().paused = game_paused
		print("Pause toggled:", game_paused)

func pause():
	pause_ready = false
	game_paused = true
	get_tree().paused = game_paused
	print("Game Paused!")

func unpause():
	pause_ready = true
	game_paused = false
	get_tree().paused = game_paused
	print("Game Unpaused!")

func add_score(amount):
	score += amount
	print(score)
