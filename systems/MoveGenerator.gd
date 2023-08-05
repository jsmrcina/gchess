extends Node
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
func addCastlingMove(board : Board, turn : Globals.PieceColor, type : Globals.CastlingSide, possible_moves : Array):
	var rank = 1
	if turn == Globals.PieceColor.BLACK:
		rank = 8
	
	var file = 'G'
	if type == Globals.CastlingSide.QUEEN:
		file = 'B'
		
	possible_moves.append([MoveType.CASTLE, Coord.new(rank, file)])

# This is only used for pawns moving straight forward
func addNormalMoveIfEmpty(board : Board, new_move : Coord, possible_moves : Array):
	if not new_move.is_on_board():
		return

	if board.get_coord(new_move) == null:
		possible_moves.append([MoveType.NORMAL, new_move])

func anyAttacked(attacked_locations : Array, check_list : Array) -> bool:
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

func addNormalOrAttackMoveIfNotAttacked(board : Board, new_move : Coord, possible_moves : Array, attacked_locations : Array):
	if not new_move.is_on_board():
		return

	var is_attacked = false
	for attack in attacked_locations:
		var source_coord = attack[0]
		var piece_at_source = attack[1]
		var move_type = attack[2]
		var destination_coord = attack[3]
		if new_move.equal(destination_coord):
			is_attacked = true
			break

	if not is_attacked:
		if board.get_coord(new_move) == null:
			possible_moves.append([MoveType.NORMAL_OR_ATTACK, new_move])

func addNormalOrAttackMove(board : Board, new_move : Coord, possible_moves : Array):
	if not new_move.is_on_board():
		return

	possible_moves.append([MoveType.NORMAL_OR_ATTACK, new_move])

func addAttackMove(new_move : Coord, possible_moves : Array):
	if not new_move.is_on_board():
		return

	possible_moves.append([MoveType.ATTACK, new_move])

func addAttackMoveIfEnemy(location : Coord, board, new_move : Coord, possible_moves : Array):
	if not new_move.is_on_board():
		return

	var moving_piece = board.get_coord(location)
	var target_piece = board.get_coord(new_move)
	if moving_piece.isOppositeColor(target_piece):
		possible_moves.append([MoveType.ATTACK, new_move])

func addMovesInDirection(piece : Piece, board, location : Coord, direction : Globals.Direction, possible_moves : Array):
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
func determineAllAttackedSquares(board : Board, color : Globals.PieceColor):
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

func determinePossiblePawnMoves(piece : Piece, location : Coord, board : Board, include_all_attacks : bool, possible_moves : Array):
	var step = location.get_in_direction(piece.get_direction())

	addNormalMoveIfEmpty(board, step, possible_moves)
	if location.get_rank() == piece.get_starting_rank_position():
		addNormalMoveIfEmpty(board, step.get_in_direction(piece.get_direction()), possible_moves)

	var east_diag_step = step.get_in_direction(Direction.FILE_UP)
	var west_diag_step = step.get_in_direction(Direction.FILE_DOWN)

	if include_all_attacks:
		addAttackMove(east_diag_step, possible_moves)
		addAttackMove(west_diag_step, possible_moves)
	else:
		addAttackMoveIfEnemy(location, board, east_diag_step, possible_moves)
		addAttackMoveIfEnemy(location, board, west_diag_step, possible_moves)

func determinePossibleKingMoves(piece : Piece, location : Coord, board : Board, color : Globals.PieceColor, include_all_attacks : bool, possible_moves : Array):
	var attacked_locations = []
	if piece.get_color() == board.get_player_turn():
		attacked_locations = determineAllAttackedSquares(board, Globals.get_opposite_color(color))

	for d in Direction:
		var d_as_int = Direction[d]
		addNormalOrAttackMoveIfNotAttacked(board, location.get_in_direction(d_as_int), possible_moves, attacked_locations)

	# If we can castle, show that as an option
	var rank = 1
	if color == Globals.PieceColor.BLACK:
		rank = 8

	var rookCoord = Coord.new(rank, 'H')
	var knightCoord = Coord.new(rank, 'G')
	var bishopCoord = Coord.new(rank, 'F')
	var kingCoord = Coord.new(rank, 'E')
	var queenCoord = Coord.new(rank, 'D')
	var castling_permission = board.get_castling_permission()
	
	if castling_permission[color][Globals.CastlingSide.KING]:
		var knightExists = (board.get_coord(knightCoord) != null)
		var bishopExists = (board.get_coord(bishopCoord) != null)
		if !knightExists and !bishopExists:
			# Check to see if any of the pieces is under attack
			var checkCoords = [rookCoord, knightCoord, bishopCoord, kingCoord]
			if not anyAttacked(attacked_locations, checkCoords):
				addCastlingMove(board, color, Globals.CastlingSide.KING, possible_moves)
			else:
				print("Cannot castle king-side, something is under attack")
	
	if castling_permission[color][Globals.CastlingSide.QUEEN]:
		var bishopExists = (board.get_coord(bishopCoord) != null)
		var knightExists = (board.get_coord(knightCoord) != null)
		var queenExists = (board.get_coord(queenCoord) != null)
		if !knightExists and !bishopExists and !queenExists:
			var checkCoords = [rookCoord, knightCoord, bishopCoord, kingCoord, queenCoord]
			if not anyAttacked(attacked_locations, checkCoords):
				addCastlingMove(board, color, Globals.CastlingSide.QUEEN, possible_moves)
			else:
				print("Cannot castle queen-side, something is under attack")

