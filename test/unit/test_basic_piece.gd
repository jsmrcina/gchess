extends GutTest

var Piece = preload("res://entities/piece.tscn")

func test_basic_coord():
	var coord = Coord.new(1, 'A')
	assert_eq(coord.get_rank(), 1)

# Each test is: input FEN string, position to analyze, expected output moves (each move is a type and a coordinate)
var pawn_move_tests = [["8/8/8/8/3P4/8/8/8", [4, 'D'], [[0, "D5"]]],
						["8/8/8/4p3/3P4/8/8/8", [4, 'D'], [[0, "D5"], [1, "E5"]]],
						["8/8/8/2p1p3/3P4/8/8/8", [4, 'D'], [[0, "D5"], [1, "E5"], [1, "C5"]]]]

func test_pawn_moves(params = use_parameters(pawn_move_tests)):
	var board = Board.new()
	board.init_from_fen(params[0])
	
	var position = Coord.new(params[1][0], params[1][1])
	var move_generator = MoveGenerator.new()
	var valid_moves = move_generator.get_valid_moves_for_current_player(board.get_coord(position), position, board, false)
	var x = 0
	for valid_move in valid_moves:
		var expected_move = params[2][x]
		assert_eq(valid_move[0], expected_move[0])
		var expected_coord = Coord.new(int(expected_move[1][1]), expected_move[1][0])
		assert_true(valid_move[1].equal(expected_coord), "actual: " + str(valid_move[1]) + " expected: " + str(expected_coord))
		x = x + 1
