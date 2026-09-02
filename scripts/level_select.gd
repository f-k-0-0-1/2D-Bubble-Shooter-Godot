extends Control

@onready var back_button: TextureButton = $BackTextureButton
@onready var levels_container: GridContainer = $Levels/GridContainer


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)

	for i in range(12):
		var level_button: TextureButton = levels_container.get_child(i)
		
		if i < 3:
			level_button.disabled = false
			level_button.pressed.connect(_on_level_pressed.bind(i + 1))
		else:
			level_button.disabled = true


func _on_level_pressed(level: int) -> void:
	GameManager.start_level(level)


func _on_back_pressed() -> void:
	GameManager.go_to_main_menu()
