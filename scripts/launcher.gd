extends Control

const BUBBLE_SCENE = preload("res://scenes/bubble.tscn")

@export var shoot_speed: float = 900.0

# ---------------------------------------------------------
# PLAY AREA
# ---------------------------------------------------------

@export var wall_left: float = 32.0
@export var wall_right: float = 688.0
@export var top_limit: float = 80.0

# Distance at which the shooting bubble is considered
# to have collided with another bubble.
@export var collision_distance: float = 78.0

# Maximum length of the predicted trajectory.
@export var aim_max_distance: float = 1600.0


# ---------------------------------------------------------
# NODES
# ---------------------------------------------------------

@onready var spawn_point: Marker2D = $BubbleSpawnPoint
@onready var aim_guide: Line2D = $AimGuide


# ---------------------------------------------------------
# STATE
# ---------------------------------------------------------

var current_bubble: Area2D = null
var shooting_bubble: Area2D = null

var aim_direction: Vector2 = Vector2.UP

var shooting: bool = false

# True while the player is holding the screen/mouse.
var touch_aiming: bool = false

# Current finger position.
var touch_position: Vector2 = Vector2.ZERO


# =========================================================
# READY
# =========================================================

func _ready() -> void:
	call_deferred("create_next_bubble")
	update_aim_guide()


# =========================================================
# PROCESS
# =========================================================

func _process(delta: float) -> void:
	if shooting:
		move_shooting_bubble(delta)
	else:
		# Android touch aiming
		if touch_aiming:
			update_aim_from_position(touch_position)
		# Mouse aiming when testing on PC
		else:
			update_aim()

		update_aim_guide()


# =========================================================
# INPUT (FIXED for Screen Transform)
# =========================================================

func _input(event: InputEvent) -> void:

	# -----------------------------------------------------
	# ANDROID TOUCH
	# -----------------------------------------------------
	if event is InputEventScreenTouch:
		if event.pressed:
			if not shooting:
				touch_aiming = true
				touch_position = get_canvas_transform().affine_inverse() * event.position
				update_aim_from_position(touch_position)
				update_aim_guide()
		else:
			if touch_aiming:
				touch_aiming = false
				if not shooting:
					shoot()

	# -----------------------------------------------------
	# ANDROID FINGER DRAG
	# -----------------------------------------------------
	elif event is InputEventScreenDrag:
		if not shooting and touch_aiming:
			touch_position = get_canvas_transform().affine_inverse() * event.position
			update_aim_from_position(touch_position)
			update_aim_guide()

	# -----------------------------------------------------
	# MOUSE - PC TESTING
	# -----------------------------------------------------
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if not shooting:
					touch_aiming = true
					update_aim()
					update_aim_guide()
			else:
				if touch_aiming:
					touch_aiming = false
					if not shooting:
						shoot()

	# -----------------------------------------------------
	# MOUSE MOVEMENT
	# -----------------------------------------------------
	elif event is InputEventMouseMotion:
		if not shooting and touch_aiming:
			update_aim()
			update_aim_guide()


# =========================================================
# AIMING
# =========================================================

func update_aim() -> void:
	if spawn_point == null:
		return
	var mouse_position: Vector2 = get_global_mouse_position()
	update_aim_from_position(mouse_position)


func update_aim_from_position(target_position: Vector2) -> void:
	if spawn_point == null:
		return

	var start_position: Vector2 = spawn_point.global_position
	var direction: Vector2 = target_position - start_position

	if direction.length_squared() <= 0.001:
		return

	direction = direction.normalized()

	# Prevent downward aiming
	if direction.y > -0.1:
		direction.y = -0.1
		direction = direction.normalized()

	aim_direction = direction


# =========================================================
# AIM GUIDE
# =========================================================

func update_aim_guide() -> void:
	if aim_guide == null or spawn_point == null:
		return

	var start_position: Vector2 = spawn_point.global_position
	var current_position: Vector2 = start_position
	var direction: Vector2 = aim_direction.normalized()
	var remaining_distance: float = aim_max_distance

	var points: Array[Vector2] = []
	points.append(aim_guide.to_local(current_position))

	# Trace Trajectory
	while remaining_distance > 0.0:
		var wall_distance: float = INF
		var top_distance: float = INF
		var bubble_distance: float = INF

		var collision_type: String = "end"

		# Left Wall
		if direction.x < 0.0:
			var distance_to_left: float = (wall_left - current_position.x) / direction.x
			if distance_to_left >= 0.0:
				wall_distance = distance_to_left

		# Right Wall
		elif direction.x > 0.0:
			var distance_to_right: float = (wall_right - current_position.x) / direction.x
			if distance_to_right >= 0.0:
				wall_distance = distance_to_right

		# Top
		if direction.y < 0.0:
			var distance_to_top: float = (top_limit - current_position.y) / direction.y
			if distance_to_top >= 0.0:
				top_distance = distance_to_top

		# Bubble
		var bubble_hit: Dictionary = find_first_bubble_on_path(current_position, direction, remaining_distance)
		if not bubble_hit.is_empty():
			bubble_distance = bubble_hit["distance"]

		# Find First Collision
		var travel_distance: float = remaining_distance

		if wall_distance < travel_distance:
			travel_distance = wall_distance
			collision_type = "wall"

		if top_distance < travel_distance:
			travel_distance = top_distance
			collision_type = "top"

		if bubble_distance < travel_distance:
			travel_distance = bubble_distance
			collision_type = "bubble"

		if travel_distance <= 0.01:
			break

		# Move to collision
		current_position += direction * travel_distance
		points.append(aim_guide.to_local(current_position))
		remaining_distance -= travel_distance

		if collision_type == "bubble" or collision_type == "top":
			break

		if collision_type == "wall":
			direction.x *= -1.0
			current_position += direction * 0.5
			continue

		break

	aim_guide.points = PackedVector2Array(points)


