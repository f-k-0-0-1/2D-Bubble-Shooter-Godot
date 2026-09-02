extends Control


func _on_play_button_pressed() -> void:
	GameManager.go_to_level_select()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
