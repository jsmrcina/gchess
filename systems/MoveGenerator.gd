extends Node

var Coord = load("res://systems/coord.gd")
const PieceType = preload("res://systems/globals.gd").PieceType
const PieceColor = preload("res://systems/globals.gd").PieceColor
const Direction = preload("res://systems/globals.gd").Direction

enum MoveType
{
	NORMAL = 0,
	ATTACK = 1,
	NORMAL_OR_ATTACK = 2
}

var possible_moves : Array = []

func addNormalMoveIfEmpty(board, new_move, possible_moves):
	if not new_move.is_on_board():
		return

	if board.get_coord(new_move) == null:
		possible_moves.append([MoveType.NORMAL, new_move])

func addNormalOrAttackMoveIfNotAttacked(board, new_move, possible_moves, attacked_locations):
	if not new_move.is_on_board():
		return

	if board.get_coord(new_move) == null:
		var is_attacked = false
		for attacked_location in attacked_locations:
			if new_move == attacked_location[1]:
				is_attacked = true

		if not is_attacked:
			possible_moves.append([MoveType.NORMAL_OR_ATTACK, new_move])

func addNormalOrAttackMove(board, new_move, possible_moves):
	if not new_move.is_on_board():
		return

	possible_moves.append([MoveType.NORMAL_OR_ATTACK, new_move])

func addAttackMove(new_move, possible_moves):
	if not new_move.is_on_board():
		return

	possible_moves.append([MoveType.ATTACK, new_move])

func addAttackMoveIfEnemy(location, board, new_move, possible_moves):
	if not new_move.is_on_board():
		return

	var moving_piece = board.get_coord(location)
	var target_piece = board.get_coord(new_move)
	if moving_piece.isOppositeColor(target_piece):
		possible_moves.append([MoveType.ATTACK, new_move])

func addMovesInDirection(piece, board, location, direction, possible_moves):
	var running = true
	var step = location
	# moving_piece = board.get_coord(location)

	while running:
		step = step.get_in_direction(direction)

		if not step.is_on_board():
			running = false
			continue

		var target_piece = board.get_coord(step)
		if target_piece == null:
			possible_moves.append([MoveType.NORMAL, step])
		elif piece.isOppositeColor(target_piece):
			possible_moves.append([MoveType.NORMAL_OR_ATTACK, step])
			running = false
		elif piece.isSameColor(target_piece):
			running = false


static func determineAllAttackedSquares(board, color):
	var pieces = board.get_pieces_by_color(color)
	var allPossibleMovesByColor = []
	for item in pieces:
		allPossibleMovesByColor += board.move_generator.get_valid_moves(item[1], item[0], board, true)

	var allAttackMovesByColor = []
	for item in allPossibleMovesByColor:
		if item[0] == MoveType.ATTACK or item[0] == MoveType.NORMAL_OR_ATTACK:
			allAttackMovesByColor.append([item[0], item[1]])

	return allAttackMovesByColor

func determinePossiblePawnMoves(piece, location, board, includeAllAttacks, possible_moves):
	var step = location.get_in_direction(piece.get_direction())

	addNormalMoveIfEmpty(board, step, possible_moves)
	if location.get_rank() == piece.get_starting_row_position():
		addNormalMoveIfEmpty(board, step.get_in_direction(piece.get_direction()), possible_moves)

	var east_diag_step = step.get_in_direction(Direction.FILE_UP)
	var west_diag_step = step.get_in_direction(Direction.FILE_DOWN)

	if includeAllAttacks:
		addAttackMove(east_diag_step, possible_moves)
		addAttackMove(west_diag_step, possible_moves)
	else:
		addAttackMoveIfEnemy(location, board, east_diag_step, possible_moves)
		addAttackMoveIfEnemy(location, board, west_diag_step, possible_moves)

func determinePossibleKingMoves(piece, location, board, includeAllAttacks, possible_moves):
	var attacked_locations = []
	if piece.get_color() == board.get_turn():
		attacked_locations = determineAllAttackedSquares(board,  board.get_opposite_color(piece.get_color()))

	for d in Direction:
		var d_as_int = Direction[d]
		addNormalOrAttackMoveIfNotAttacked(board, location.get_in_direction(d_as_int), possible_moves, attacked_locations)

func determinePossibleQueenMoves(piece, location, board, includeAllAttacks, possible_moves):
	for d in Direction:
		var d_as_int = Direction[d]
		addMovesInDirection(piece, board, location, d_as_int, possible_moves)

func determinePossibleRookMoves(piece, location, board, includeAllAttacks, possible_moves):
	var cardinal_directions = [Direction.RANK_UP, Direction.RANK_DOWN, Direction.FILE_UP, Direction.FILE_DOWN]
	for d in cardinal_directions:
		addMovesInDirection(piece, board, location, d, possible_moves)

func determinePossibleBishopMoves(piece, location, board, includeAllAttacks, possible_moves):
	var cardinal_directions = [Direction.RANK_UP_FILE_UP, Direction.RANK_UP_FILE_DOWN, Direction.RANK_DOWN_FILE_UP, Direction.RANK_DOWN_FILE_DOWN]
	for d in cardinal_directions:
		addMovesInDirection(piece, board, location, d, possible_moves)

func determinePossibleKnightMoves(piece, location, board, includeAllAttacks, possible_moves):
	var cardinal_directions = [Direction.RANK_UP, Direction.RANK_DOWN, Direction.FILE_UP, Direction.FILE_DOWN]

	var i = 0
	var j = 3

	while i < 2:
		var twoInRank = location.get_in_direction(cardinal_directions[i]).get_in_direction(cardinal_directions[i])
		while j > 1:
			var oneInFile = twoInRank.get_in_direction(cardinal_directions[j])
			addNormalOrAttackMove(board, oneInFile, possible_moves)
			j = j - 1
		i = i + 1

	while i < 4:
		var twoInFile = location.get_in_direction(cardinal_directions[i]).get_in_direction(cardinal_directions[i])
		while j >= 0:
			var oneInRank = twoInFile.get_in_direction(cardinal_directions[j])
			addNormalOrAttackMove(board, oneInRank, possible_moves)
			j = j - 1
		i = i + 1

func get_valid_moves(piece, location, board, includeAllAttacks):
	var possible_moves = []

	if piece.get_type() == PieceType.PAWN:
		determinePossiblePawnMoves(piece, location, board, includeAllAttacks, possible_moves)
	elif piece.get_type() == PieceType.KING:
		determinePossibleKingMoves(piece, location, board, includeAllAttacks, possible_moves)
	if piece.get_type() == PieceType.QUEEN:
		determinePossibleQueenMoves(piece, location, board, includeAllAttacks, possible_moves)
	if piece.get_type() == PieceType.ROOK:
		determinePossibleRookMoves(piece, location, board, includeAllAttacks, possible_moves)
	if piece.get_type() == PieceType.BISHOP:
		determinePossibleBishopMoves(piece, location, board, includeAllAttacks, possible_moves)
	if piece.get_type() == PieceType.KNIGHT:
		determinePossibleKnightMoves(piece, location, board, includeAllAttacks, possible_moves)

	# Prune out of bounds
	var result = []
	for move in possible_moves:
		if not move[1].is_on_board():
			continue

		result.append(move)
	
	return result
