extends Node2D

@export var color: String

var is_special_piece: bool = false
var is_horizontal: bool = false
var is_rainbow:bool = false
var matched = false

func move(target):
	var move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_ELASTIC)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "position", target, 0.4)

func dim():
	$Sprite2D.modulate = Color(1, 1, 1, 0.5)

func set_horizontal(value):
	is_horizontal = value

func set_rainbow(value):
	is_rainbow = value
