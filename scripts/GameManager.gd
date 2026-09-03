extends Node

signal score_changed(new_score: int)

const MAIN_MENU_SCENE = preload("res://scenes/main_menu.tscn")
const LEVEL_SELECT_SCENE = preload("res://scenes/level_select.tscn")
const GAME_SCENE = preload("res://scenes/game.tscn")

var current_level: int = 1
var score: int = 0


func go_to_main_menu() -> void:
	get_tree().change_scene_to_packed(MAIN_MENU_SCENE)


func go_to_level_select() -> void:
	get_tree().change_scene_to_packed(LEVEL_SELECT_SCENE)


func start_level(level: int) -> void:
	current_level = level
	score = 0
	score_changed.emit(score)
	get_tree().change_scene_to_packed(GAME_SCENE)


func restart_level() -> void:
	score = 0
	score_changed.emit(score)
	get_tree().change_scene_to_packed(GAME_SCENE)


func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)
