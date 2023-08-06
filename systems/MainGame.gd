extends Node2D

# Missing rules
# En Passant
# Promotion

var Piece = preload("res://entities/piece.tscn")
var TileMarker = preload("res://entities/tile_marker.tscn")

var board_enabled : bool = true
var hide_overlay : bool = false
var board : Board
var markers : Array = []
var half_moves : int = 0
var full_moves : int = 1
var move_list_moves : int = 0
var move_generator : MoveGenerator
var start_turn_time : int = -1
var clock_times : Array[int] = [60 * 10, 60 * 10]

var selected_tile : Coord
var selected_piece : Piece

# Called when the node enters the scene tree for the first time.
func _ready():
	move_generator = MoveGenerator.new()
	board = Board.new()
	
	for r in range(0, Constants.BOARD_WIDTH_IN_TILES):
		markers.append([])
		for c in range(0, Constants.BOARD_HEIGHT_IN_TILES):
			var tileMarker = TileMarker.instantiate()
			print("tile Marker: " + str(tileMarker.get_instance_id()))
			tileMarker.position.x = c * Constants.TILE_WIDTH
			tileMarker.position.y = r * Constants.TILE_HEIGHT
			tileMarker.visible = false
			$Board/Tiles/Markers.add_child(tileMarker)
			markers[r].append(tileMarker)
	
	board.set_player_turn(Globals.PieceColor.WHITE)
	update_clock(Globals.PieceColor.WHITE, false)
	update_clock(Globals.PieceColor.BLACK, false)
	
	$UI/Clock/WhiteTurnMarker.set_color(Globals.WHITE_COLOR)
	$UI/Clock/BlackTurnMarker.set_color(Globals.BLACK_COLOR)
	
	initialize_from_fen("kq6/4PPP1/8/3R4/8/5Q2/8/7K b KQkq - 1 2")
	# initialize_from_fen("rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("click"):
		
		# To avoid spurious clicks being processed, make this a 3-state transition
		if hide_overlay:
			board_enabled = true
			hide_overlay = false
			return
		
		var position = get_viewport().get_mouse_position()
		
		# Check to see if the click is within the board
		var pixel_board_width = Constants.TILE_WIDTH * Constants.BOARD_WIDTH_IN_TILES
		var pixel_board_height = Constants.TILE_HEIGHT * Constants.BOARD_HEIGHT_IN_TILES
		
		var bounding_rectangle = Rect2($Board/Tiles.global_position.x, $Board/Tiles.global_position.y, pixel_board_width, pixel_board_height)
		if bounding_rectangle.has_point(position):
			handle_click(bounding_rectangle, position)

	if board_enabled:
		var ran_out_of_time = update_clock(board.get_player_turn(), false)
		if ran_out_of_time:
			board_enabled = false
			# If we run out of time, the other player wins
			add_score_to_move_list(Globals.get_opposite_color(board.get_player_turn()))
			$UI/Clock/WhiteTurnMarker.visible = false
			$UI/Clock/BlackTurnMarker.visible = false
			$Board/Control/GameOverContainer.visible = true

func start_game():
	board.set_player_turn(Globals.PieceColor.WHITE)
	reset_clock()
	update_clock(Globals.PieceColor.WHITE, false)
	update_clock(Globals.PieceColor.BLACK, false)
	reset_half_moves()
	reset_full_moves()
	reset_markers()
	board.reset_in_check()
	board.reset_castling_permission()
	reset_move_list()
	$UI/Clock/WhiteTurnMarker.visible = true
	$UI/Clock/BlackTurnMarker.visible = false
	$Board/Control/GameOverContainer.visible = false
	board_enabled = true

#func get_turn():
#	return player_turn

func add_checkmate_to_move_list():
	var idx = $UI/MoveList.add_item("#")
	$UI/MoveList.set_item_disabled(idx, true)

func add_score_to_move_list(white_wins):
	if white_wins:
		var idx = $UI/MoveList.add_item("1-0")
		$UI/MoveList.set_item_disabled(idx, true)
		
	else:
		var idx = $UI/MoveList.add_item("0-1")
		$UI/MoveList.set_item_disabled(idx, true)

func reset_clock():
	start_turn_time = -1
	clock_times = [60 * 10, 60 * 10]