# =========================================================
# FIND FIRST BUBBLE ON TRAJECTORY
# =========================================================

func find_first_bubble_on_path(origin: Vector2, direction: Vector2, max_distance: float) -> Dictionary:
	var bubble_board: Node = get_node_or_null("../BubbleBoard")
	if bubble_board == null:
		return {}

	var bubbles: Array = bubble_board.get_bubbles()
	var closest_distance: float = max_distance
	var closest_bubble: Area2D = null

	for bubble_variant in bubbles:
		var bubble: Area2D = bubble_variant as Area2D

		if bubble == null or bubble == shooting_bubble:
			continue

		var bubble_position: Vector2 = bubble.global_position
		var relative_position: Vector2 = bubble_position - origin
		var projection: float = relative_position.dot(direction)

		if projection < 0.0 or projection > max_distance:
			continue

		var closest_point: Vector2 = origin + direction * projection
		var perpendicular_distance: float = bubble_position.distance_to(closest_point)

		if perpendicular_distance > collision_distance:
			continue

		var offset: float = sqrt(
			max(0.0, collision_distance * collision_distance - perpendicular_distance * perpendicular_distance)
		)

		var collision_distance_along_ray: float = projection - offset
		if collision_distance_along_ray < 0.0:
			collision_distance_along_ray = projection

		if collision_distance_along_ray < closest_distance:
			closest_distance = collision_distance_along_ray
			closest_bubble = bubble

	if closest_bubble == null:
		return {}

	return {
		"distance": closest_distance,
		"bubble": closest_bubble
	}


# =========================================================
# CREATE NEXT BUBBLE
# =========================================================

func create_next_bubble() -> void:
	if current_bubble != null:
		return

	var bubble: Area2D = BUBBLE_SCENE.instantiate() as Area2D
	if bubble == null:
		push_error("Launcher: Failed to create bubble.")
		return

	var projectiles: Node = get_node_or_null("../Projectiles")
	if projectiles == null:
		push_error("Launcher: Projectiles node not found.")
		bubble.queue_free()
		return

	projectiles.add_child(bubble)
	bubble.global_position = spawn_point.global_position
	bubble.set_color(get_random_color())
	current_bubble = bubble


# =========================================================
# RANDOM BUBBLE COLOR
# =========================================================

func get_random_color() -> String:
	var colors: Array[String] = ["R", "B", "G", "Y"]
	if GameManager.current_level >= 3:
		colors.append("P")
	return colors.pick_random()


# =========================================================
# SHOOT
# =========================================================

func shoot() -> void:
	if current_bubble == null or shooting:
		return

	shooting = true
	shooting_bubble = current_bubble
	current_bubble = null
	shooting_bubble.set_meta("is_shot", true)


# =========================================================
# MOVE SHOOTING BUBBLE (FIXED with Substeps)
# =========================================================

func move_shooting_bubble(delta: float) -> void:
	if shooting_bubble == null:
		shooting = false
		return

	var total_dist: float = shoot_speed * delta
	var step_size: float = 20.0
	var steps: int = ceil(total_dist / step_size)
	var per_step: float = total_dist / steps

	for i in range(steps):
		# Move bubble.
		shooting_bubble.global_position += aim_direction * per_step

		# Left Wall
		if shooting_bubble.global_position.x <= wall_left:
			shooting_bubble.global_position.x = wall_left
			aim_direction.x = abs(aim_direction.x)

		# Right Wall
		elif shooting_bubble.global_position.x >= wall_right:
			shooting_bubble.global_position.x = wall_right
			aim_direction.x = -abs(aim_direction.x)

		# Bubble Collision
		if check_bubble_collision():
			return

		# Top
		if shooting_bubble.global_position.y <= top_limit:
			attach_bubble()
			return


# =========================================================
# CHECK BUBBLE COLLISION (FIXED fading bubbles)
# =========================================================

func check_bubble_collision() -> bool:
	var bubble_board: Node = get_node_or_null("../BubbleBoard")

	if bubble_board == null or shooting_bubble == null:
		return false

	var bubbles: Array = bubble_board.get_bubbles()

	for bubble_variant in bubbles:
		var bubble: Area2D = bubble_variant as Area2D

		if bubble == null or bubble == shooting_bubble:
			continue

		# Ignore dying/fading bubbles
		if not bubble.is_visible_in_tree() or bubble.scale.x < 0.8:
			continue

		var distance: float = shooting_bubble.global_position.distance_to(bubble.global_position)

		if distance <= collision_distance:
			attach_bubble(bubble)
			return true

	return false


# =========================================================
# ATTACH BUBBLE
# =========================================================

func attach_bubble(hit_bubble: Area2D = null) -> void:
	if shooting_bubble == null:
		return

	var bubble: Area2D = shooting_bubble
	shooting_bubble = null
	shooting = false

	var bubble_board: Node = get_node_or_null("../BubbleBoard")

	if bubble_board == null:
		bubble.queue_free()
		call_deferred("create_next_bubble")
		return

	if hit_bubble != null:
		bubble_board.attach_bubble(bubble, hit_bubble)
	else:
		bubble_board.attach_bubble(bubble, null)

	call_deferred("create_next_bubble")
