extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label
var current_score = 0
var moves_left = 10
			
func _ready():
	var parent_node = get_parent()
	var grid = parent_node.get_node("grid")
	var success_score = grid.connect("score_changed", Callable(self, "_on_score_changed"))
	var success_moves = grid.connect("moves_left_changed", Callable(self, "_on_moves_left_changed"))
		
	score_label.text = str(current_score)
	counter_label.text = str(moves_left)
		
func _on_score_changed(new_score):
	print("Score changed to: ", new_score)
	current_score = new_score
	score_label.text = str(current_score)
		
func _on_moves_left_changed(new_moves):
	print("Moves left changed to: ", new_moves)
	moves_left = moves_left - new_moves
	counter_label.text = str(moves_left)
