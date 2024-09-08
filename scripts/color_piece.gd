extends Piece

var special_activated = false

func special(position, all_pieces):
	if special_activated:
		return
	special_activated = true
	print(position[0], " ", position[1], " ", all_pieces[position[0]][position[1]].color)
	for row in all_pieces.size():
		for column in all_pieces[0].size():
			if all_pieces[position[0]][position[1]].color == all_pieces[row][column].color:
				all_pieces[row][column].dim()
				all_pieces[row][column].matched = true
				all_pieces[row][column].special(Vector2(row,column), all_pieces)
			
