extends Area2D

const GAME_OVER_SCENE = preload("res://scenes/game_over.tscn")

var is_game_over: bool = false


func _process(_delta: float) -> void:
	if is_game_over:
		return
		
	# Continuously check for any areas currently touching the deadline line
	var overlapping_areas: Array[Area2D] = get_overlapping_areas()
	
	for area in overlapping_areas:
		
		# Check if the colliding object is a bubble
		if area.has_method("get_color_code"):
			
			# FIXED PATH: Deadline -> Control -> Game -> BubbleBoard -> Bubbles
			var bubbles_container: Node = get_node_or_null("../../BubbleBoard/Bubbles")
			
			# If the bubble is officially attached to the board and touching the line
			if bubbles_container != null and area.get_parent() == bubbles_container:
				trigger_game_over()
				return


func trigger_game_over() -> void:
	is_game_over = true
	
	# Instantiate the Game Over UI
	var game_over_screen = GAME_OVER_SCENE.instantiate()
	
	# Add it to the current scene so it overlays the game
	get_tree().current_scene.add_child(game_over_screen)
	
	# Pause the game to stop bubbles from moving or shooting
	get_tree().paused = true
