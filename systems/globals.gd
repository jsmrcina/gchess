extends Node

var Piece = load("res://entities/piece.gd")
var PieceManager = preload("res://systems/PieceManager.gd")

enum PieceType { PAWN = 0, KNIGHT = 1, BISHOP = 2, ROOK = 3, QUEEN = 4, KING = 5 }

enum PieceColor { BLACK, WHITE }

enum Direction {
	RANK_UP,
	RANK_DOWN,
	FILE_UP,
	FILE_DOWN,
	RANK_UP_FILE_UP,
	RANK_DOWN_FILE_DOWN,
	RANK_UP_FILE_DOWN,
	RANK_DOWN_FILE_UP
}

func piece_from_fen_string(string):
	var toReturn = null
	if string.to_lower() == 'p':
		toReturn = Piece.new($"/root/Globals".PieceType.PAWN, $"/root/Globals".PieceColor.BLACK)
	elif string.to_lower() == 'n':
		toReturn = Piece.new($"/root/Globals".PieceType.KNIGHT, $"/root/Globals".PieceColor.BLACK)
	elif string.to_lower() == 'b':
		toReturn = Piece.new($"/root/Globals".PieceType.BISHOP, $"/root/Globals".PieceColor.BLACK)
	elif string.to_lower() == 'r':
		toReturn = Piece.new($"/root/Globals".PieceType.ROOK, $"/root/Globals".PieceColor.BLACK)
	elif string.to_lower() == 'q':
		toReturn = Piece.new($"/root/Globals".PieceType.QUEEN, $"/root/Globals".PieceColor.BLACK)
	elif string.to_lower() == 'k':
		toReturn = Piece.new($"/root/Globals".PieceType.KING, $"/root/Globals".PieceColor.BLACK)
	else:
		assert("Invalid piece string")

	get_node("Sprite2D").texture = PieceManager.new().get_texture(string)

	if string == string.to_upper():
		toReturn.color = $"/root/Globals".PieceColor.WHITE

	return toReturn
