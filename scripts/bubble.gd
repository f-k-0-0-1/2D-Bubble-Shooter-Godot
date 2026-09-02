extends Area2D

enum BubbleColor {
	RED,
	BLUE,
	GREEN,
	YELLOW,
	PURPLE
}

const RED_TEXTURE = preload("res://assets/bubbles/red.png")
const BLUE_TEXTURE = preload("res://assets/bubbles/blue.png")
const GREEN_TEXTURE = preload("res://assets/bubbles/green.png")
const YELLOW_TEXTURE = preload("res://assets/bubbles/yellow.png")
const PURPLE_TEXTURE = preload("res://assets/bubbles/purple.png")

var color: BubbleColor


func set_color(color_code: String) -> void:
	match color_code:
		"R":
			color = BubbleColor.RED
			$Sprite2D.texture = RED_TEXTURE

		"B":
			color = BubbleColor.BLUE
			$Sprite2D.texture = BLUE_TEXTURE

		"G":
			color = BubbleColor.GREEN
			$Sprite2D.texture = GREEN_TEXTURE

		"Y":
			color = BubbleColor.YELLOW
			$Sprite2D.texture = YELLOW_TEXTURE

		"P":
			color = BubbleColor.PURPLE
			$Sprite2D.texture = PURPLE_TEXTURE

		_:
			push_error("Unknown bubble color: " + color_code)


func get_color_code() -> String:
	match color:
		BubbleColor.RED:
			return "R"
		BubbleColor.BLUE:
			return "B"
		BubbleColor.GREEN:
			return "G"
		BubbleColor.YELLOW:
			return "Y"
		BubbleColor.PURPLE:
			return "P"

	return ""
