extends Node2D

var type
var color
var direction
var starting_row_position : int

var Coord = load("res://systems/coord.gd")
const PieceType = preload("res://systems/globals.gd").PieceType
const PieceColor = preload("res://systems/globals.gd").PieceColor
const Direction = preload("res://systems/globals.gd").Direction

func create(info):
	type = info[0]
	color = info[1]
	get_node("Sprite2D").texture = info[2]
	direction = null
	starting_row_position = -1

	if type == PieceType.PAWN:
		if color == PieceColor.WHITE:
			direction = Direction.RANK_UP
			starting_row_position = 2
		else:
			direction = Direction.RANK_DOWN
			starting_row_position = 7

func get_color():
	return color

func get_type():
	return type

func get_direction():
	return direction

func get_starting_row_position():
	return starting_row_position

func to_fen_string():

	var toReturn = null
	if self.get_type() == PieceType.PAWN:
		toReturn = 'p'
	elif self.get_type() == PieceType.KNIGHT:
		toReturn = 'n'
	elif self.get_type() == PieceType.BISHOP:
		toReturn = 'b'
	elif self.get_type() == PieceType.ROOK:
		toReturn = 'r'
	elif self.get_type() == PieceType.QUEEN:
		toReturn = 'q'
	elif self.get_type() == PieceType.KING:
		toReturn = 'k'
	else:
		assert(false)

	if self.get_color() == PieceColor.BLACK:
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
	return to_fen_string()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
