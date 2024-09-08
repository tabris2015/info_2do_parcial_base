extends Piece

var special_activated = false

func special(position, all_pieces):
	if special_activated:
		return
	special_activated = true
	var column = position[1]
	var height = all_pieces.size()
	for row in height:
		all_pieces[row][column].dim()
		all_pieces[row][column].matched = true
		all_pieces[row][column].special(Vector2(row,column), all_pieces)
