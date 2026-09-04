extends Control

@onready var next_button = $NextButton
@onready var home_button = $HomeButton
@onready var score_label = $ScoreLabel

const MAX_LEVELS: int = 3

func _ready() -> void:

	if score_label != null:
		score_label.text = "Score: " + str(GameManager.score)
	
	# 2. Connect the button signals
	if next_button != null:
		next_button.pressed.connect(_on_next_button_pressed)
		
	if home_button != null:
		home_button.pressed.connect(_on_home_button_pressed)


func _on_next_button_pressed() -> void:
	var next_level: int = GameManager.current_level + 1
	
	if next_level <= MAX_LEVELS:
		GameManager.start_level(next_level)
	else:
		GameManager.go_to_level_select()


func _on_home_button_pressed() -> void:
	GameManager.go_to_main_menu()
