extends Control

# Container where we will list the buttons
@onready var action_list_container = $PanelContainer/VBoxContainer/ScrollContainer/ActionList
@onready var back_button = $PanelContainer/VBoxContainer/BackButton

const CONTROLS_PATH = "user://controls.json"

# Dictionary of InputMap actions you want to allow remapping for
# Format: "input_action_name": "Readable Name for UI"
var actions_to_remap = {
	"move_up": "Move Up",
	"move_down": "Move Down",
	"move_left": "Move Left",
	"move_right": "Move Right",
	"sprint": "Sprint",
	"shoot": "Shoot/Attack",
	"pause": "Pause Game",
	"map": "Map",
}

var is_remapping = false
var action_being_remapped = null
var button_being_remapped = null

func _ready():
	# Clean up any placeholder children in the list
	for child in action_list_container.get_children():
		child.queue_free()
	
	# Create buttons for each action
	for action in actions_to_remap:
		create_action_button(action, actions_to_remap[action])
	
	back_button.pressed.connect(_on_back_pressed)

func create_action_button(action_name: String, readable_name: String):
	# Create a horizontal container for the label and button
	var hbox = HBoxContainer.new()
	action_list_container.add_child(hbox)
	
	# Label (e.g., "Move Up")
	var label = Label.new()
	label.text = readable_name
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(label)
	
	# Button (shows current key, e.g., "W")
	var button = Button.new()
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.text = get_button_text(action_name)
	button.pressed.connect(_on_remap_button_pressed.bind(button, action_name))
	hbox.add_child(button)

func get_button_text(action_name: String) -> String:
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		# Return the name of the first key/button assigned
		return events[0].as_text().trim_suffix(" (Physical)")
	return "Unbound"

func _on_remap_button_pressed(button: Button, action_name: String):
	if is_remapping: return
	
	is_remapping = true
	action_being_remapped = action_name
	button_being_remapped = button
	button.text = "Press key..."

func _input(event):
	if is_remapping:
		# Accept Keyboard keys or Mouse Buttons
		if (event is InputEventKey or event is InputEventMouseButton) and event.pressed:
			
			# Don't bind double clicks or scroll wheels usually
			if event is InputEventMouseButton and event.button_index > 3:
				return 

			# remove old inputs
			InputMap.action_erase_events(action_being_remapped)
			
			# Add new input
			InputMap.action_add_event(action_being_remapped, event)
			
			# Update UI
			button_being_remapped.text = event.as_text().trim_suffix(" (Physical)")
			
			# Reset remapping state
			is_remapping = false
			action_being_remapped = null
			button_being_remapped = null
			
			# Stop the input from propagating
			get_viewport().set_input_as_handled()

func save_controls():
	var controls_data = {}
	
	for action in actions_to_remap.keys():
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			var event = events[0]
			var entry = {}
			
			# We only save the first event for simplicity
			if event is InputEventKey:
				entry["type"] = "key"
				entry["value"] = event.physical_keycode # Use physical keycode for layout independence
			elif event is InputEventMouseButton:
				entry["type"] = "mouse"
				entry["value"] = event.button_index
			
			if not entry.is_empty():
				controls_data[action] = entry

	var file = FileAccess.open(CONTROLS_PATH, FileAccess.WRITE)
	if file == null:
		print("Error: Could not open controls file for writing.")
		return
	
	var json_string = JSON.stringify(controls_data)
	file.store_string(json_string)
	file.close()
	print("Controls saved to ", CONTROLS_PATH)

func _on_back_pressed():
	# Save before exiting
	save_controls()
	# Return to Start Menu
	get_tree().change_scene_to_file("res://Scenes/Start.tscn")