func update_clock(clock_color, turn_over):
	var current_time = Time.get_ticks_usec()
	var ran_out_of_time = false
	
	# We don't start counting until a turn is taken
	var current_remaining_time = clock_times[clock_color]
	if start_turn_time != -1:
		var elapsed_time = current_time - start_turn_time
		current_remaining_time = clock_times[clock_color] - (elapsed_time / 1000000)
		if current_remaining_time < 0:
			current_remaining_time = 0
			ran_out_of_time = true
			
		if turn_over:
			clock_times[clock_color] = current_remaining_time
		
	var minute = (int)(current_remaining_time / 60)
	var second = (int)(current_remaining_time % 60)
	var time = "%02d:%02d" % [minute, second]
	if clock_color == Globals.PieceColor.WHITE:
		$UI/Clock/WhiteClock.text = time
	else:
		$UI/Clock/BlackClock.text = time

	return ran_out_of_time

func flip_turn():
	if board.is_checkmate(move_generator):
		board_enabled = false
		add_checkmate_to_move_list()
		add_score_to_move_list(true)
		$Board/Control/GameOver.visible = true
	else:
		if board.get_player_turn() == Globals.PieceColor.WHITE:
			board.set_player_turn(Globals.PieceColor.BLACK)
			$UI/Clock/WhiteTurnMarker.visible = false
			$UI/Clock/BlackTurnMarker.visible = true
		else:
			full_moves = full_moves + 1
			board.set_player_turn(Globals.PieceColor.WHITE)
			$UI/Clock/WhiteTurnMarker.visible = true
			$UI/Clock/BlackTurnMarker.visible = false

		half_moves = half_moves + 1
		start_turn_time = Time.get_ticks_usec()

func reset_half_moves():
	half_moves = 0

func reset_full_moves():
	full_moves = 1

func reset_markers():
	for row in markers:
		for marker in row:
			marker.visible = false

func reset_move_list():
	$UI/MoveList.clear()
	move_list_moves = 0

func update_markers(valid_moves):
	reset_markers()
	
	if selected_tile != null:
		markers[selected_tile.get_row()][selected_tile.get_col()].set_color(Color.BLUE)
		markers[selected_tile.get_row()][selected_tile.get_col()].visible = true
	
	if valid_moves != null:
		for item in valid_moves:
			var move_type = item[0]
			var valid_move = item[1]
			var color = Color.GREEN
			
			if move_type == MoveGenerator.MoveType.ATTACK:
				color = Color.RED
			elif move_type == MoveGenerator.MoveType.NORMAL_OR_ATTACK:
				var destination_piece = board.get_coord(valid_move)
				if destination_piece != null:
					if destination_piece.get_color() == Globals.get_opposite_color(board.get_player_turn()):
						color = Color.ORANGE_RED
					else:
						# This is our own piece, we can't move here
						continue

			markers[valid_move.get_row()][valid_move.get_col()].set_color(color)
			markers[valid_move.get_row()][valid_move.get_col()].visible = true

# Note: Does not do en passant, move disambiguation, or promotion
# Reference: https://en.wikipedia.org/wiki/Algebraic_notation_(chess)
func add_move_to_move_list(piece : Piece, source : Coord, dest : Coord, capture : bool, placed_in_check : bool, castling_side : Globals.CastlingSide):
	
	var final_string = str(move_list_moves) + ": "
	move_list_moves = move_list_moves + 1
	if capture:
		var piece_as_string = piece.to_string()
		if piece_as_string == "":
			final_string += source.get_file().to_lower() + "x" + dest.to_string()
		else:
			final_string += piece_as_string + "x" + dest.to_string()
	else:
		if castling_side == Globals.CastlingSide.NONE:
			final_string += piece.to_string() + dest.to_string()
		elif castling_side == Globals.CastlingSide.KING:
			final_string += "0-0"
		else:
			final_string += "0-0-0"
		
	if placed_in_check:
		final_string += "+"

	var idx = $UI/MoveList.add_item(final_string)
	$UI/MoveList.set_item_disabled(idx, true)

