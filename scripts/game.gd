extends Control

@onready var level_manager: Node = $LevelManager
@onready var launcher: Node = $Launcher
@onready var bubble_board: Node = $BubbleBoard
@onready var back_button: TextureButton = $BackTextureButton

# Add a reference to your score label (adjust the node path if it is inside a container)
@onready var score_label: Label = $ScoreLabel


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	
	# Connect to the GameManager's signal
	GameManager.score_changed.connect(_update_score_ui)
	
	# Initialize the UI with the current score right away
	_update_score_ui(GameManager.score)


func _update_score_ui(new_score: int) -> void:
	if score_label != null:
		score_label.text = str(new_score)


func _on_back_pressed() -> void:
	GameManager.go_to_level_select()
