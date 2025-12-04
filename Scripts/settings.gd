extends Control

# Sliders
@onready var master_slider = $PanelContainer/VBoxContainer/MasterSlider
@onready var sfx_slider     = $PanelContainer/VBoxContainer/SFXSlider
@onready var music_slider   = $PanelContainer/VBoxContainer/MusicSlider
@onready var main_menu      = $PanelContainer/VBoxContainer/BackButton

# Path to the player's JSON file
const PLAYER_PATH := "user://player.json"

func _ready() -> void:
	var data := _load_player_data()

	var master_bus := AudioServer.get_bus_index("Master")
	var sfx_bus    := AudioServer.get_bus_index("SFX")
	var music_bus  := AudioServer.get_bus_index("Music")

	# If the value exists in JSON, use it; otherwise use current bus volume.
	master_slider.value = data.get("master_volume_db", AudioServer.get_bus_volume_db(master_bus))
	sfx_slider.value    = data.get("sfx_volume_db",    AudioServer.get_bus_volume_db(sfx_bus))
	music_slider.value  = data.get("music_volume_db",  AudioServer.get_bus_volume_db(music_bus))

	# Apply volumes immediately so they match the sliders
	_on_master_slider_changed(master_slider.value)
	_on_sfx_slider_changed(sfx_slider.value)
	_on_music_slider_changed(music_slider.value)

	# Connect signals
	master_slider.value_changed.connect(_on_master_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)
	main_menu.pressed.connect(_on_main_pressed)


func _load_player_data() -> Dictionary:
	if not FileAccess.file_exists(PLAYER_PATH):
		return {}
	var file := FileAccess.open(PLAYER_PATH, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		return {}

	return json.data as Dictionary


func _save_settings_to_player() -> void:
	# Load existing data so we don't wipe out other player fields.
	var data := _load_player_data()

	data["master_volume_db"] = master_slider.value
	data["sfx_volume_db"]    = sfx_slider.value
	data["music_volume_db"]  = music_slider.value

	var file := FileAccess.open(PLAYER_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Error: Could not open player file for writing.")
		return

	file.store_string(JSON.stringify(data))
	file.close()
	print("Audio settings saved to ", PLAYER_PATH)


func _on_master_slider_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, value)
	print("MASTER BUS:", value)


func _on_sfx_slider_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus, value)
	print("SFX BUS:", value)


func _on_music_slider_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus, value)
	print("MUSIC BUS:", value)


func _on_main_pressed() -> void:
	_save_settings_to_player()
	get_tree().change_scene_to_file("res://Scenes/Start.tscn")
