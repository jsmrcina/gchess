extends Node2D

var Coord = load("res://systems/coord.gd")
var Piece = preload("res://entities/piece.tscn")
var TileMarker = preload("res://entities/tile_marker.tscn")
var MoveGenerator = load("res://systems/MoveGenerator.gd")

var board_enabled : bool = true
var board : Array = []
var markers : Array = []
var player_turn
var in_check : Array[bool] = [false, false]
var castling_permission : Array[bool] = [true, true, true, true]
var half_moves : int = 0
var full_moves : int = 1
var move_generator

var selected_tile
var selected_piece
var moves : Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	move_generator = MoveGenerator.new()
	
	for r in range(0, $"/root/Constants".BOARD_WIDTH_IN_TILES):
		board.append([])
		markers.append([])
		for c in range(0, $"/root/Constants".BOARD_HEIGHT_IN_TILES):
			board[r].append(null)
			var tileMarker = TileMarker.instantiate()
			tileMarker.position.x = c * $"/root/Constants".TILE_WIDTH
			tileMarker.position.y = r * $"/root/Constants".TILE_HEIGHT
			tileMarker.visible = false
			$Markers.add_child(tileMarker)
			markers[r].append(tileMarker)
	
	player_turn = $"/root/Globals".PieceColor.WHITE
	
	initialize_from_fen("rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("click"):
		
		var position = get_viewport().get_mouse_position()
		
		# Check to see if the click is within the board
		var pixel_board_width = $"/root/Constants".TILE_WIDTH * $"/root/Constants".BOARD_WIDTH_IN_TILES
		var pixel_board_height = $"/root/Constants".TILE_HEIGHT * $"/root/Constants".BOARD_HEIGHT_IN_TILES
		
		var bounding_rectangle = Rect2($Tiles.position.x, $Tiles.position.y, pixel_board_width, pixel_board_height)
		if bounding_rectangle.has_point(position):
			handle_click(bounding_rectangle, position)

func is_game_over():
	return false

func get_width():
	return $"/root/Constants".BOARD_WIDTH_IN_TILES

func get_height():
	return $"/root/Constants".BOARD_HEIGHT_IN_TILES

func get_tile(i, j):
	return board[i][j]

func get_turn():
	return player_turn
	
func get_opposite_color(color):
	if color == $"/root/Globals".PieceColor.WHITE:
		return $"/root/Globals".PieceColor.BLACK
	else:
		return $"/root/Globals".PieceColor.WHITE

func update_incheck():
	in_check[$"/root/Globals".PieceColor.WHITE] = false
	in_check[$"/root/Globals".PieceColor.BLACK] = false

	var attacked_locations = move_generator.determineAllAttackedSquares(self, player_turn)
	for item in attacked_locations:
		var move_type = item[0]
		var attacked_square = item[1]
		var piece_at_attacked_location = get_coord(attacked_square)
		if piece_at_attacked_location != null:
			if piece_at_attacked_location.get_type() == $"/root/Globals".PieceType.KING and piece_at_attacked_location.get_color() == get_opposite_color(
					player_turn):
				in_check[get_opposite_color(player_turn)] = true

func flip_turn():
	if is_game_over():
		# Two conditions make a check-mate:
		# 1) The king cannot move
		# 2) There is no piece that can be put between the king to make it not in check

		board_enabled = false

	if player_turn == $"/root/Globals".PieceColor.WHITE:
		player_turn = $"/root/Globals".PieceColor.BLACK
	else:
		full_moves = full_moves + 1
		player_turn = $"/root/Globals".PieceColor.WHITE

	half_moves = half_moves + 1

func reset_half_moves():
	half_moves = 0

func update_markers(valid_moves):
	for row in markers:
		for marker in row:
			marker.visible = false
	
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
				var destination_piece = get_coord(valid_move)
				if destination_piece != null:
					if destination_piece.get_color() == get_opposite_color(player_turn):
						color = Color.ORANGE_RED
					else:
						# This is our own piece, we can't move here
						continue

			markers[valid_move.get_row()][valid_move.get_col()].set_color(color)
			markers[valid_move.get_row()][valid_move.get_col()].visible = true

func handle_click(boundingRectangle, pos):

	#if not board_enabled:
	#	return False

	var markers_moves = null

	var tile_w = boundingRectangle.size.x / get_width()
	var tile_h = boundingRectangle.size.y / get_height()

	var tile_x = (int)((pos.x - boundingRectangle.position.x) / tile_w)
	var tile_y = (int)((pos.y - boundingRectangle.position.y) / tile_h)

	var new_selected_coord = Coord.new(get_height() - tile_y, Coord.file_from_col(tile_x))
	var new_selected_piece = get_coord(new_selected_coord)
	
	print(str(new_selected_coord) + " " + str(new_selected_piece))

	if new_selected_coord.equal(selected_tile):
		selected_tile = null
		selected_piece = null
	elif selected_tile != null:
		# Check to see if the location is a valid move
		var valid_moves = move_generator.get_valid_moves(selected_piece, selected_tile, self, false)

		for item in valid_moves:
			var move_type = item[0]
			var valid_move = item[1] 
			var found_dest = false

			if valid_move.equal(new_selected_coord):
				var valid_move_destination_piece = get_coord(new_selected_coord)
				
				# Before we make the move, we need to check it won't place our king in check
				# Pretend the piece we're about to move is gone. Only do this check if we're not
				# holding the current king in our hand
				set_coord(selected_tile, null)
				
				var current_king = get_king_by_color(player_turn)
				
				var puts_king_in_check = false
				if current_king != null:
					var attacked_locations = move_generator.determineAllAttackedSquares(self, get_opposite_color(player_turn))
					for item2 in attacked_locations:
						var move = item2[1]
						if move == current_king[0]:
							print("Cannot move " + str(selected_piece) + " as it would place your king in check")
							puts_king_in_check = true

				set_coord(selected_tile, selected_piece)

				if puts_king_in_check:
					selected_piece = null
					selected_tile = null
				else:
					if valid_move_destination_piece != null:
						if move_type == MoveGenerator.MoveType.ATTACK:
							# Take the piece
							take_piece(new_selected_coord)
							set_coord(selected_tile, null)
							set_coord(new_selected_coord, selected_piece)
							selected_tile = null
							selected_piece = null
							update_incheck()
							reset_half_moves()
							flip_turn()
							found_dest = true
						elif move_type == MoveGenerator.MoveType.NORMAL_OR_ATTACK and get_opposite_color(
								selected_piece.get_color()) == valid_move_destination_piece.get_color():
							take_piece(new_selected_coord)
							set_coord(selected_tile, null)
							set_coord(new_selected_coord, selected_piece)
							selected_tile = null
							selected_piece = null
							update_incheck()
							reset_half_moves()
							flip_turn()
							found_dest = true
					else:
						set_coord(selected_tile, null)
						set_coord(new_selected_coord, selected_piece)

						if selected_piece.get_type() == $"/root/Globals".PieceType.PAWN:
							reset_half_moves()

						selected_tile = null
						selected_piece = null
						update_incheck()
						flip_turn()
						found_dest = true

				if found_dest:
					break
	elif new_selected_piece != null and new_selected_piece.get_color() == player_turn:
		# If you're in check, you can only select your king to move
		if in_check[player_turn] and new_selected_piece.get_type() == $"/root/Globals".PieceType.KING:
			selected_tile = new_selected_coord
			selected_piece = new_selected_piece
		elif not in_check[player_turn]:
			selected_tile = new_selected_coord
			selected_piece = new_selected_piece
		else:
			print("Must select king when in check")
		
		if selected_piece != null:
			markers_moves = move_generator.get_valid_moves(selected_piece, selected_tile, self, false)
	
	update_markers(markers_moves)

func set_coord(coord, piece):
	board[coord.get_row()][coord.get_col()] = piece
	# 64 is the width of the tiles, 6 is the offset to make the piece centered
	
	if piece != null:
		piece.position = Vector2((coord.get_col() * $"/root/Constants".TILE_WIDTH) + 6, (coord.get_row() * $"/root/Constants".TILE_HEIGHT) + 6)

func take_piece(coord):
	var piece = board[coord.get_row()][coord.get_col()]
	board[coord.get_row()][coord.get_col()] = null
	piece.visible = false

func get_coord(coord):
	return board[coord.get_row()][coord.get_col()]

func get_pieces_by_color(color):
	var pieces = []

	for c in range(1, get_width() + 1):
		for r in range(get_height(), 0, -1):
			var piece_coord = Coord.new(r, Coord.file_from_col(c - 1))
			var piece_at_coord = get_coord(piece_coord)
			if piece_at_coord != null:
				if piece_at_coord.get_color() == color:
					pieces.append([piece_coord, piece_at_coord])

	return pieces

func get_king_by_color(color):
	for c in range(1, get_width() + 1):
		for r in range(get_height(), 0, -1):
			var piece_coord = Coord.new(r, Coord.file_from_col(c - 1))
			var piece_at_coord = get_coord(piece_coord)
			print(str(piece_coord) + " " + str(piece_at_coord))
			if piece_at_coord != null:
				if piece_at_coord.get_color() == color and piece_at_coord.get_type() == $"/root/Globals".PieceType.KING:
					return [piece_coord, piece_at_coord]

	return null

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
						cur_pos = cur_pos.get_in_direction($"/root/Globals".Direction.FILE_UP)
				else:
					var piece_info = $"/root/Globals".piece_info_from_fen_string(item)
					var piece = Piece.instantiate()
					piece.create(piece_info)
					set_coord(cur_pos, piece)
					$Tiles.add_child(piece)
					cur_pos = cur_pos.get_in_direction($"/root/Globals".Direction.FILE_UP)
			cur_pos = cur_pos.get_in_direction($"/root/Globals".Direction.RANK_DOWN)
			cur_pos.set_file("A")

		# The second field tells you whose turn it is
		if fields[1] == 'w':
			player_turn = $"/root/Globals".PieceColor.WHITE
		elif fields[1] == 'b':
			player_turn = $"/root/Globals".PieceColor.BLACK

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

		# start_game()