func handle_click(boundingRectangle, pos):

	if not board_enabled:
		return false

	var markers_moves = null

	var tile_w = boundingRectangle.size.x / board.get_width()
	var tile_h = boundingRectangle.size.y / board.get_height()

	var tile_x = (int)((pos.x - boundingRectangle.position.x) / tile_w)
	var tile_y = (int)((pos.y - boundingRectangle.position.y) / tile_h)

	var new_selected_coord = Coord.new(board.get_height() - tile_y, Coord.file_from_col(tile_x))
	var new_selected_piece = board.get_coord(new_selected_coord)

	if new_selected_coord.equal(selected_tile):
		selected_tile = null
		selected_piece = null
	elif selected_tile != null:
		# Check to see if the location is a valid move
		var valid_moves = move_generator.get_valid_moves_for_current_player(selected_piece, selected_tile, board, false)
		var found_dest = false
		
		for item in valid_moves:
			var move_type = item[0]
			var valid_move = item[1] 

			if valid_move.equal(new_selected_coord):
				var king_safe = board.is_move_king_safe(move_generator, selected_tile, new_selected_coord)
				if king_safe:
					var valid_move_destination_piece = board.get_coord(new_selected_coord)
					if valid_move_destination_piece != null:
						if move_type == MoveGenerator.MoveType.ATTACK:
							# Take the piece
							board.take_piece(new_selected_coord)
							board.set_coord(selected_tile, null)
							board.set_coord(new_selected_coord, selected_piece)
							var placed_in_check = board.update_incheck(move_generator)
							board.update_castling_permission(selected_piece)
							add_move_to_move_list(selected_piece, selected_tile, new_selected_coord, true, placed_in_check, Globals.CastlingSide.NONE)
							selected_tile = null
							selected_piece = null
							reset_half_moves()
							update_clock(board.get_player_turn(), true)
							flip_turn()
							found_dest = true
						elif move_type == MoveGenerator.MoveType.NORMAL_OR_ATTACK and Globals.get_opposite_color(
								selected_piece.get_color()) == valid_move_destination_piece.get_color():
							board.take_piece(new_selected_coord)
							board.set_coord(selected_tile, null)
							board.set_coord(new_selected_coord, selected_piece)
							var placed_in_check = board.update_incheck(move_generator)
							board.update_castling_permission(selected_piece)
							add_move_to_move_list(selected_piece, selected_tile, new_selected_coord, true, placed_in_check, Globals.CastlingSide.NONE)
							selected_tile = null
							selected_piece = null
							reset_half_moves()
							update_clock(board.get_player_turn(), true)
							flip_turn()
							found_dest = true
						else:
							assert("Found a non-attack move onto a valid piece")
					elif move_type == MoveGenerator.MoveType.NORMAL or move_type == MoveGenerator.MoveType.NORMAL_OR_ATTACK:
						board.set_coord(selected_tile, null)
						board.set_coord(new_selected_coord, selected_piece)
						
						if selected_piece.get_type() == Globals.PieceType.PAWN:
							reset_half_moves()

						var placed_in_check = board.update_incheck(move_generator)
						board.update_castling_permission(selected_piece)
						add_move_to_move_list(selected_piece, selected_tile, new_selected_coord, false, placed_in_check, Globals.CastlingSide.NONE)
						selected_tile = null
						selected_piece = null
						update_clock(board.get_player_turn(), true)
						flip_turn()
						found_dest = true
					elif move_type == MoveGenerator.MoveType.CASTLE:
						board.set_coord(selected_tile, null)
						board.set_coord(new_selected_coord, selected_piece)
						
						var type = Globals.CastlingSide.NONE
						if new_selected_coord.get_file() == 'B':
							var rook_coord = Coord.new(selected_tile.get_rank(), 'A')
							var rook_destination = Coord.new(selected_tile.get_rank(), 'C')
							var rook_piece = board.get_coord(rook_coord)
							board.set_coord(rook_coord, null)
							board.set_coord(rook_destination, rook_piece)
							type = Globals.CastlingSide.QUEEN
						else:
							var rook_coord = Coord.new(selected_tile.get_rank(), 'H')
							var rook_destination = Coord.new(selected_tile.get_rank(), 'F')
							var rook_piece = board.get_coord(rook_coord)
							board.set_coord(rook_coord, null)
							board.set_coord(rook_destination, rook_piece)
							type = Globals.CastlingSide.KING
						
						board.update_castling_permission(selected_piece)
						add_move_to_move_list(selected_piece, selected_tile, new_selected_coord, false, false, type)
						selected_tile = null
						selected_piece = null
						update_clock(board.get_player_turn(), true)
						flip_turn()
						found_dest = true

				if found_dest:
					break
					
		if !found_dest:
			# Player selected an invalid destination for this move
			selected_tile = null
			selected_piece = null
	elif new_selected_piece != null and new_selected_piece.get_color() == board.get_player_turn():
		selected_tile = new_selected_coord
		selected_piece = new_selected_piece
		
		if selected_piece != null:
			markers_moves = move_generator.get_valid_moves_for_current_player(selected_piece, selected_tile, board, false)
	
	update_markers(markers_moves)

func create_piece_from_info(position, info):
	var piece = Piece.instantiate()
	piece.create(position, info)
	print("board: " + str(piece) + " " + str(piece.get_instance_id()))
	board.set_coord(position, piece)

func place_piece_visuals():
	for piece in board.get_pieces():
		$Board/Tiles.add_child(piece[1])