func determinePossibleQueenMoves(piece : Piece, location : Coord, board : Board, include_all_attacks : bool, possible_moves : Array):
	for d in Direction:
		var d_as_int = Direction[d]
		addMovesInDirection(piece, board, location, d_as_int, possible_moves)

func determinePossibleRookMoves(piece : Piece, location : Coord, board : Board, include_all_attacks : bool, possible_moves : Array):
	var cardinal_directions = [Direction.RANK_UP, Direction.RANK_DOWN, Direction.FILE_UP, Direction.FILE_DOWN]
	for d in cardinal_directions:
		addMovesInDirection(piece, board, location, d, possible_moves)

func determinePossibleBishopMoves(piece : Piece, location : Coord, board : Board, include_all_attacks : bool, possible_moves : Array):
	var cardinal_directions = [Direction.RANK_UP_FILE_UP, Direction.RANK_UP_FILE_DOWN, Direction.RANK_DOWN_FILE_UP, Direction.RANK_DOWN_FILE_DOWN]
	for d in cardinal_directions:
		addMovesInDirection(piece, board, location, d, possible_moves)

func determinePossibleKnightMoves(piece : Piece, location : Coord, board : Board, include_all_attacks : bool, possible_moves : Array):
	var cardinal_directions = [Direction.RANK_UP, Direction.RANK_DOWN, Direction.FILE_UP, Direction.FILE_DOWN]

	for r in cardinal_directions.slice(0, 2):
		var twoInRank = location.get_in_direction(r).get_in_direction(r)
		for f in cardinal_directions.slice(2, 4):
			var oneInFile = twoInRank.get_in_direction(f)
			addNormalOrAttackMove(board, oneInFile, possible_moves)

	for r in cardinal_directions.slice(2, 4):
		var twoInFile = location.get_in_direction(r).get_in_direction(r)
		for f in cardinal_directions.slice(0, 2):
			var oneInRank = twoInFile.get_in_direction(f)
			addNormalOrAttackMove(board, oneInRank, possible_moves)

func get_valid_moves_for_current_player(piece : Piece, location : Coord, board : Board, include_all_attacks : bool):
	return get_valid_moves(piece, location, board, board.get_player_turn(), include_all_attacks)

func get_valid_moves_for_opposite_player(piece : Piece, location : Coord, board : Board, include_all_attacks : bool):
	return get_valid_moves(piece, location, board, Globals.get_opposite_color(board.get_player_turn()), include_all_attacks)

func get_valid_moves(piece : Piece, location : Coord, board : Board, color : Globals.PieceColor, include_all_attacks : bool):
	var possible_moves = []

	if piece.get_type() == PieceType.PAWN:
		determinePossiblePawnMoves(piece, location, board, include_all_attacks, possible_moves)
	elif piece.get_type() == PieceType.KING:
		determinePossibleKingMoves(piece, location, board, color, include_all_attacks, possible_moves)
	if piece.get_type() == PieceType.QUEEN:
		determinePossibleQueenMoves(piece, location, board, include_all_attacks, possible_moves)
	if piece.get_type() == PieceType.ROOK:
		determinePossibleRookMoves(piece, location, board, include_all_attacks, possible_moves)
	if piece.get_type() == PieceType.BISHOP:
		determinePossibleBishopMoves(piece, location, board, include_all_attacks, possible_moves)
	if piece.get_type() == PieceType.KNIGHT:
		determinePossibleKnightMoves(piece, location, board, include_all_attacks, possible_moves)

	# Prune out of bounds
	var result = []
	for move in possible_moves:
		if not move[1].is_on_board():
			continue

		result.append(move)
	
	return result
