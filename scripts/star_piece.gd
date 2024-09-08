extends Piece

var special_activated = false

func special(position, all_pieces):
	if special_activated:
		return
	special_activated = true
	var row = position[0]
	var column = position[1]
	var width = all_pieces[0].size()
	var height = all_pieces.size()
	for j in width:
		all_pieces[row][j].dim()
		all_pieces[row][j].matched = true
		all_pieces[row][j].special(Vector2(row,j), all_pieces)
	
	for i in height: 
		all_pieces[i][column].dim()
		all_pieces[i][column].matched = true
		all_pieces[i][column].special(Vector2(i, column), all_pieces)
		
