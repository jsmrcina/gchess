extends RefCounted

class_name MoveGenerator

# var Coord = load("res://systems/coord.gd")
const PieceType = preload("res://systems/globals.gd").PieceType
const PieceColor = preload("res://systems/globals.gd").PieceColor
const Direction = preload("res://systems/globals.gd").Direction

enum MoveType
{
	NORMAL = 0,
	ATTACK = 1,
	NORMAL_OR_ATTACK = 2,
	CASTLE = 3
}

var possible_moves : Array[Coord] = []

# This is only used for castling. Caller must check that castling is valid
func add_castling_move(board : Board, turn : Globals.PieceColor, type : Globals.CastlingSide, possible_moves : Array):
	var rank = 1
	if turn == Globals.PieceColor.BLACK:
		rank = 8
	
	var file = 'G'
	if type == Globals.CastlingSide.QUEEN:
		file = 'C'
		
	possible_moves.append([MoveType.CASTLE, Coord.new(rank, file)])

# This is only used for pawns moving straight forward
func add_normal_move_if_empty(board : Board, new_move : Coord, possible_moves : Array):
	if not new_move.is_on_board():
		return

	if board.get_coord(new_move) == null:
		possible_moves.append([MoveType.NORMAL, new_move])

func any_attacked(attacked_locations : Array, check_list : Array) -> bool:
	for move in check_list:
		if not move.is_on_board():
			assert("Invalid move passed")

		var is_attacked = false
		for attack in attacked_locations:
			var source_coord = attack[0]
			var piece_at_source = attack[1]
			var move_type = attack[2]
			var destination_coord = attack[3]
			if move.equal(destination_coord):
				return true

	return false

func add_normal_or_attack_move_if_not_attacked(board : Board, source_tile : Coord, dest_tile : Coord, color : Globals.PieceColor, possible_moves : Array, attacked_locations : Array):
	if not dest_tile.is_on_board():
		return

	var is_attacked = false
	for attack in attacked_locations:
		var source_coord = attack[0]
		var piece_at_source = attack[1]
		var move_type = attack[2]
		var destination_coord = attack[3]
		if dest_tile.equal(destination_coord):
			is_attacked = true
			break

	if not is_attacked:
		if board.get_coord(dest_tile) == null or board.get_coord(dest_tile).get_color() == Globals.get_opposite_color(color):
			possible_moves.append([MoveType.NORMAL_OR_ATTACK, dest_tile])

func add_normal_or_attack_move(board : Board, new_move : Coord, possible_moves : Array):
	if not new_move.is_on_board():
		return

	possible_moves.append([MoveType.NORMAL_OR_ATTACK, new_move])

func add_attack_move(new_move : Coord, possible_moves : Array):
	if not new_move.is_on_board():
		return

	possible_moves.append([MoveType.ATTACK, new_move])

func add_attack_move_if_enemy(location : Coord, board, new_move : Coord, possible_moves : Array):
	if not new_move.is_on_board():
		return

	var moving_piece = board.get_coord(location)
	var target_piece = board.get_coord(new_move)
	if moving_piece.isOppositeColor(target_piece):
		possible_moves.append([MoveType.ATTACK, new_move])

func add_moves_in_direction(piece : Piece, board, location : Coord, direction : Globals.Direction, possible_moves : Array):
	var running = true
	var step = location

	while running:
		step = step.get_in_direction(direction)

		if not step.is_on_board():
			running = false
			continue

		var target_piece = board.get_coord(step)
		if target_piece == null:
			possible_moves.append([MoveType.NORMAL_OR_ATTACK, step])
		elif piece.isOppositeColor(target_piece):
			possible_moves.append([MoveType.NORMAL_OR_ATTACK, step])
			running = false
		elif piece.isSameColor(target_piece):
			running = false

# Returns an array in the shape of [source_coord, piece_at_source, [[move_type, destination_coord], ...]]
# Which contains all squares attacked by the passed color
func determine_all_attacked_squares(board : Board, color : Globals.PieceColor):
	var pieces = board.get_pieces_by_color(color)
	var allPossibleMovesByColor = []
	for item in pieces:
		var coord = item[0]
		var piece_at_coord = item[1]
		var piece_with_moves = [coord, piece_at_coord, [get_valid_moves(piece_at_coord, coord, board, color, true)]]
		allPossibleMovesByColor += [piece_with_moves]

	var allAttackMovesByColor = []
	for attack in allPossibleMovesByColor:
		var coord = attack[0]
		var piece_at_coord = attack[1]
		var moves = attack[2][0]
		for item2 in moves:
			var move_type = item2[0]
			var destination_coord = item2[1]
			if move_type == MoveType.ATTACK or move_type == MoveType.NORMAL_OR_ATTACK:
				allAttackMovesByColor.append([coord, piece_at_coord, move_type, destination_coord])

	return allAttackMovesByColor

