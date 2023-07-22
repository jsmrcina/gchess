extends Node2D

var board : Array = []
var player_turn
var in_check : Array[bool] = [false, false]
var castling_permission : Array[bool] = [true, true, true, true]
var half_moves : int = 0
var full_moves : int = 1

var Coord = load("res://systems/coord.gd")
var Piece = preload("res://entities/tile.tscn")

# Called when the node enters the scene tree for the first time.
func _ready():
	for r in range(0, $"/root/Constants".BOARD_WIDTH):
		board.append([])
		for c in range(0, $"/root/Constants".BOARD_HEIGHT):
			board[r].append(null)
	
	player_turn = $"/root/Globals".PieceColor.WHITE
	
	initialize_from_fen("rnbqkbnr/pp1ppppp/8/2p5/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_coord(coord, piece):
	print(str(coord.get_col()) + " " + str(coord.get_row()))
	board[coord.get_col()][coord.get_row()] = piece

func get_coord(coord):
	return board[coord.get_col()][coord.get_row()]

func initialize_from_fen(fen):
		# First, split into the fields
		var fields = fen.split(" ")

		# The first field describes the pieces, we're going to ignore the rest for now
		var pieces = fields[0]

		# Each row is separated by a slash
		var rows = pieces.split("/")

		# Parse each row and place pieces
		var cur_pos = Coord.new(8, "A")
		print("cur " + str(cur_pos.get_col()) + " " + str(cur_pos.get_row()))
		for row in rows:
			for item in row:
				if item.is_valid_int():
					for i in range(0, int(item)):
						cur_pos = cur_pos.get_in_direction($"/root/Globals".Direction.FILE_UP)
				else:
					set_coord(cur_pos, $"/root/Globals".piece_from_fen_string(item))
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
