extends Object

class_name Board

var Coord = load("res://systems/coord.gd")
var Piece = preload("res://entities/piece.tscn")

var board : Array = []
var player_turn : Globals.PieceColor
var in_check : Array[bool] = [false, false]
var castling_permission : Array = [[true, true], [true, true]] # King / Queen side

func _init():
	for r in range(0, Constants.BOARD_WIDTH_IN_TILES):
		board.append([])
		for c in range(0, Constants.BOARD_HEIGHT_IN_TILES):
			board[r].append(null)

func copy(other : Board):
	for c in range(1, get_width() + 1):
		for r in range(get_height(), 0, -1):
			var coord = Coord.new(r, Coord.file_from_col(c - 1))
			var piece = other.get_coord(coord)
			
			if piece != null:
				var piece_copy = Piece.instantiate()
				piece_copy.copy(piece)
				print("copy: " + str(piece) + " " + str(piece.get_instance_id()))
				set_coord(coord, piece_copy)
				
	# Copy other attributes
	player_turn = other.get_player_turn()
	in_check = other.get_in_check()
	castling_permission = other.get_castling_permission()

func delete():
	for c in range(1, get_width() + 1):
		for r in range(get_height(), 0, -1):
			var coord = Coord.new(r, Coord.file_from_col(c - 1))
			var piece = get_coord(coord)
			
			if piece != null:
				piece.queue_free()

func init_from_fen(pieces : String):
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
				
				var piece = Piece.instantiate()
				piece.create(cur_pos, piece_info)
				print("create from fen: " + str(piece) + " " + str(piece.get_instance_id()))
				set_coord(cur_pos, piece)
				
				cur_pos = cur_pos.get_in_direction(Globals.Direction.FILE_UP)
		cur_pos = cur_pos.get_in_direction(Globals.Direction.RANK_DOWN)
		cur_pos.set_file("A")

func reset_in_check():
	in_check = [false, false]
	
func reset_castling_permission():
	castling_permission = [[true, true], [true, true]]

func set_castling_permission_from_fen_string(fen_string : String):
	for b in range(0, len(castling_permission)):
		castling_permission[b][Globals.CastlingSide.KING] = false
		castling_permission[b][Globals.CastlingSide.QUEEN] = false

	for c in fen_string:
		if c == 'K':
			castling_permission[Globals.PieceColor.WHITE][Globals.CastlingSide.KING] = true
		elif c == 'Q':
			castling_permission[Globals.PieceColor.WHITE][Globals.CastlingSide.QUEEN] = true
		elif c == 'k':
			castling_permission[Globals.PieceColor.BLACK][Globals.CastlingSide.KING] = true
		elif c == 'q':
			castling_permission[Globals.PieceColor.BLACK][Globals.CastlingSide.QUEEN] = true

func get_player_turn():
	return player_turn
	
func set_player_turn(color : Globals.PieceColor):
	player_turn = color

func get_in_check():
	return in_check

func get_castling_permission():
	return castling_permission

func update_incheck(move_generator : MoveGenerator) -> bool:
	in_check[Globals.PieceColor.WHITE] = false
	in_check[Globals.PieceColor.BLACK] = false

	var attacked_locations = move_generator.determineAllAttackedSquares(self, player_turn)
	for attack in attacked_locations:
		var source_coord = attack[0]
		var piece_at_source = attack[1]
		var move_type = attack[2]
		var destination_coord = attack[3]
		var piece_at_attacked_location = get_coord(destination_coord)
		if piece_at_attacked_location != null:
			if piece_at_attacked_location.get_type() == Globals.PieceType.KING and piece_at_attacked_location.get_color() == Globals.get_opposite_color(
					player_turn):
				in_check[Globals.get_opposite_color(player_turn)] = true
				return true

	return false

func update_castling_permission(moved_piece : Piece):
	# If you move your king, both types are not permitted
	if moved_piece.get_type() == Globals.PieceType.KING:
		castling_permission[Globals.get_opposite_color(player_turn)][Globals.CastlingSide.KING] = false
		castling_permission[Globals.get_opposite_color(player_turn)][Globals.CastlingSide.QUEEN] = false
	
	# If you move a rook, you cannot castle that side any longer
	if moved_piece.get_type() == Globals.PieceType.ROOK:
		if moved_piece.get_starting_file_position() == 'A':
			castling_permission[Globals.get_opposite_color(player_turn)][Globals.CastlingSide.QUEEN] = false
		else:
			castling_permission[Globals.get_opposite_color(player_turn)][Globals.CastlingSide.KING] = false

	print(str(castling_permission))

