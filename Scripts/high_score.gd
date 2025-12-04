extends Control

# List Container
@onready var score_container := $Panel/VBoxContainer/ScoresContainer
@onready var reset_score := $Panel/VBoxContainer/ResetScores
@onready var back_button := $Panel/VBoxContainer/Back

# Input Container
@onready var input_container := $Panel/VBoxContainer/InputContainer
@onready var initials_input := $Panel/VBoxContainer/InputContainer/Initials
@onready var submit_button := $Panel/VBoxContainer/InputContainer/SubmitButton
@onready var your_score_label := $Panel/VBoxContainer/InputContainer/YourScoreLabel

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	submit_button.pressed.connect(_on_submit_pressed)
	reset_score.pressed.connect(_on_reset_pressed)
	
	# Force UPPERCASE and length 3
	initials_input.text_changed.connect(func(new_text): 
		var processed_text = new_text.to_upper()
		
		# If longer than 3, cut it off immediately
		if processed_text.length() > 3:
			processed_text = processed_text.left(3)
		
		# Apply changes only if text is different (prevents infinite signal loops)
		if initials_input.text != processed_text:
			initials_input.text = processed_text
			initials_input.caret_column = 3 # Keep cursor at the end
	)
	
	check_status()

func check_status():
	var current_score = GameManager.score
	
	# 1. Check if we have a score AND it's a high score
	if current_score > 0 and GameManager.is_new_high_score(current_score):
		show_input_mode(current_score)
	else:
		show_display_mode()

func show_input_mode(score_val: int):
	# Show Input, Hide List
	input_container.show()
	score_container.hide()
	back_button.hide() # Force them to submit first
	
	your_score_label.text = "SCORE: %d" % score_val
	initials_input.text = ""
	initials_input.grab_focus()

func show_display_mode():
	# Show List, Hide Input
	input_container.hide()
	score_container.show()
	reset_score.show()
	back_button.show()
	
	display_scores()

func _on_submit_pressed():
	var name_text = initials_input.text
	
	# 1. Save the score
	GameManager.add_high_score(name_text, GameManager.score)
	
	# 2. Reset current score so we don't trigger this input loop again if we reload
	GameManager.score = 0 
	
	# 3. Switch to Display Mode
	show_display_mode()

func display_scores():
	# Clear old labels
	for child in score_container.get_children():
		child.queue_free()
	
	# CHANGED: Get only the top 10 from GameManager
	var top_10 = GameManager.get_leaderboard_scores()
	
	var rank = 1
	for entry in top_10:
		var row = HBoxContainer.new()
		
		# Rank
		var rank_lbl = Label.new()
		rank_lbl.text = "%d." % rank
		rank_lbl.custom_minimum_size.x = 40
		row.add_child(rank_lbl)
		
		# Name
		var name_lbl = Label.new()
		name_lbl.text = str(entry["name"])
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(name_lbl)
		
		# Score
		var score_lbl = Label.new()
		score_lbl.text = str(entry["score"])
		score_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(score_lbl)
		
		score_container.add_child(row)
		rank += 1

func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scenes/Start.tscn")

func _on_reset_pressed():
	# 1. Call the manager to wipe data
	GameManager.reset_high_scores()
	
	# 2. Refresh the display (it will now be empty)
	display_scores()
