class_name Piece

extends Node2D

var type
var color
var direction
var starting_rank_position : int
var starting_file_position : String

func copy(other : Piece):
	type = other.type
	color = other.color
	direction = other.direction
	starting_rank_position = other.starting_rank_position
	
	# Not needed for the copies we do
	# get_node("Sprite2D").texture = other.get_node("Sprite2D").texture

func create(position : Coord, info : Array):
	type = info[0]
	color = info[1]
	get_node("Sprite2D").texture = info[2]
	direction = null
	starting_rank_position = -1

	if type == Globals.PieceType.PAWN:
		if color == Globals.PieceColor.WHITE:
			direction = Globals.Direction.RANK_UP
			starting_rank_position = 2
		else:
			direction = Globals.Direction.RANK_DOWN
			starting_rank_position = 7
	elif type == Globals.PieceType.ROOK:
		starting_file_position = position.get_file()

func get_color():
	return color

func get_type():
	return type

func get_direction():
	return direction

func get_starting_rank_position():
	return starting_rank_position
	
func get_starting_file_position():
	return starting_file_position

func to_readable_string():
	var toReturn = null
	if self.get_type() == Globals.PieceType.PAWN:
		toReturn = 'p'
	elif self.get_type() == Globals.PieceType.KNIGHT:
		toReturn = 'n'
	elif self.get_type() == Globals.PieceType.BISHOP:
		toReturn = 'b'
	elif self.get_type() == Globals.PieceType.ROOK:
		toReturn = 'r'
	elif self.get_type() == Globals.PieceType.QUEEN:
		toReturn = 'q'
	elif self.get_type() == Globals.PieceType.KING:
		toReturn = 'k'
	else:
		assert(false)

	if self.get_color() == Globals.PieceColor.BLACK:
		return toReturn

	return toReturn.to_upper()

func to_san_string():
	var output = to_readable_string()
	if output == 'P' or output == 'p':
		return ''
	else:
		return output

func isOppositeColor(other):
	if other == null:
		return false

	if get_color() != other.get_color():
		return true

	return false

func isSameColor(other):
	if other == null:
		return false

	if get_color() == other.get_color():
		return true

	return false

func _to_string():
	return to_san_string()
