extends Node2D

const BUBBLE_SCENE = preload("res://scenes/bubble.tscn")

@export var bubble_diameter: float = 85.0
@export var board_offset: Vector2 = Vector2(200, 150)

const MAX_COLUMNS: int = 8

var bubbles_container: Node2D
var grid: Array = []
var current_level_data: LevelData


func _ready() -> void:
	bubbles_container = get_node_or_null("Bubbles") as Node2D

	if bubbles_container == null:
		push_error("BubbleBoard: Bubbles node not found!")


# ==================================================
# LEVEL SETUP
# ==================================================

func setup_level(level_data: LevelData) -> void:
	current_level_data = level_data

	if bubbles_container == null:
		bubbles_container = get_node_or_null("Bubbles") as Node2D

	if bubbles_container == null:
		push_error("BubbleBoard: Bubbles container missing!")
		return

	clear_board()
	grid.clear()

	# Create the grid.
	for row in range(level_data.layout.size()):
		var new_row: Array = []

		for column in range(MAX_COLUMNS):
			new_row.append(null)

		grid.append(new_row)

	# Create level bubbles.
	for row in range(level_data.layout.size()):
		var row_data: String = level_data.layout[row]

		for column in range(row_data.length()):

			if column >= MAX_COLUMNS:
				continue

			var color_code: String = row_data[column]

			if color_code == ".":
				continue

			var bubble: Area2D = BUBBLE_SCENE.instantiate() as Area2D

			if bubble == null:
				continue

			bubbles_container.add_child(bubble)

			bubble.set_color(color_code)
			bubble.position = grid_to_position(row, column)

			grid[row][column] = bubble


# ==================================================
# GRID POSITION
# ==================================================

func grid_to_position(row: int, column: int) -> Vector2:
	var radius: float = bubble_diameter / 2.0

	var x: float = radius + column * bubble_diameter
	var y: float = radius + row * bubble_diameter * 0.866

	if row % 2 == 1:
		x += radius

	return Vector2(x, y) + board_offset


# ==================================================
# GET BUBBLES
# ==================================================

func get_bubbles() -> Array:
	if bubbles_container == null:
		return []

	return bubbles_container.get_children()


# ==================================================
# ATTACH TO HIT BUBBLE
# ==================================================

func attach_bubble(
	bubble: Area2D,
	hit_bubble: Area2D
) -> void:

	if bubble == null:
		return

	if hit_bubble == null:
		attach_to_top(bubble)
		return

	var hit_cell: Vector2i = find_bubble_cell(hit_bubble)

	if hit_cell.x < 0:
		attach_to_top(bubble)
		return

	# Find the empty neighbor that is closest
	# to the projectile's actual position.
	var best_cell: Vector2i = find_best_neighbor_cell(
		hit_cell.y,
		hit_cell.x,
		bubble.global_position
	)

	if best_cell.x < 0:
		return

	var row: int = best_cell.y
	var column: int = best_cell.x

	ensure_grid_row(row)

	grid[row][column] = bubble

	# Move bubble into board.
	var old_parent: Node = bubble.get_parent()

	if old_parent != bubbles_container:

		if old_parent != null:
			old_parent.remove_child(bubble)

		bubbles_container.add_child(bubble)

	# Snap exactly to the selected position.
	bubble.position = grid_to_position(row, column)

	check_matches(row, column)


# ==================================================
# FIND CELL OF EXISTING BUBBLE
# ==================================================

func find_bubble_cell(target: Area2D) -> Vector2i:

	for row in range(grid.size()):
		for column in range(MAX_COLUMNS):
			var bubble: Area2D = grid[row][column] as Area2D
			if bubble == target:
				return Vector2i(column, row)

	return Vector2i(-1, -1)


# ==================================================
# FIND BEST NEIGHBOR
# ==================================================

func find_best_neighbor_cell(
	row: int,
	column: int,
	world_position: Vector2
) -> Vector2i:

	var candidates: Array[Vector2i] = []

	for neighbor in get_neighbors(row, column):
		var neighbor_column: int = neighbor.x
		var neighbor_row: int = neighbor.y

		if neighbor_row < 0:
			continue

		if neighbor_column < 0:
			continue

		if neighbor_column >= MAX_COLUMNS:
			continue

		ensure_grid_row(neighbor_row)

		var existing: Area2D = grid[neighbor_row][neighbor_column] as Area2D

		if existing == null:
			candidates.append(Vector2i(neighbor_column, neighbor_row))

	if candidates.is_empty():
		return Vector2i(-1, -1)

	# Convert projectile position to board-local coordinates.
	var local_position: Vector2 = to_local(world_position)

	var best_cell: Vector2i = candidates[0]
	var best_distance: float = INF

	for candidate in candidates:
		var candidate_position: Vector2 = grid_to_position(candidate.y, candidate.x)
		var distance: float = local_position.distance_to(candidate_position)

		if distance < best_distance:
			best_distance = distance
			best_cell = candidate

	return best_cell


# ==================================================
# TOP ATTACHMENT
# ==================================================

func attach_to_top(bubble: Area2D) -> void:

	var local_position: Vector2 = to_local(bubble.global_position)

	ensure_grid_row(0)

	var best_column: int = -1
	var best_distance: float = INF

	for column in range(MAX_COLUMNS):
		var existing: Area2D = grid[0][column] as Area2D

		if existing != null:
			continue

		var position: Vector2 = grid_to_position(0, column)
		var distance: float = abs(local_position.x - position.x)

		if distance < best_distance:
			best_distance = distance
			best_column = column

	if best_column < 0:
		return

	grid[0][best_column] = bubble

	var old_parent: Node = bubble.get_parent()

	if old_parent != bubbles_container:
		if old_parent != null:
			old_parent.remove_child(bubble)
		bubbles_container.add_child(bubble)

	bubble.position = grid_to_position(0, best_column)
	check_matches(0, best_column)


