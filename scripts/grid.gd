extends Node2D

# state machine
enum {WAIT, MOVE, TIME}
var state

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

#puntae
@onready var top_ui = get_parent().get_node("top_ui") 
var current_score = 0

#niveles
@onready var game_timer: Timer = $"../game_timer"
var game_time_limit = 60 
var current_count = 10
@export var time_limit: int = 60  
var remaining_time: float = 0.0 
var is_time_mode: bool = false  

# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
]

var rainbow = preload("res://scenes/rainbow.tscn")

var striped_pieces_horizontal = {
	"blue": preload("res://scenes/blue_piece_row.tscn"),
	"green": preload("res://scenes/green_piece_row.tscn"),
	"light_green": preload("res://scenes/light_green_row.tscn"),
	"pink": preload("res://scenes/pink_row.tscn"),
	"yellow": preload("res://scenes/yellow_row.tscn"),
	"orange": preload("res://scenes/orange_row.tscn"),
}

var striped_pieces_vertical = {
	"blue": preload("res://scenes/blue_piece_column.tscn"),
	"green": preload("res://scenes/green_piece_column.tscn"),
	"light_green": preload("res://scenes/light_green_column.tscn"),
	"pink": preload("res://scenes/pink_column.tscn"),
	"yellow": preload("res://scenes/yellow_column.tscn"),
	"orange": preload("res://scenes/orange_column.tscn"),
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

func _process(delta):
	if state == MOVE:
		touch_input()
	elif state == TIME:
		update_time(delta)

# Called when the node enters the scene tree for the first time.
func _ready():
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()
	setup_level()

func setup_level():
	if state == TIME:
		transition_to_time_mode()
	else:
		transition_to_moves_mode()

func end_level():
	game_timer.stop()  
	setup_level()

#esto no sirve
func transition_to_time_mode():
	state = TIME
	remaining_time = time_limit
	game_timer.start()  

func update_time(delta):
	remaining_time -= delta
	if remaining_time <= 0:
		remaining_time = 0
		game_over()   

#Esto funciona
func transition_to_moves_mode():
	state = MOVE
	start_moves_mode()  
	game_timer.stop()  

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
	if current_count > 0:
		state = WAIT
		store_info(first_piece, other_piece, Vector2(column, row), direction)
		all_pieces[column][row] = other_piece
		all_pieces[column + direction.x][row + direction.y] = first_piece
		#first_piece.position = grid_to_pixel(column + direction.x, row + direction.y)
		#other_piece.position = grid_to_pixel(column, row)
		first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
		other_piece.move(grid_to_pixel(column, row))
		if not move_checked:
			find_matches()
			decrement_moves()
	else :
		game_over()

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

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
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

func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				if (
					i <= width - 5 
					and 
					all_pieces[i + 1] != null and all_pieces[i + 2] != null 
					and all_pieces[i + 3] != null and all_pieces[i + 4] != null
					and 
					all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null 
					and all_pieces[i + 3][j] != null and all_pieces[i + 4][j] != null
					and 
					all_pieces[i + 1][j].color == current_color and all_pieces[i + 2][j].color == current_color and all_pieces[i + 3][j].color == current_color and all_pieces[i + 4][j].color == current_color
				):
					create_special_piece(i, j, current_color, true, true)
					
				
				if (
					j <= height - 5
					and 
					all_pieces[i][j + 1] != null and all_pieces[i][j + 2] != null
					and all_pieces[i][j + 3] != null and all_pieces[i][j + 4] != null
					and 
					all_pieces[i][j + 1].color == current_color and all_pieces[i][j + 2].color == current_color 
					and all_pieces[i][j + 3].color == current_color and all_pieces[i][j + 4].color == current_color
				):
					create_special_piece(i, j, current_color, false, true)
				if (
					i <= width - 4 
					and 
					all_pieces[i + 1] != null and all_pieces[i + 2] != null and all_pieces[i + 3] != null
					and 
					all_pieces[i + 1][j] != null and all_pieces[i + 2][j] != null and all_pieces[i + 3][j] != null
					and 
					all_pieces[i + 1][j].color == current_color and all_pieces[i + 2][j].color == current_color and all_pieces[i + 3][j].color == current_color
				):
					create_special_piece(i, j, current_color, true)
				if (
					j <= height - 4 
					and 
					all_pieces[i][j + 1] != null and all_pieces[i][j + 2] != null and all_pieces[i][j + 3] != null
					and 
					all_pieces[i][j + 1].color == current_color and all_pieces[i][j + 2].color == current_color and all_pieces[i][j + 3].color == current_color
				):
					create_special_piece(i, j, current_color, false)
				 #detect horizontal matches
				if (
					i > 0 and i < width -1 
					and 
					all_pieces[i - 1][j] != null and all_pieces[i + 1][j]
					and 
					all_pieces[i - 1][j].color == current_color and all_pieces[i + 1][j].color == current_color
				):
					all_pieces[i - 1][j].matched = true
					all_pieces[i - 1][j].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i + 1][j].matched = true
					all_pieces[i + 1][j].dim()
				# detect vertical matches
				if (
					j > 0 and j < height -1 
					and 
					all_pieces[i][j - 1] != null and all_pieces[i][j + 1]
					and 
					all_pieces[i][j - 1].color == current_color and all_pieces[i][j + 1].color == current_color
				):
					all_pieces[i][j - 1].matched = true
					all_pieces[i][j - 1].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i][j + 1].matched = true
					all_pieces[i][j + 1].dim()
					
	get_parent().get_node("destroy_timer").start()

	
func create_special_piece(column, row, color, is_horizontal, is_rainbow := false):
	var special_piece_scene = null
	if is_rainbow:
		special_piece_scene = rainbow
		update_score(15)
	else:
		if is_horizontal:
			special_piece_scene = striped_pieces_horizontal.get(color, null)
		else:
			special_piece_scene = striped_pieces_vertical.get(color, null)
		update_score(10)
	if special_piece_scene == null:
		return
	var special_piece = special_piece_scene.instantiate()
	if special_piece == null:
		return
	add_child(special_piece)
	special_piece.position = grid_to_pixel(column, row)
	all_pieces[column][row] = special_piece
	

func destroy_matched():
	var was_matched = false
	var points= 0
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
	points += 5
	move_checked = true
	if was_matched:
		update_score(points)
		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()

func update_score(points):
	current_score += points
	top_ui.score_label.text = str(current_score)
	if current_score == 10:
		state = WAIT
		print("You won!")

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				print(i, j)
				# look above
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
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

func start_moves_mode():
	current_count = 10
	top_ui.counter_label.text = str(current_count)
	state = MOVE  

func decrement_moves():
	current_count -= 1
	top_ui.counter_label.text = str(current_count) 
	if current_count <= 0:
		game_over()

func game_over():
	state = WAIT
	if is_time_mode:
		print("Time's up! Game over")
	else:
		print("No moves left. Game over")

func _on_collapse_timer_timeout():
	print("collapse")
	collapse_columns()

func _on_refill_timer_timeout() -> void:
	refill_columns()

func _on_destroy_timer_timeout() -> void:
	print("destroy")
	destroy_matched()

func _on_game_timer_timeout() -> void:
	if is_time_mode:
		end_level()
