extends Node2D

# state machine
enum {WAIT, MOVE}
var state

enum {HORIZONTAL, VERTICAL}

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
]
var column_pieces = {
	"blue": preload("res://scenes/column_blue_piece.tscn"),
	"green": preload("res://scenes/column_green_piece.tscn"),
	"light_green": preload("res://scenes/column_light_green_piece.tscn"),
	"pink": preload("res://scenes/column_pink_piece.tscn"),
	"yellow": preload("res://scenes/column_yellow_piece.tscn"),
	"orange": preload("res://scenes/column_orange_piece.tscn")
}

var row_pieces = {
	"blue": preload("res://scenes/row_blue_piece.tscn"),
	"green": preload("res://scenes/row_green_piece.tscn"),
	"light_green": preload("res://scenes/row_light_green_piece.tscn"),
	"pink": preload("res://scenes/row_pink_piece.tscn"),
	"yellow": preload("res://scenes/row_yellow_piece.tscn"),
	"orange": preload("res://scenes/row_orange_piece.tscn")
}

var color_piece = {
	"blue": preload("res://scenes/color_blue_piece.tscn"),
	"green": preload("res://scenes/color_green_piece.tscn"),
	"light_green": preload("res://scenes/color_light_green_piece.tscn"),
	"pink": preload("res://scenes/color_pink_piece.tscn"),
	"yellow": preload("res://scenes/color_yellow_piece.tscn"),
	"orange": preload("res://scenes/color_orange_piece.tscn")	
}
# current pieces in scene
var all_pieces = []

# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false

# scoring variables and signals
var score = 0
signal score_changed(new_score)

# counter variables and signals
var minus_moves = 1
signal moves_left_changed(new_moves)

var just_moved = []
var groups = []



# Called when the node enters the scene tree for the first time.
func _ready():
	print("Nodo padre: ", get_parent().name)
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	just_moved = make_2d_array()
	spawn_pieces()

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
	
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height
	
func spawn_pieces():
	for i in width:
		for j in height:
			# random number
			var rand = randi_range(0, possible_pieces.size() - 1)
			# instance 
			var piece = possible_pieces[rand].instantiate()
			# repeat until no matches
			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			# fill array with pieces
			all_pieces[i][j] = piece

func match_at(i, j, color):
	# check left
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	# check down
	if j> 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true

func touch_input():
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true
		
	# release button
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)

func swap_pieces(column, row, direction: Vector2):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece == null or other_piece == null:
		return
	# swap
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	#first_piece.position = grid_to_pixel(column + direction.x, row + direction.y)
	#other_piece.position = grid_to_pixel(column, row)
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	
	if not move_checked:
		just_moved[column][row] = true
		just_moved[column + direction.x][row + direction.y] = true
		var isFind = find_matches()
		if isFind:
			# Restar una jugada
			emit_signal("moves_left_changed", minus_moves)

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = MOVE
	move_checked = false

func init_just_moved():
	for i in width:
		for j in height:
			just_moved[i][j] = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	
	init_just_moved()
	# should move x or y?
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(delta):
	if state == MOVE:
		touch_input()