func determine_possible_pawn_moves(piece : Piece, location : Coord, board : Board, include_all_attacks : bool, possible_moves : Array):
	var step = location.get_in_direction(piece.get_direction())

	add_normal_move_if_empty(board, step, possible_moves)
	if location.get_rank() == piece.get_starting_rank_position():
		add_normal_move_if_empty(board, step.get_in_direction(piece.get_direction()), possible_moves)

	var east_diag_step = step.get_in_direction(Direction.FILE_UP)
	var west_diag_step = step.get_in_direction(Direction.FILE_DOWN)

	if include_all_attacks:
		add_attack_move(east_diag_step, possible_moves)
		add_attack_move(west_diag_step, possible_moves)
	else:
		add_attack_move_if_enemy(location, board, east_diag_step, possible_moves)
		add_attack_move_if_enemy(location, board, west_diag_step, possible_moves)

func determine_possible_king_moves(piece : Piece, location : Coord, board : Board, color : Globals.PieceColor, include_all_attacks : bool, possible_moves : Array):
	var attacked_locations = []
	if not include_all_attacks:
		attacked_locations = determine_all_attacked_squares(board, Globals.get_opposite_color(color))

	for d in Direction:
		var d_as_int = Direction[d]
		add_normal_or_attack_move_if_not_attacked(board, location, location.get_in_direction(d_as_int), color, possible_moves, attacked_locations)

	# If we can castle, show that as an option
	var rank = 1
	if piece.get_color() == Globals.PieceColor.BLACK:
		rank = 8

	var RKCoord = Coord.new(rank, 'H')
	var NKCoord = Coord.new(rank, 'G')
	var BKCoord = Coord.new(rank, 'F')
	var KCoord = Coord.new(rank, 'E')
	var QCoord = Coord.new(rank, 'D')
	var BQCoord = Coord.new(rank, 'C')
	var NQCoord = Coord.new(rank, 'B')
	var RQCoord = Coord.new(rank, 'A')	
	var castling_permission = board.get_castling_permission()
	
	if castling_permission[piece.get_color()][Globals.CastlingSide.KING]:
		var knightExists = (board.get_coord(NKCoord) != null)
		var bishopExists = (board.get_coord(BKCoord) != null)
		if !knightExists and !bishopExists:
			# Check to see if any of the pieces is under attack
			var checkCoords = [RKCoord, NKCoord, BKCoord, KCoord]
			if not any_attacked(attacked_locations, checkCoords):
				add_castling_move(board, piece.get_color(), Globals.CastlingSide.KING, possible_moves)
	
	if castling_permission[piece.get_color()][Globals.CastlingSide.QUEEN]:
		var bishopExists = (board.get_coord(BQCoord) != null)
		var knightExists = (board.get_coord(NQCoord) != null)
		var queenExists = (board.get_coord(QCoord) != null)
		if !knightExists and !bishopExists and !queenExists:
			var checkCoords = [RQCoord, NQCoord, BQCoord, KCoord, QCoord]
			if not any_attacked(attacked_locations, checkCoords):
				add_castling_move(board, piece.get_color(), Globals.CastlingSide.QUEEN, possible_moves)

func determine_possible_queen_moves(piece : Piece, location : Coord, board : Board, include_all_attacks : bool, possible_moves : Array):
	for d in Direction:
		var d_as_int = Direction[d]
		add_moves_in_direction(piece, board, location, d_as_int, possible_moves)

func determine_possible_rook_moves(piece : Piece, location : Coord, board : Board, include_all_attacks : bool, possible_moves : Array):
	var cardinal_directions = [Direction.RANK_UP, Direction.RANK_DOWN, Direction.FILE_UP, Direction.FILE_DOWN]
	for d in cardinal_directions:
		add_moves_in_direction(piece, board, location, d, possible_moves)