func is_move_king_safe(move_generator : MoveGenerator, source_tile : Coord, dest_tile : Coord) -> bool:
	var king_safe = true
	var after_move_board = Board.new()
	after_move_board.copy(self)
	
	# Perform the move on our new board
	var valid_move_destination_piece = after_move_board.get_coord(dest_tile)
	if valid_move_destination_piece != null:
		after_move_board.take_piece(dest_tile)

	var moving_piece = after_move_board.get_coord(source_tile)
	after_move_board.set_coord(source_tile, null)
	after_move_board.set_coord(dest_tile, moving_piece)

	var current_king = after_move_board.get_king_by_color(after_move_board.get_player_turn())

	var attacked_locations = move_generator.determineAllAttackedSquares(after_move_board, Globals.get_opposite_color(after_move_board.get_player_turn()))
	for attack in attacked_locations:
		var source_coord = attack[0]

		var destination_coord = attack[3]
		if destination_coord.equal(current_king[0]):
			king_safe = false
			break

	after_move_board.delete()
	return king_safe

func is_checkmate(move_generator : MoveGenerator) -> bool:
	if !(in_check[0] || in_check[1]):
		return false

	var attacks_participating_in_check : Array = []
	var checked_king = get_king_by_color(Globals.get_opposite_color(player_turn))
	
	# Find all attacks participating in this check
	var attacked_locations = move_generator.determineAllAttackedSquares(self, player_turn)
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
		var valid_king_moves = move_generator.get_valid_moves_for_opposite_player(checked_king[1], checked_king[0], self, false)
		if valid_king_moves.size() == 0:
			var attacking_piece_coord = attacks_participating_in_check[0][0]
			var attacking_piece = attacks_participating_in_check[0][1]
			var valid_attacker_moves = move_generator.get_valid_moves_for_current_player(attacking_piece, attacking_piece_coord, self, false)
			
			# Can someone intercept or take the piece
			for piece_tuple in get_pieces_by_color(Globals.get_opposite_color(player_turn)):
				var piece_coord = piece_tuple[0]
				var piece = piece_tuple[1]
				var valid_piece_moves = move_generator.get_valid_moves_for_opposite_player(piece, piece_coord, self, false)
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
								if is_move_king_safe(move_generator, piece_coord, valid_move):
									print("Piece can (at least) be intercepted by " + piece.to_readable_string() + " at " + str(piece_coord) + " to " + str(attacker_valid_move))
									return false
								
			# If we get here, this is a single check with no way to intercept or to take the piece.
			return true
		else:
			for move in valid_king_moves:
				var move_type = move[0]
				var valid_move = move[1] 
				print(str(move_type) + " " + str(valid_move))
			print("King can move")
	# Double check (only resolved by moving)
	else:
		var valid_king_moves = move_generator.get_valid_moves_for_opposite_player(checked_king[1], checked_king[0], self, false)
		if valid_king_moves.size() == 0:
			return true
			
	return false

func get_width():
	return Constants.BOARD_WIDTH_IN_TILES

func get_height():
	return Constants.BOARD_HEIGHT_IN_TILES

func set_coord(coord, piece):
	board[coord.get_row()][coord.get_col()] = piece
	
	if piece != null:
		piece.position = Vector2((coord.get_col() * Constants.TILE_WIDTH) + Constants.PIECE_OFFSET, (coord.get_row() * Constants.TILE_HEIGHT) + Constants.PIECE_OFFSET)

func take_piece(coord):
	var piece = board[coord.get_row()][coord.get_col()]
	board[coord.get_row()][coord.get_col()] = null
	piece.queue_free()

func get_coord(coord):
	return board[coord.get_row()][coord.get_col()]

func get_pieces():
	var pieces = []

	for c in range(1, get_width() + 1):
		for r in range(get_height(), 0, -1):
			var piece_coord = Coord.new(r, Coord.file_from_col(c - 1))
			var piece_at_coord = get_coord(piece_coord)
			if piece_at_coord != null:
				pieces.append([piece_coord, piece_at_coord])

	return pieces

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
			if piece_at_coord != null:
				if piece_at_coord.get_color() == color and piece_at_coord.get_type() == Globals.PieceType.KING:
					return [piece_coord, piece_at_coord]

	assert("no king found")

func dump():
	print("dump")
	var output = ""
	for r in range(get_height(), 0, -1):
		for c in range(1, get_width() + 1):
			var coord = Coord.new(r, Coord.file_from_col(c - 1))
			var piece = get_coord(coord)
			
			if piece != null:
				output += piece.to_readable_string()
			else:
				output += "-"
		output += "\n"
	print(output)