func find_matches():
	groups = []
	var idGroup = make_2d_array()
	var matches_found = false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				# detect horizontal matches
				if (
					i > 0 and i < width -1 
					and 
					all_pieces[i - 1][j] != null and all_pieces[i + 1][j]
					and 
					all_pieces[i - 1][j].color == current_color and all_pieces[i + 1][j].color == current_color
				):
					var group = null
					if idGroup[i-1][j] != null:
						group=idGroup[i-1][j]
					if idGroup[i][j] != null:
						group=idGroup[i][j]
					if idGroup[i+1][j] != null:
						group=idGroup[i+1][j]	
					
					if(group == null):
						idGroup[i-1][j]=groups.size()
						idGroup[i][j]=groups.size()
						idGroup[i+1][j]=groups.size()
						group = groups.size()
						groups.append([])
							
					groups[group].append([Vector2(i,j), all_pieces[i][j].color, VERTICAL])
					groups[group].append([Vector2(i+1,j), all_pieces[i+1][j].color, VERTICAL])
					groups[group].append([Vector2(i-1,j), all_pieces[i-1][j].color, VERTICAL])
					
					all_pieces[i][j].special(Vector2(i,j), all_pieces)	
					all_pieces[i-1][j].special(Vector2(i-1,j), all_pieces)
					all_pieces[i+1][j].special(Vector2(i+1,j), all_pieces)
															
					
					all_pieces[i - 1][j].matched = true
					all_pieces[i - 1][j].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i + 1][j].matched = true
					all_pieces[i + 1][j].dim()
					score += 30 
					emit_signal("score_changed", score)
					matches_found = true
				# detect vertical matches
				if (
					j > 0 and j < height -1 
					and 
					all_pieces[i][j - 1] != null and all_pieces[i][j + 1]
					and 
					all_pieces[i][j - 1].color == current_color and all_pieces[i][j + 1].color == current_color
				):
					
					var group = null
					if idGroup[i][j-1] != null:
						group=idGroup[i][j-1]
					if idGroup[i][j] != null:
						group=idGroup[i][j]
					if idGroup[i][j+1] != null:
						group=idGroup[i][j+1]	
					
					if(group == null):
						idGroup[i][j-1]=groups.size()
						idGroup[i][j]=groups.size()
						idGroup[i][j+1]=groups.size()
						group = groups.size()
						groups.append([])
							
					groups[group].append([Vector2(i,j-1), all_pieces[i][j-1].color, HORIZONTAL])
					groups[group].append([Vector2(i,j), all_pieces[i][j].color, HORIZONTAL])
					groups[group].append([Vector2(i,j+1), all_pieces[i][j+1].color, HORIZONTAL])
					
					all_pieces[i][j].special(Vector2(i,j), all_pieces)
					all_pieces[i][j+1].special(Vector2(i,j+1), all_pieces)
					all_pieces[i][j-1].special(Vector2(i,j-1), all_pieces)
					
					all_pieces[i][j - 1].matched = true
					all_pieces[i][j - 1].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i][j + 1].matched = true
					all_pieces[i][j + 1].dim()
					score += 30 
					emit_signal("score_changed", score)
					matches_found = true
					
	get_parent().get_node("destroy_timer").start()

	return matches_found
	
		
func uniqueArray(array):
	var unique = []
	for item in array:
		if not unique.has(item):
			unique.append(item)
	return unique

func destroy_matched():
	var was_matched = false
	
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
				
	move_checked = true
	if was_matched:
		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()

func create_special(size, position, color, direction):
	var piece = null
	if(size == 4):
		if direction == VERTICAL:
			piece = row_pieces[color].instantiate()
		else:
			piece = column_pieces[color].instantiate()
	else:
		piece = color_piece[color].instantiate()
	
	add_child(piece)
	piece.position = grid_to_pixel(position[0], position[1] - y_offset)
	piece.move(grid_to_pixel(position[0], position[1]))
	
	all_pieces[position[0]][position[1]] = piece
	
func generate_special():
	for group in groups:
		group = uniqueArray(group)
		if group.size() >= 4:
			var special
			for piece in group:
				var x = piece[0][0]
				var y = piece[0][1]
				if just_moved[x][y]:
					special = piece
					break
			create_special(group.size(), special[0], special[1], special[2])
	groups = []

func collapse_columns():
	
	generate_special()
	
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				print(i, ", ", j)
				# look above
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						just_moved[i][j] = true
						break
	get_parent().get_node("refill_timer").start()

func refill_columns():
	
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# random number
				var rand = randi_range(0, possible_pieces.size() - 1)
				# instance 
				var piece = possible_pieces[rand].instantiate()
				# repeat until no matches
				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				# fill array with pieces
				all_pieces[i][j] = piece
				
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				get_parent().get_node("destroy_timer").start()
				return
	state = MOVE
	
	move_checked = false

func _on_destroy_timer_timeout():
	print("destroy")
	destroy_matched()

func _on_collapse_timer_timeout():
	print("collapse")
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()
	
func game_over():
	state = WAIT
	print("game over")
