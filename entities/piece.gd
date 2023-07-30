class_name Piece

extends Node2D

var type
var color
var direction
var starting_row_position : int

func create(info):
	type = info[0]
	color = info[1]
	get_node("Sprite2D").texture = info[2]
	direction = null
	starting_row_position = -1

	if type == Globals.PieceType.PAWN:
		if color == Globals.PieceColor.WHITE:
			direction = Globals.Direction.RANK_UP
			starting_row_position = 2
		else:
			direction = Globals.Direction.RANK_DOWN
			starting_row_position = 7

func get_color():
	return color

func get_type():
	return type

func get_direction():
	return direction

func get_starting_row_position():
	return starting_row_position

func to_san_string():

	var toReturn = null
	if self.get_type() == Globals.PieceType.PAWN:
		toReturn = ''
	elif self.get_type() == Globals.PieceType.KNIGHT:
		toReturn = 'N'
	elif self.get_type() == Globals.PieceType.BISHOP:
		toReturn = 'B'
	elif self.get_type() == Globals.PieceType.ROOK:
		toReturn = 'R'
	elif self.get_type() == Globals.PieceType.QUEEN:
		toReturn = 'Q'
	elif self.get_type() == Globals.PieceType.KING:
		toReturn = 'K'
	else:
		assert(false)

	if self.get_color() == Globals.PieceColor.BLACK:
		return toReturn

	return toReturn.to_upper()

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

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
