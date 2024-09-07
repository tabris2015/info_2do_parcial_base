extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label

var current_score = 0
var current_count = 0

func show_time(time: float):
	$TimeLabel.text = str(time) + "s" 

func update_time(time: float):
	$TimeLabel.text = str(round(time)) + "s"
