extends Control

@onready var level_manager: Node = $LevelManager
@onready var launcher: Node = $Launcher
@onready var bubble_board: Node = $BubbleBoard
@onready var back_button: TextureButton = $BackTextureButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)


func _on_back_pressed() -> void:
	GameManager.go_to_level_select()
