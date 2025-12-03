# LoadMenu.gd
extends Control

@onready var save_list_container = $PanelBackground/VBoxContainer/HBoxContainer/SaveListContainer
@onready var back_button = $PanelBackground/VBoxContainer/BackButton
@onready var no_saves_label = $PanelBackground/VBoxContainer/NoSavesLabel

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	no_saves_label.hide()
	populate_save_list()

func populate_save_list():
	var save_files = []
	
	# 1. Open the user directory
	var dir = DirAccess.open("user://")
	if dir == null:
		print("Error: Could not open user directory.")
		return

	# 2. Find all valid save files
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		# Check if it's a save file (ends in .json)
		# Exclude settings and the file that tracks the last save
		if file_name.ends_with(".json") and file_name != "settings.json" and file_name != "last_save.json"and file_name != "controls.json":
			var save_name = file_name.trim_suffix(".json")
			var mod_time = FileAccess.get_modified_time("user://" + file_name)
			save_files.append({"name": save_name, "time": mod_time})
		
		file_name = dir.get_next()
	dir.list_dir_end()
	
	if save_files.is_empty():
		no_saves_label.show()
	else:
		no_saves_label.hide()

	# 3. Sort the files by modification time (most recent first)
	save_files.sort_custom(func(a, b): return a.time > b.time)

	# 4. Create a row (HBox) for each save file
	for save_file in save_files:
		# Create a horizontal container for the two buttons
		var hbox = HBoxContainer.new()
		
		# --- Save Button (on the left) ---
		var save_btn = Button.new()
		var t = Time.get_datetime_dict_from_unix_time(save_file.time)
		var time_str = "%s-%02d-%02d %02d:%02d" % [t.year, t.month, t.day, t.hour, t.minute]
		save_btn.text = "%s (%s)" % [save_file.name, time_str]
		
		# Make the save button expand to fill available space
		save_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		save_btn.pressed.connect(_on_save_file_pressed.bind(save_file.name))
		hbox.add_child(save_btn) # Add to HBox

		# --- Delete Button (on the right) ---
		var delete_btn = Button.new()
		delete_btn.text = "X" # Keep it small
		
		delete_btn.pressed.connect(_on_delete_button_pressed.bind(save_file.name))
		hbox.add_child(delete_btn) # Add to HBox
		
		# Add the whole HBox row to the VBoxContainer
		save_list_container.add_child(hbox)

func _on_delete_button_pressed(save_name: String):
	print("Deleting save: ", save_name)
	
	# 1. Construct the path and remove the file
	var save_path = "user://%s.json" % save_name
	var err = DirAccess.remove_absolute(save_path)
	if err != OK:
		print("Error deleting file: ", save_path)
	
	# 2. Check if this was the "last save"
	if FileAccess.file_exists(GameManager.LAST_SAVE_PATH):
		var file = FileAccess.open(GameManager.LAST_SAVE_PATH, FileAccess.READ)
		var json = JSON.parse_string(file.get_as_text())
		file.close()
		if json and json.get("last_save_name") == save_name:
			# If it was, delete the last_save.json file too
			DirAccess.remove_absolute(GameManager.LAST_SAVE_PATH)
			print("Removed last_save.json as it pointed to a deleted file.")

	# 3. Refresh the list
	_clear_save_list()
	populate_save_list()

func _clear_save_list():
	# Remove all existing buttons before repopulating
	for child in save_list_container.get_children():
		child.queue_free()
func _on_save_file_pressed(save_name: String):
	print("Loading save: ", save_name)
	# 1. Call the new GameManager function to load this specific file
	GameManager.load_game_by_name(save_name)
	
	# 2. Change scene based on the loaded data
	match GameManager.lastLevel:
		"Main":
			get_tree().change_scene_to_file("res://Scenes/Levels/main_menu.tscn")
		"Area1":
			get_tree().change_scene_to_file("res://Scenes/Levels/DemoLevel.tscn")
		"Area2":
			get_tree().change_scene_to_file("res://Scenes/Levels/level2.tscn")
		# Add any other levels here
		"Controls":
			get_tree().change_scene_to_file("res://Scenes/Levels/controls.tscn")


func _on_back_pressed():
	# Always go back to the main menu from here
	get_tree().change_scene_to_file("res://Scenes/Start.tscn")
	
#	Implement return to last level opened (whatever that may be)
