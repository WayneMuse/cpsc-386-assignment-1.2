extends Control

@onready var sfx_slider = $PanelContainer/VBoxContainer/SFXSlider
@onready var music_slider = $PanelContainer/VBoxContainer/MusicSlider
@onready var main_menu = $PanelContainer/VBoxContainer/BackButton

#THE EXACT SAME AS THE PREVIOUS PROJECT WITH THE SAVING FEATURE @BRITE
const SETTINGS_PATH = "user://settings.json"

func _ready():
	sfx_slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX"))
	music_slider.value = AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Music"))
	main_menu.pressed.connect(_on_main_pressed)
	
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	music_slider.value_changed.connect(_on_music_slider_changed)

func save_settings():
	var settings_data = {
		"sfx_volume_db": sfx_slider.value,
		"music_volume_db": music_slider.value
	}
	
	var file = FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		print("Error: Could not open settings file for writing.")
		return
	
	var json_string = JSON.stringify(settings_data)
	
	file.store_string(json_string)
	file.close()
	print("Audio settings saved to ", SETTINGS_PATH)

func _on_sfx_slider_changed(value: float) -> void:
	var sfx_bus = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(sfx_bus, value)
	print("SFX BUS:", value)

func _on_music_slider_changed(value: float) -> void:
	var music_bus = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(music_bus, value)
	print("MUSIC BUS:", value)

func _on_main_pressed():
	save_settings()
	get_tree().change_scene_to_file("res://Scenes/Start.tscn")
