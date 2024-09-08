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
	"orange": preload("res://scenes/color_orange_piece.tscn"),
}
var rainbow_piece = preload("res://scenes/rainbow_piece.tscn")	
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
var final_score = 0
signal score_changed(new_score)

# counter variables and signals
var moves_left = 10
signal moves_changed(new_moves)

# levels variables and signal to change levels
var current_level = 1
var target_score = 10 
var level_time = 30
var time_remaining = level_time
var time_passed = 0
signal level_changed(new_level)
signal time_remaining_changed(new_time)
signal game_over_signal()
signal current_level_signal()
	
#Called when the node enters the scene tree for the first time.
var minus_moves = 1
signal moves_left_changed(new_moves)

var just_moved = []
var groups = []

#Freezing probability %
var freeze_probability = 10
var harden_probability = 10

# Called when the node enters the scene tree for the first time.
func _ready():
	print("Nodo padre: ", get_parent().name)
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	just_moved = make_2d_array()
	spawn_pieces()
	emit_signal("moves_changed", moves_left)
	start_level_timer()
	call_deferred("emit_signal", "current_level_signal", current_level)
	
	
func _process(delta):
	if state == MOVE:
		touch_input()
	
	# Update the timer
	time_passed += delta
	if time_passed >= 1:
		time_remaining -= 1
		emit_signal("time_remaining_changed", time_remaining)
		time_passed = 0

		if time_remaining <= 0:
			check_end_of_level()
			
func start_level_timer():
	var timer_label = get_parent().get_node("top_ui/MarginContainer/HBoxContainer/timer_label")
	if timer_label:
		timer_label.text = str(time_remaining) 
	
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
			
			var should_freeze = randi_range(0, 100) < freeze_probability
			if should_freeze:
				piece.freeze(randi_range(2, 3))
				
			var should_harden = randi_range(0, 100) < harden_probability
			if should_harden:
				piece.harden()
				
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
	if first_piece.is_frozen() or other_piece.is_frozen():
		print("No se puede mover una ficha congelada!")
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
	
	if first_piece.color == "multicolor" || other_piece.color == "multicolor":
		other_piece.special(Vector2(column + direction.x, row + direction.y), all_pieces)		
		first_piece.special(Vector2(column, row), all_pieces)
			
		first_piece.dim()
		first_piece.matched = true
		other_piece.dim()
		other_piece.matched = true
		
	if not move_checked:
		just_moved[column][row] = true
		just_moved[column + direction.x][row + direction.y] = true
		var isFind = find_matches()
		if isFind:
			moves_left -= 1
			emit_signal("moves_changed", moves_left)
			decrement_frozen_turns()
			check_end_of_level()
			

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

#func _process(delta):
	#if state == MOVE:
		#touch_input()

func find_matches():
	groups = []
	var idGroup = make_2d_array()
	var matches_found = false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and not all_pieces[i][j].frozen:
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
	
	var count_matched = 0
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				count_matched += 1
				if all_pieces[i][j].is_destroyed():
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
				else:
					all_pieces[i][j].matched = false
				
	score += count_matched * 10 
	final_score += count_matched * 10
	emit_signal("score_changed", score)
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
		var rainbow = randi_range(0,1)
		if rainbow == 1:
			piece = rainbow_piece.instantiate()
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
			var special = group[0]
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
				
				var should_freeze = randi_range(0, 100) < freeze_probability
				if should_freeze:
					piece.freeze(randi_range(2, 3))
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
	#decrement_frozen_turns()
	state = MOVE
	
	move_checked = false
	
func decrement_frozen_turns():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				all_pieces[i][j].decrement_frozen_turn()
				
func _on_destroy_timer_timeout():
	print("destroy")
	destroy_matched()

func _on_collapse_timer_timeout():
	print("collapse")
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()
	
#func _on_level_timer_timeout():
	#time_remaining -= 1
	#emit_signal("time_remaining_changed", time_remaining)
	#if time_remaining <= 0:
		#check_end_of_level()
		
func check_end_of_level():
	if score >= target_score and (moves_left <= 0 or time_remaining <= 0):
		advance_to_next_level()
	elif moves_left <= 0 or time_remaining <= 0:
		game_over()
		
func advance_to_next_level():
	current_level += 1
	target_score += 100
	level_time += 10  
	emit_signal("level_changed", current_level) 
	reset_level()
	
func reset_level():
	score = 0
	time_remaining = level_time
	reset_moves()
	emit_signal("score_changed", score)
	emit_signal("time_remaining_changed", time_remaining)
	emit_signal("current_level_signal", current_level)
	reset_moves()
	reset_board()
	start_level_timer()
	
func reset_board():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
	# Generate new pieces
	spawn_pieces()
	
func reset_moves():
	moves_left = 10 + 2 * (current_level - 1)
	emit_signal("moves_changed", moves_left)
	
func game_over():
	state = WAIT
	print("game over")
	get_tree().paused = true
	
	#Final score and current levell
	emit_signal("game_over_signal", final_score, current_level)
