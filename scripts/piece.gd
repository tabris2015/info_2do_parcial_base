extends Node2D
class_name Piece

@export var color: String
@onready var block = $Block

var matched = false
var frozen = false 
var frozen_turns = 0

var life = 1

	
func move(target):
	var move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_ELASTIC)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "position", target, 0.4)

func dim():
	$Sprite2D.modulate = Color(1, 1, 1, 0.5)
	
func special(postion, all_pieces):
	pass

func freeze(turns):
	frozen_turns = turns
	frozen = true
	$Block.visible = true

func unfreeze():
	frozen_turns = 0
	frozen = false
	$Block.visible = false

func harden():
	life += 1
	set_modulate(Color(0.7, 0.7, 0.7, 1) )

func is_destroyed():
	life -= 1
	if life == 0:
		return true
	else:
		$Sprite2D.modulate = Color(1, 1, 1, 1)
		set_modulate(Color(1, 1, 1, 1))
		return false

func is_frozen() -> bool:
	return frozen_turns > 0

func decrement_frozen_turn():
	if frozen_turns > 0:
		frozen_turns -= 1
		if frozen_turns == 0:
			unfreeze()