func determine_possible_bishop_moves(piece : Piece, location : Coord, board : Board, include_all_attacks : bool, possible_moves : Array):
	var cardinal_directions = [Direction.RANK_UP_FILE_UP, Direction.RANK_UP_FILE_DOWN, Direction.RANK_DOWN_FILE_UP, Direction.RANK_DOWN_FILE_DOWN]
	for d in cardinal_directions:
		add_moves_in_direction(piece, board, location, d, possible_moves)

func determine_possible_knight_moves(piece : Piece, location : Coord, board : Board, include_all_attacks : bool, possible_moves : Array):
	var cardinal_directions = [Direction.RANK_UP, Direction.RANK_DOWN, Direction.FILE_UP, Direction.FILE_DOWN]

	for r in cardinal_directions.slice(0, 2):
		var twoInRank = location.get_in_direction(r).get_in_direction(r)
		for f in cardinal_directions.slice(2, 4):
			var oneInFile = twoInRank.get_in_direction(f)
			add_normal_or_attack_move(board, oneInFile, possible_moves)

	for r in cardinal_directions.slice(2, 4):
		var twoInFile = location.get_in_direction(r).get_in_direction(r)
		for f in cardinal_directions.slice(0, 2):
			var oneInRank = twoInFile.get_in_direction(f)
			add_normal_or_attack_move(board, oneInRank, possible_moves)

func get_valid_moves_for_current_player(piece : Piece, location : Coord, board : Board, include_all_attacks : bool):
	return get_valid_moves(piece, location, board, board.get_player_turn(), include_all_attacks)

func get_valid_moves_for_opposite_player(piece : Piece, location : Coord, board : Board, include_all_attacks : bool):
	return get_valid_moves(piece, location, board, Globals.get_opposite_color(board.get_player_turn()), include_all_attacks)

func get_valid_moves(piece : Piece, location : Coord, board : Board, color : Globals.PieceColor, include_all_attacks : bool):
	var possible_moves = []

	if piece.get_type() == PieceType.PAWN:
		determine_possible_pawn_moves(piece, location, board, include_all_attacks, possible_moves)
	elif piece.get_type() == PieceType.KING:
		determine_possible_king_moves(piece, location, board, color, include_all_attacks, possible_moves)
	if piece.get_type() == PieceType.QUEEN:
		determine_possible_queen_moves(piece, location, board, include_all_attacks, possible_moves)
	if piece.get_type() == PieceType.ROOK:
		determine_possible_rook_moves(piece, location, board, include_all_attacks, possible_moves)
	if piece.get_type() == PieceType.BISHOP:
		determine_possible_bishop_moves(piece, location, board, include_all_attacks, possible_moves)
	if piece.get_type() == PieceType.KNIGHT:
		determine_possible_knight_moves(piece, location, board, include_all_attacks, possible_moves)

	# Prune out of bounds
	var result = []
	for move in possible_moves:
		if not move[1].is_on_board():
			continue

		result.append(move)
	
	return result

func determine_line_between_coordinates(source : Coord, dest : Coord):
	var drow = 0
	if dest.get_rank() - source.get_rank() < 0:
		drow = -1
	elif dest.get_rank() - source.get_rank() > 0:
		drow = 1
	
	var dcol = 0
	if dest.get_col() - source.get_col() < 0:
		dcol = -1
	elif dest.get_col() - source.get_col() > 0:
		dcol = 1
	
	print(str(source) + " " + str(dest) + " " + str(drow) + " " + str(dcol))
	
	var result = []
	var cur = Coord.new(source.get_rank(), source.get_file())
	while not cur.equal(dest):
		var new_rank = cur.get_rank() + drow
		var new_col = cur.get_col() + dcol
		
		cur = Coord.new(new_rank, Coord.file_from_col(new_col))
		if not cur.equal(dest):
			result.append(cur)
	
	return result

func determine_in_check(board : Board, to_determine_color : Globals.PieceColor) -> bool:
	var attacked_locations = determine_all_attacked_squares(board, Globals.get_opposite_color(to_determine_color))
	print(str(attacked_locations))
	for attack in attacked_locations:
		var source_coord = attack[0]
		var piece_at_source = attack[1]
		var move_type = attack[2]
		var destination_coord = attack[3]
		var piece_at_attacked_location = board.get_coord(destination_coord)
		if piece_at_attacked_location != null:
			if piece_at_attacked_location.get_type() == Globals.PieceType.KING and piece_at_attacked_location.get_color() == to_determine_color:
				# print("In Check! " + str(to_determine_color))
				return true

	return false
