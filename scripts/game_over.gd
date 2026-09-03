extends Control

@onready var retry_button = $RetryButton
@onready var home_button = $HomeButton
# Note: ScoreLabel is a child of the Control node in your scene tree
@onready var score_label = $ScoreLabel

func _ready() -> void:
	# 1. Allow this UI to process clicks even when the game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 2. Update the score label with the final score[cite: 5]
	if score_label != null:
		score_label.text = "Score: " + str(GameManager.score)
		
	# 3. Connect the button signals
	if retry_button != null:
		retry_button.pressed.connect(_on_retry_pressed)
		
	if home_button != null:
		home_button.pressed.connect(_on_home_pressed)


func _on_retry_pressed() -> void:
	# Crucial: Unpause the game tree before loading the new scene
	get_tree().paused = false 
	GameManager.restart_level() #[cite: 5]


func _on_home_pressed() -> void:
	# Crucial: Unpause the game tree before leaving
	get_tree().paused = false 
	GameManager.go_to_main_menu() #[cite: 5]
