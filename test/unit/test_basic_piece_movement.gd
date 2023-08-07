extends GutTest

var Piece = preload("res://entities/piece.tscn")

func test_basic_coord():
	var coord = Coord.new(1, 'A')
	assert_eq(coord.get_rank(), 1)
	assert_eq(coord.get_file(), 'A')

func perform_piece_move_test(params):
	var board = Board.new()

	board.init_from_fen(params[0])
	for piece in board.get_pieces():
		autoqfree(piece[1])

	var position = Coord.new(params[1][0], params[1][1])

	var move_generator = MoveGenerator.new()

	var valid_moves = move_generator.get_valid_moves_for_current_player(board.get_coord(position), position, board, false)
	var x = 0
	for valid_move in valid_moves:
		var expected_move = params[2][x]
		assert_eq(valid_move[0], expected_move[0])
		assert_true(valid_move[1].equal(expected_move[1]), "actual: " + str(valid_move[1]) + " expected: " + str(expected_move))
		x = x + 1
	
	assert_eq(valid_moves.size(), x)

# Each test is: input FEN string, position to analyze, expected output moves (each move is a type and a coordinate)
var pawn_move_tests = [["8/8/8/8/3P4/8/8/8", [4, 'D'], [[0, Coord.new(5, 'D')]]],
						["8/8/8/4p3/3P4/8/8/8", [4, 'D'], [[0, Coord.new(5, 'D')], [1, Coord.new(5, 'E')]]],
						["8/8/8/2p1p3/3P4/8/8/8", [4, 'D'], [[0, Coord.new(5, 'D')], [1, Coord.new(5, 'E')], [1, Coord.new(5, 'C')]]]]

# Each test is: input FEN string, position to analyze, expected output moves (each move is a type and a coordinate)
var bishop_move_tests = [["8/8/8/8/8/8/8/B7", [1, 'A'], [[2, Coord.new(2, 'B')],[2, Coord.new(3, 'C')],
							[2, Coord.new(4, 'D')], [2, Coord.new(5, 'E')], [2, Coord.new(6, 'F')], [2, Coord.new(7, 'G')], [2, Coord.new(8, 'H')]]],
						["8/8/8/8/7B/8/8/8", [4, 'H'], [[2, Coord.new(5, 'G')],[2, Coord.new(6, 'F')],
							[2, Coord.new(7, 'E')], [2, Coord.new(8, 'D')], [2, Coord.new(3, 'G')], [2, Coord.new(2, 'F')], [2, Coord.new(1, 'E')]]],
						["8/8/5p2/8/7B/8/5p2/8", [4, 'H'], [[2, Coord.new(5, 'G')],[2, Coord.new(6, 'F')], [2, Coord.new(3, 'G')], [2, Coord.new(2, 'F')]]]]

func test_pawn_moves(params = use_parameters(pawn_move_tests)):
	perform_piece_move_test(params)

func test_bishop_moves(params = use_parameters(bishop_move_tests)):
	perform_piece_move_test(params)
