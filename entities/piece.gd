extends Node2D

var type
var color
var direction
var starting_row_position : int

var Coord = load("res://systems/coord.gd")
const PieceType = preload("res://systems/globals.gd").PieceType
const PieceColor = preload("res://systems/globals.gd").PieceColor
const Direction = preload("res://systems/globals.gd").Direction

func _init(type, color):
	type = type
	color = color
	direction = null
	starting_row_position = -1

	if type == PieceType.PAWN:
		if color == PieceColor.WHITE:
			direction = Direction.RANK_UP
			starting_row_position = 2
		else:
			direction = Direction.RANK_DOWN
			starting_row_position = 7
			
	

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
