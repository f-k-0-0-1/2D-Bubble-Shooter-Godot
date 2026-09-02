extends Node

@onready var bubble_board = $"../BubbleBoard"


func _ready() -> void:
	call_deferred("load_current_level")


func load_current_level() -> void:
	load_level(GameManager.current_level)


func load_level(level_number: int) -> void:
	var level_path := "res://levels/level_%d.tres" % level_number

	if not ResourceLoader.exists(level_path):
		push_error("Level does not exist: " + level_path)
		return

	var level_data = load(level_path) as LevelData

	if level_data == null:
		push_error("Failed to load level: " + level_path)
		return

	bubble_board.setup_level(level_data)
