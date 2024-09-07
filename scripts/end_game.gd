extends MarginContainer

@onready var final_score_label = $HBoxContainer/score_label
@onready var level_label = $HBoxContainer/level_label

func _ready() -> void:
	var parent_node = get_parent()
	var grid = parent_node.get_node("grid")
	grid.connect("game_over_signal", Callable(self, "_on_game_over_signal"))
	grid.connect("current_level_signal", Callable(self, "_on_current_level_signal"))

func _on_game_over_signal(final_score: int, current_level: int):
	final_score_label.text = "Puntaje total: " + str(final_score)
	level_label.text = "Nivel: " + str(current_level)

func _on_current_level_signal(current_level:int):
	level_label.text = "Nivel: " + str(current_level)
