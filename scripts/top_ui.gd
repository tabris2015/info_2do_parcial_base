extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label
@onready var time_label = $MarginContainer/HBoxContainer/timer_label 

var moves_left = 0
var current_score = 0
var time_remaining = 0
var current_level = 1
			
func _ready():
	var parent_node = get_parent()
	var grid = parent_node.get_node("grid")
	grid.connect("score_changed", Callable(self, "_on_score_changed"))
	grid.connect("moves_changed", Callable(self, "_on_moves_changed"))
	grid.connect("time_remaining_changed", Callable(self, "_on_time_remaining_changed"))
	grid.connect("level_changed", Callable(self, "_on_level_changed"))
	grid.connect("game_over_signal", Callable(self, "_on_game_over"))
	
	score_label.text = str(current_score)
	counter_label.text = str(moves_left)
	time_label.text = str(time_remaining)
		
func _on_score_changed(new_score):
	print("Score changed to: ", new_score)
	current_score = new_score
	score_label.text = str(current_score)
		
func _on_moves_changed(new_moves):
	print("Moves left changed to: ", new_moves)
	moves_left = new_moves
	counter_label.text = str(moves_left)
	
func _on_time_remaining_changed(new_time):
	print("Time remaining: ", new_time)
	time_remaining = new_time
	time_label.text = str(time_remaining)

func _on_level_changed(new_level):
	print("Level changed to: ", new_level)
	current_level = new_level

func _on_game_over():
	print("Game Over")
