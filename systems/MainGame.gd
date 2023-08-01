extends Node2D

# Missing rules
# Castling
# En Passant
# Promotion

#var Coord = load("res://systems/coord.gd")
var Piece = preload("res://entities/piece.tscn")
var TileMarker = preload("res://entities/tile_marker.tscn")
var MoveGenerator = load("res://systems/MoveGenerator.gd")

var board_enabled : bool = true
var board : Board
var markers : Array = []
var player_turn
var in_check : Array[bool] = [false, false]
var castling_permission : Array[bool] = [true, true, true, true]
var half_moves : int = 0
var full_moves : int = 1
var move_generator
var start_turn_time : int = -1
var clock_times : Array[int] = [60 * 10, 1 * 10]

var selected_tile
var selected_piece

# Called when the node enters the scene tree for the first time.
func _ready():
	move_generator = MoveGenerator.new()
	board = Board.new()
	
	for r in range(0, Constants.BOARD_WIDTH_IN_TILES):
		markers.append([])
		for c in range(0, Constants.BOARD_HEIGHT_IN_TILES):
			var tileMarker = TileMarker.instantiate()
			tileMarker.position.x = c * Constants.TILE_WIDTH
			tileMarker.position.y = r * Constants.TILE_HEIGHT
			tileMarker.visible = false
			$Board/Tiles/Markers.add_child(tileMarker)
			markers[r].append(tileMarker)
	
	player_turn = Globals.PieceColor.WHITE
	update_clock(Globals.PieceColor.WHITE, false)
	update_clock(Globals.PieceColor.BLACK, false)
	
	$UI/Clock/WhiteTurnMarker.set_color(Globals.WHITE_COLOR)
	$UI/Clock/BlackTurnMarker.set_color(Globals.BLACK_COLOR)
	
	
	initialize_from_fen("rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("click"):
		
		var position = get_viewport().get_mouse_position()
		
		# Check to see if the click is within the board
		var pixel_board_width = Constants.TILE_WIDTH * Constants.BOARD_WIDTH_IN_TILES
		var pixel_board_height = Constants.TILE_HEIGHT * Constants.BOARD_HEIGHT_IN_TILES
		
		var bounding_rectangle = Rect2($Board/Tiles.global_position.x, $Board/Tiles.global_position.y, pixel_board_width, pixel_board_height)
		if bounding_rectangle.has_point(position):
			handle_click(bounding_rectangle, position)

	if board_enabled:
		var ran_out_of_time = update_clock(player_turn, false)
		if ran_out_of_time:
			board_enabled = false
			# If we run out of time, the other player wins
			add_score_to_move_list(Globals.get_opposite_color(player_turn))
			$UI/Clock/WhiteTurnMarker.visible = false
			$UI/Clock/BlackTurnMarker.visible = false
			$Board/Control/GameOver.visible = true

func start_game():
	player_turn = Globals.PieceColor.WHITE
	reset_clock()
	update_clock(Globals.PieceColor.WHITE, false)
	update_clock(Globals.PieceColor.BLACK, false)
	reset_half_moves()
	reset_full_moves()
	reset_markers()
	reset_in_check()
	reset_castling_permission()
	reset_move_list()
	$UI/Clock/WhiteTurnMarker.visible = true
	$UI/Clock/BlackTurnMarker.visible = false
	$Board/Control/GameOver.visible = false
	board_enabled = true

func get_turn():
	return player_turn

func update_incheck() -> bool:
	in_check[Globals.PieceColor.WHITE] = false
	in_check[Globals.PieceColor.BLACK] = false

	var attacked_locations = move_generator.determineAllAttackedSquares(board, player_turn, player_turn)
	for attack in attacked_locations:
		var source_coord = attack[0]
		var piece_at_source = attack[1]
		var move_type = attack[2]
		var destination_coord = attack[3]
		var piece_at_attacked_location = board.get_coord(destination_coord)
		if piece_at_attacked_location != null:
			if piece_at_attacked_location.get_type() == Globals.PieceType.KING and piece_at_attacked_location.get_color() == Globals.get_opposite_color(
					player_turn):
				in_check[Globals.get_opposite_color(player_turn)] = true
				return true

	return false

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

func is_checkmate() -> bool:
	if !(in_check[0] || in_check[1]):
		return false

	var attacks_participating_in_check : Array = []
	var checked_king = board.get_king_by_color(Globals.get_opposite_color(player_turn))
	
	# Find all attacks participating in this check
	var attacked_locations = move_generator.determineAllAttackedSquares(board, player_turn, player_turn)
	for attack in attacked_locations:
		var source_coord = attack[0]
		var piece_at_source = attack[1]
		var move_type = attack[2]
		var destination_coord = attack[3]
		if destination_coord.equal(checked_king[0]):
			attacks_participating_in_check.append(attack)
	
	for attack in attacks_participating_in_check:
		var source_coord = attack[0]
		var piece_at_source = attack[1]
		var move_type = attack[2]
		var destination_coord = attack[3]
	
	# Single check
	if attacks_participating_in_check.size() == 1:
		# Can the king move?
		var valid_king_moves = move_generator.get_valid_moves(checked_king[1], checked_king[0], board, Globals.get_opposite_color(player_turn), false)
		if valid_king_moves.size() == 0:
			var attacking_piece_coord = attacks_participating_in_check[0][0]
			var attacking_piece = attacks_participating_in_check[0][1]
			var valid_attacker_moves = move_generator.get_valid_moves(attacking_piece, attacking_piece_coord, board, player_turn, false)
			
			# Can someone intercept or take the piece
			for piece_tuple in board.get_pieces_by_color(Globals.get_opposite_color(player_turn)):
				var piece_coord = piece_tuple[0]
				var piece = piece_tuple[1]
				var valid_piece_moves = move_generator.get_valid_moves(piece, piece_coord, board, Globals.get_opposite_color(player_turn), false)
				for piece_move in valid_piece_moves:
					var move_type = piece_move[0]
					var valid_move = piece_move[1] 
					if (move_type == MoveGenerator.MoveType.NORMAL_OR_ATTACK or move_type == MoveGenerator.MoveType.ATTACK) and valid_move.equal(attacking_piece_coord):
						# We can take the piece!
						print("Piece can (at least) be taken by " + piece.to_readable_string())
						return false
					else:
						# FIXME: This is ungodly slow -- need to think about this more
						for attacker_move in valid_attacker_moves:
							var attacker_move_type = attacker_move[0]
							var attacker_valid_move = attacker_move[1]
							if (move_type == MoveGenerator.MoveType.NORMAL_OR_ATTACK or move_type == MoveGenerator.MoveType.NORMAL) and valid_move.equal(attacker_valid_move):
								# Check to see if the king is safe after the move
								if is_move_king_safe(piece_coord, valid_move, Globals.get_opposite_color(player_turn)):
									print("Piece can (at least) be intercepted by " + piece.to_readable_string() + " at " + str(piece_coord) + " to " + str(attacker_valid_move))
									return false
								
			# If we get here, this is a single check with no way to intercept or to take the piece.
			add_checkmate_to_move_list()
			return true
		else:
			for move in valid_king_moves:
				var move_type = move[0]
				var valid_move = move[1] 
				print(str(move_type) + " " + str(valid_move))
			print("King can move")
	# Double check (only resolved by moving)
	else:
		var valid_king_moves = move_generator.get_valid_moves(checked_king[1], checked_king[0], board, Globals.get_opposite_color(player_turn), false)
		if valid_king_moves.size() == 0:
			add_checkmate_to_move_list()
			return true
			
	return false

func is_move_king_safe(source_tile, dest_tile, color) -> bool:
	var king_safe = true
	var after_move_board = Board.new()
	after_move_board.copy(board)
	
	# Perform the move on our new board
	var valid_move_destination_piece = after_move_board.get_coord(dest_tile)
	if valid_move_destination_piece != null:
		after_move_board.take_piece(dest_tile)

	var moving_piece = after_move_board.get_coord(source_tile)
	after_move_board.set_coord(source_tile, null)
	after_move_board.set_coord(dest_tile, moving_piece)

	var current_king = after_move_board.get_king_by_color(color)

	var attacked_locations = move_generator.determineAllAttackedSquares(after_move_board, Globals.get_opposite_color(color), color)
	for attack in attacked_locations:
		var source_coord = attack[0]

		var destination_coord = attack[3]
		if destination_coord.equal(current_king[0]):
			king_safe = false
			break

	after_move_board.delete()
	return king_safe

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
	if is_checkmate():
		board_enabled = false
		add_score_to_move_list(true)
		$Board/Control/GameOver.visible = true
	else:
		if player_turn == Globals.PieceColor.WHITE:
			player_turn = Globals.PieceColor.BLACK
			$UI/Clock/WhiteTurnMarker.visible = false
			$UI/Clock/BlackTurnMarker.visible = true
		else:
			full_moves = full_moves + 1
			player_turn = Globals.PieceColor.WHITE
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
			
func reset_in_check():
	in_check = [false, false]
	
func reset_castling_permission():
	castling_permission = [true, true, true, true]
	
func reset_move_list():
	$UI/MoveList.clear()

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
					if destination_piece.get_color() == Globals.get_opposite_color(player_turn):
						color = Color.ORANGE_RED
					else:
						# This is our own piece, we can't move here
						continue

			markers[valid_move.get_row()][valid_move.get_col()].set_color(color)
			markers[valid_move.get_row()][valid_move.get_col()].visible = true

# Note: Does not do en passant, move disambiguation, or promotion, castling, checkmate, end of game
# Reference: https://en.wikipedia.org/wiki/Algebraic_notation_(chess)
func add_move_to_move_list(piece, source, dest, capture, placed_in_check):
	
	var final_string = null
	if capture:
		var piece_as_string = piece.to_string()
		if piece_as_string == "":
			final_string = source.get_file().to_lower() + "x" + dest.to_string()
		else:
			final_string = piece_as_string + "x" + dest.to_string()
	else:
		final_string = piece.to_string() + dest.to_string()
		
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
		var valid_moves = move_generator.get_valid_moves(selected_piece, selected_tile, board, get_turn(), false)

		var found_dest = false
		
		for item in valid_moves:
			var move_type = item[0]
			var valid_move = item[1] 

			if valid_move.equal(new_selected_coord):
				var king_safe = is_move_king_safe(selected_tile, new_selected_coord, player_turn)
				if king_safe:
					var valid_move_destination_piece = board.get_coord(new_selected_coord)
					if valid_move_destination_piece != null:
						if move_type == MoveGenerator.MoveType.ATTACK:
							# Take the piece
							board.take_piece(new_selected_coord)
							board.set_coord(selected_tile, null)
							board.set_coord(new_selected_coord, selected_piece)
							var placed_in_check = update_incheck()
							add_move_to_move_list(selected_piece, selected_tile, new_selected_coord, true, placed_in_check)
							selected_tile = null
							selected_piece = null
							reset_half_moves()
							update_clock(player_turn, true)
							flip_turn()
							found_dest = true
						elif move_type == MoveGenerator.MoveType.NORMAL_OR_ATTACK and Globals.get_opposite_color(
								selected_piece.get_color()) == valid_move_destination_piece.get_color():
							board.take_piece(new_selected_coord)
							board.set_coord(selected_tile, null)
							board.set_coord(new_selected_coord, selected_piece)
							var placed_in_check = update_incheck()
							add_move_to_move_list(selected_piece, selected_tile, new_selected_coord, true, placed_in_check)
							selected_tile = null
							selected_piece = null
							reset_half_moves()
							update_clock(player_turn, true)
							flip_turn()
							found_dest = true
					else:
						board.set_coord(selected_tile, null)
						board.set_coord(new_selected_coord, selected_piece)
						
						if selected_piece.get_type() == Globals.PieceType.PAWN:
							reset_half_moves()

						var placed_in_check = update_incheck()
						add_move_to_move_list(selected_piece, selected_tile, new_selected_coord, false, placed_in_check)
						selected_tile = null
						selected_piece = null
						update_clock(player_turn, true)
						flip_turn()
						found_dest = true

				if found_dest:
					break
					
		if !found_dest:
			# Player selected an invalid destination for this move
			selected_tile = null
			selected_piece = null
	elif new_selected_piece != null and new_selected_piece.get_color() == player_turn:
		selected_tile = new_selected_coord
		selected_piece = new_selected_piece
		
		if selected_piece != null:
			markers_moves = move_generator.get_valid_moves(selected_piece, selected_tile, board, get_turn(), false)
	
	update_markers(markers_moves)



func create_piece_from_info(position, info):
	var piece = Piece.instantiate()
	piece.create(info)
	board.set_coord(position, piece)
	$Board/Tiles.add_child(piece)

func initialize_from_fen(fen):
		# First, split into the fields
		var fields = fen.split(" ")

		# The first field describes the pieces, we're going to ignore the rest for now
		var pieces = fields[0]

		# Each row is separated by a slash
		var rows = pieces.split("/")

		# Parse each row and place pieces
		var cur_pos = Coord.new(8, "A")
		for row in rows:
			for item in row:
				if item.is_valid_int():
					for i in range(0, int(item)):
						cur_pos = cur_pos.get_in_direction(Globals.Direction.FILE_UP)
				else:
					var piece_info = Globals.piece_info_from_fen_string(item)
					create_piece_from_info(cur_pos, piece_info)
					cur_pos = cur_pos.get_in_direction(Globals.Direction.FILE_UP)
			cur_pos = cur_pos.get_in_direction(Globals.Direction.RANK_DOWN)
			cur_pos.set_file("A")

		# The second field tells you whose turn it is
		if fields[1] == 'w':
			player_turn = Globals.PieceColor.WHITE
			$UI/Clock/WhiteTurnMarker.visible = true
			$UI/Clock/BlackTurnMarker.visible = false
		elif fields[1] == 'b':
			#print("Black turn")
			player_turn = Globals.PieceColor.BLACK
			$UI/Clock/WhiteTurnMarker.visible = false
			$UI/Clock/BlackTurnMarker.visible = true

		# Castling
		for b in range(0, len(castling_permission)):
			castling_permission[b] = false

		for c in fields[2]:
			if c == 'K':
				castling_permission[0] = true
			elif c == 'Q':
				castling_permission[1] = true
			elif c == 'k':
				castling_permission[2] = true
			elif c == 'q':
				castling_permission[3] = true

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
	
	start_game()

func _on_new_game_button_pressed():
	reset_pieces()
	start_game()
