extends Object

class_name Board

var Coord = load("res://systems/coord.gd")
var Piece = preload("res://entities/piece.tscn")

var board : Array = []

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
				set_coord(coord, piece_copy)

func delete():
	for c in range(1, get_width() + 1):
		for r in range(get_height(), 0, -1):
			var coord = Coord.new(r, Coord.file_from_col(c - 1))
			var piece = get_coord(coord)
			
			if piece != null:
				piece.queue_free()

func get_width():
	return Constants.BOARD_WIDTH_IN_TILES

func get_height():
	return Constants.BOARD_HEIGHT_IN_TILES

func set_coord(coord, piece):
	board[coord.get_row()][coord.get_col()] = piece
	# 64 is the width of the tiles, 6 is the offset to make the piece centered
	
	if piece != null:
		piece.position = Vector2((coord.get_col() * Constants.TILE_WIDTH) + 6, (coord.get_row() * Constants.TILE_HEIGHT) + 6)

func take_piece(coord):
	var piece = board[coord.get_row()][coord.get_col()]
	board[coord.get_row()][coord.get_col()] = null
	piece.queue_free()

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
