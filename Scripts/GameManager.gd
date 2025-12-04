extends Node

var score: int = 0
var ammo: int = 0
var kills: int = 0
var game_paused: bool = false
var pause_ready: bool = true  
var current_wave: int = 0
var showingMenu = false

const SCORE_FILE = "user://highscores.json"
var high_scores = []

const LAST_SAVE_PATH = "user://last_save.json"
const SETTINGS_PATH = "user://settings.json"
const CONTROLS_PATH = "user://controls.json"

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	load_controls() # Load custom controls on startup
	load_high_scores()
	print("GameManager ready!")

func load_settings():
	if not FileAccess.file_exists(SETTINGS_PATH):
		print("No settings file found. Using defaults.")
		return 
	
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

func load_controls():
	if not FileAccess.file_exists(CONTROLS_PATH):
		print("No controls file found. Using defaults.")
		return

	var file = FileAccess.open(CONTROLS_PATH, FileAccess.READ)
	if file == null:
		print("Error: Could not open controls file.")
		return

	var json_string = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(json_string)
	if parse_result == null:
		print("Error: Could not parse controls JSON.")
		return

	# Apply the controls
	for action_name in parse_result.keys():
		var data = parse_result[action_name]
		
		# Clear default/current mapping
		InputMap.action_erase_events(action_name)
		
		# Re-create event based on saved data
		var new_event
		if data["type"] == "key":
			new_event = InputEventKey.new()
			new_event.physical_keycode = int(data["value"])
		elif data["type"] == "mouse":
			new_event = InputEventMouseButton.new()
			new_event.button_index = int(data["value"])
		
		if new_event:
			InputMap.action_add_event(action_name, new_event)
	
	print("Controls loaded successfully.")

func load_high_scores():
	if FileAccess.file_exists(SCORE_FILE):
		var file = FileAccess.open(SCORE_FILE, FileAccess.READ)
		var text = file.get_as_text()
		var json = JSON.parse_string(text)
		if json:
			high_scores = json
			# Ensure it's sorted on load
			high_scores.sort_custom(func(a, b): return a.score > b.score)
	else:
		high_scores = []

func save_game(save_name: String):
	var save_path = "user://%s.json" % save_name
	var save_data = {
		"current_wave": current_wave,
		"score": score,
		"ammo": ammo,
		"kills": kills,
	}
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		print("Error: Could not open save file for writing.")
		return
		
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	print("Game saved successfully to ", save_path)
	
	var last_save_file = FileAccess.open(LAST_SAVE_PATH, FileAccess.WRITE)
	if last_save_file == null:
		return
	
	var last_save_data = {"last_save_name": save_name}
	last_save_file.store_string(JSON.stringify(last_save_data))
	last_save_file.close()

func save_high_scores():
	var file = FileAccess.open(SCORE_FILE, FileAccess.WRITE)
	var json_str = JSON.stringify(high_scores)
	file.store_string(json_str)
	file.close()

func is_new_high_score(new_score: int) -> bool:
	# 1. If we have fewer than 10 scores, ANY score is a high score
	if high_scores.size() < 10:
		return true
	
	# 2. If we have 10+ scores, we must beat the 10th one (index 9)
	var threshold_score = high_scores[9]["score"]
	return new_score > threshold_score

func add_high_score(player_name: String, new_score: int):
	# Add the new entry to the potentially massive list
	high_scores.append({"name": player_name, "score": new_score})
	
	# Sort Descending (Highest First)
	high_scores.sort_custom(func(a, b): return a.score > b.score)
	
	save_high_scores()

func reset_high_scores():
	# 1. Clear the list in memory
	high_scores.clear()
	
	# 2. Save the empty list to file (overwriting the old one)
	save_high_scores()

func get_leaderboard_scores():
	# Return only the top 10 (or fewer if we don't have 10)
	return high_scores.slice(0, 10)

func load_game_by_name(save_name: String):	
	var save_path = "user://%s.json" % save_name
	if not FileAccess.file_exists(save_path):
		print("Error: Save file not found: ", save_path)
		return
		
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return
		
	var json_string = file.get_as_text()
	file.close()
	
	var parse_result = JSON.parse_string(json_string)
	if parse_result == null:
		return
		
	current_wave = int(parse_result.get("current_wave", 1))
	score = int(parse_result.get("score", 0))
	kills = int(parse_result.get("kills", 0))
	
	var last_save_file = FileAccess.open(LAST_SAVE_PATH, FileAccess.WRITE)
	if last_save_file:
		var last_save_data = {"last_save_name": save_name}
		last_save_file.store_string(JSON.stringify(last_save_data))
		last_save_file.close()
	
	print("Game loaded successfully from: ", save_path)
	
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _input(event):
	if event.is_action_pressed("menu") and not event.is_echo():
		
		# Prevent this input from triggering other things (like the Pause P key if mapped similarly)
		get_viewport().set_input_as_handled()
		
		if showingMenu:
			# If menu is open, ESC should ALWAYS close it.
			resume_game()
		else:
			# If menu is closed, check if we are allowed to open it (valid scene).
			var current_scene = get_tree().current_scene
			var excluded_scenes = [
				"res://Scenes/LoadMenu.tscn", 
				"res://Scenes/controls.tscn", 
				"res://Scenes/Start.tscn",
				"res://Scenes/Win Screen.tscn"
			]
			
			if current_scene and not excluded_scenes.has(current_scene.scene_file_path):
				open_menu()

# --- Unified State Management ---

func open_menu():
	var esc_menu = get_node_or_null("/root/EscMenu")
	if esc_menu:
		esc_menu.show()
		showingMenu = true
		
		# Force Pause
		pause_ready = false
		game_paused = true
		get_tree().paused = true
		print("Menu Opened")

func resume_game():
	var esc_menu = get_node_or_null("/root/EscMenu")
	if esc_menu:
		esc_menu.hide()
	
	showingMenu = false
	
	# Force Unpause
	pause_ready = true
	game_paused = false
	get_tree().paused = false
	print("Menu Closed & Game Resumed")

func pause():
	if game_paused: return
	pause_ready = false
	game_paused = true
	get_tree().paused = true
	print("Game Paused")

func unpause():
	if not game_paused: return
	pause_ready = true
	game_paused = false
	get_tree().paused = false
	print("Game Unpaused")

func add_score(amount: int):
	score += amount
	print("Total Score: ", score)