# ==================================================
# GRID ROW
# ==================================================

func ensure_grid_row(row: int) -> void:
	while grid.size() <= row:
		var new_row: Array = []
		for column in range(MAX_COLUMNS):
			new_row.append(null)
		grid.append(new_row)


# ==================================================
# MATCH CHECK
# ==================================================

func check_matches(row: int, column: int) -> void:
	var matches: Array = find_matching_bubbles(row, column)

	if matches.size() >= 3:
		remove_matches(matches)


# ==================================================
# FIND MATCHES
# ==================================================

func find_matching_bubbles(
	start_row: int,
	start_column: int
) -> Array:

	var matches: Array = []

	if not is_valid_cell(start_row, start_column):
		return matches

	var start_bubble: Area2D = grid[start_row][start_column] as Area2D

	if start_bubble == null:
		return matches

	var target_color = start_bubble.color

	var queue: Array[Vector2i] = []
	var visited: Dictionary = {}

	queue.append(Vector2i(start_column, start_row))

	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		var key: String = str(cell.x) + "," + str(cell.y)

		if visited.has(key):
			continue

		visited[key] = true

		if not is_valid_cell(cell.y, cell.x):
			continue

		var bubble: Area2D = grid[cell.y][cell.x] as Area2D

		if bubble == null:
			continue

		if bubble.color != target_color:
			continue

		matches.append(bubble)

		for neighbor in get_neighbors(cell.y, cell.x):
			queue.append(neighbor as Vector2i)

	return matches


# ==================================================
# NEIGHBORS (FIXED)
# ==================================================

func get_neighbors(row: int, column: int) -> Array:
	var neighbors: Array = [
		Vector2i(column - 1, row),
		Vector2i(column + 1, row)
	]

	if row % 2 == 0:
		# Unshifted (even) rows connect to left-leaning diagonals
		neighbors.append(Vector2i(column - 1, row - 1))
		neighbors.append(Vector2i(column, row - 1))
		neighbors.append(Vector2i(column - 1, row + 1))
		neighbors.append(Vector2i(column, row + 1))
	else:
		# Shifted right (odd) rows connect to right-leaning diagonals
		neighbors.append(Vector2i(column, row - 1))
		neighbors.append(Vector2i(column + 1, row - 1))
		neighbors.append(Vector2i(column, row + 1))
		neighbors.append(Vector2i(column + 1, row + 1))

	return neighbors


# ==================================================
# VALID CELL
# ==================================================

func is_valid_cell(row: int, column: int) -> bool:
	if row < 0 or row >= grid.size():
		return false
	if column < 0 or column >= MAX_COLUMNS:
		return false
	return true


# ==================================================
# REMOVE MATCHES (FIXED)
# ==================================================

func remove_matches(matches: Array) -> void:
	GameManager.add_score(matches.size() * 10)

	# 1. Clear matched bubbles from the grid array immediately
	for bubble in matches:
		if not is_instance_valid(bubble):
			continue
		var cell: Vector2i = find_bubble_cell(bubble)
		if cell.x >= 0 and cell.y >= 0:
			grid[cell.y][cell.x] = null

	# 2. Burst animation for matches
	for bubble in matches:
		if not is_instance_valid(bubble):
			continue
		var tween: Tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(bubble, "scale", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_property(bubble, "modulate:a", 0.0, 0.18)
		tween.set_parallel(false)
		tween.tween_callback(bubble.queue_free)

	# 3. Find and drop disconnected/floating bubbles
	drop_floating_bubbles()

	await get_tree().create_timer(0.25).timeout
	check_win()


# ==================================================
# DROP FLOATING BUBBLES
# ==================================================

func drop_floating_bubbles() -> void:
	var connected: Dictionary = {}
	var queue: Array[Vector2i] = []

	# Seed with all bubbles in row 0
	if grid.size() > 0:
		for col in range(MAX_COLUMNS):
			if grid[0][col] != null:
				queue.append(Vector2i(col, 0))
				connected[Vector2i(col, 0)] = true

	# Flood-fill to find everything attached to the ceiling
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for n in get_neighbors(cell.y, cell.x):
			var n_vec: Vector2i = n as Vector2i
			if is_valid_cell(n_vec.y, n_vec.x) and not connected.has(n_vec):
				if grid[n_vec.y][n_vec.x] != null:
					connected[n_vec] = true
					queue.append(n_vec)

	# Any bubble on the board not in 'connected' is floating
	var drop_count: int = 0
	for r in range(grid.size()):
		for c in range(MAX_COLUMNS):
			var bubble: Area2D = grid[r][c] as Area2D
			if bubble != null and not connected.has(Vector2i(c, r)):
				grid[r][c] = null
				drop_count += 1
				_animate_drop(bubble)

	if drop_count > 0:
		GameManager.add_score(drop_count * 20)

func _animate_drop(bubble: Area2D) -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(bubble, "position:y", bubble.position.y + 600.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(bubble, "modulate:a", 0.0, 0.5)
	tween.set_parallel(false)
	tween.tween_callback(bubble.queue_free)


# ==================================================
# WIN
# ==================================================

func check_win() -> void:
	for row in range(grid.size()):
		for column in range(MAX_COLUMNS):
			var bubble: Area2D = grid[row][column] as Area2D
			if bubble != null:
				return
	print("LEVEL COMPLETE!")


# ==================================================
# CLEAR BOARD (FIXED)
# ==================================================

func clear_board() -> void:
	if bubbles_container == null:
		return

	for bubble in bubbles_container.get_children():
		bubble.queue_free()