func initialize_from_fen(fen):
		# First, split into the fields
		var fields = fen.split(" ")
		
		if fields.size() != 6:
			# TODO: Show error
			return

		# The first field describes the pieces
		var pieces = fields[0]
		board.init_from_fen(pieces)
		place_piece_visuals()

		# The second field tells you whose turn it is
		if fields[1] == 'w':
			board.set_player_turn(Globals.PieceColor.WHITE)
			$UI/Clock/WhiteTurnMarker.visible = true
			$UI/Clock/BlackTurnMarker.visible = false
		elif fields[1] == 'b':
			#print("Black turn")
			board.set_player_turn(Globals.PieceColor.BLACK)
			$UI/Clock/WhiteTurnMarker.visible = false
			$UI/Clock/BlackTurnMarker.visible = true

		# Castling
		board.set_castling_permission_from_fen_string(fields[2])

		# TODO: Deal with en-passant
		# Fields[3] is en passant, ignore fornow

		# Halfmove clock
		half_moves = int(fields[4])

		# Fullmove clock
		full_moves = int(fields[5])

		# Game starts immediately
		start_turn_time = Time.get_ticks_usec()

func reset_pieces():
	var d_piece_type = "q"
	var e_piece_type = "k"

	for c in range(1, board.get_width() + 1):
		for r in range(board.get_height(), 0, -1):
			var piece_coord = Coord.new(r, Coord.file_from_col(c - 1))
			var piece_at_coord = board.get_coord(piece_coord)
			if piece_at_coord != null:
				piece_at_coord.queue_free()
				board.set_coord(piece_coord, null)

	for col in range(0, 8):
		create_piece_from_info(Coord.new(2, Coord.file_from_col(col)), Globals.piece_info_from_fen_string("P"))
		create_piece_from_info(Coord.new(7, Coord.file_from_col(col)), Globals.piece_info_from_fen_string("p"))

	var row = 8
	create_piece_from_info(Coord.new(row, 'A'), Globals.piece_info_from_fen_string("r"))
	create_piece_from_info(Coord.new(row, 'B'), Globals.piece_info_from_fen_string("n"))
	create_piece_from_info(Coord.new(row, 'C'), Globals.piece_info_from_fen_string("b"))
	create_piece_from_info(Coord.new(row, 'D'), Globals.piece_info_from_fen_string("q"))
	create_piece_from_info(Coord.new(row, 'E'), Globals.piece_info_from_fen_string("k"))
	create_piece_from_info(Coord.new(row, 'F'), Globals.piece_info_from_fen_string("b"))
	create_piece_from_info(Coord.new(row, 'G'), Globals.piece_info_from_fen_string("n"))
	create_piece_from_info(Coord.new(row, 'H'), Globals.piece_info_from_fen_string("r"))
	
	row = 1
	create_piece_from_info(Coord.new(row, 'A'), Globals.piece_info_from_fen_string("R"))
	create_piece_from_info(Coord.new(row, 'B'), Globals.piece_info_from_fen_string("N"))
	create_piece_from_info(Coord.new(row, 'C'), Globals.piece_info_from_fen_string("B"))
	create_piece_from_info(Coord.new(row, 'D'), Globals.piece_info_from_fen_string("Q"))
	create_piece_from_info(Coord.new(row, 'E'), Globals.piece_info_from_fen_string("K"))
	create_piece_from_info(Coord.new(row, 'F'), Globals.piece_info_from_fen_string("B"))
	create_piece_from_info(Coord.new(row, 'G'), Globals.piece_info_from_fen_string("N"))
	create_piece_from_info(Coord.new(row, 'H'), Globals.piece_info_from_fen_string("R"))
	
	place_piece_visuals()
	start_game()

func _on_new_game_button_pressed():
	reset_pieces()
	start_game()

func _on_export_to_fen_pressed_button():
	$Board/Control/FENCopyContainer.visible = true
	$Board/Control/FENCopyContainer/FENCopy.text = "Click to copy and close:\n\n" + board.export_to_fen()
	board_enabled = false

func _on_import_from_fen_pressed_button():
	$Board/Control/FENEditContainer.visible = true
	board_enabled = false

func _on_do_import_pressed():
	$Board/Control/FENEditContainer.visible = false
	# TODO: Do Validation
	initialize_from_fen($Board/Control/FENEditContainer/VBoxContainer/FENEdit.text)
	hide_overlay = true

func _on_fen_copy_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var line = $Board/Control/FENCopyContainer/FENCopy.text.split("\n")
		DisplayServer.clipboard_set(line[2])
		$Board/Control/FENCopyContainer.visible = false
		hide_overlay = true
