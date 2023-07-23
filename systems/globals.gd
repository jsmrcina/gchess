extends Node

# var Piece = load("res://entities/piece.gd")
var PieceManager = preload("res://systems/PieceManager.gd")

enum PieceType { PAWN = 0, KNIGHT = 1, BISHOP = 2, ROOK = 3, QUEEN = 4, KING = 5 }

enum PieceColor { BLACK, WHITE }

enum Direction {
	RANK_UP = 0,
	RANK_DOWN = 1,
	FILE_UP = 2,
	FILE_DOWN = 3,
	RANK_UP_FILE_UP = 4,
	RANK_DOWN_FILE_DOWN = 5,
	RANK_UP_FILE_DOWN = 6,
	RANK_DOWN_FILE_UP = 7
}

func piece_info_from_fen_string(string):
	var toReturn = []
	if string.to_lower() == 'p':
		toReturn.append($"/root/Globals".PieceType.PAWN)
	elif string.to_lower() == 'n':
		toReturn.append($"/root/Globals".PieceType.KNIGHT)
	elif string.to_lower() == 'b':
		toReturn.append($"/root/Globals".PieceType.BISHOP)
	elif string.to_lower() == 'r':
		toReturn.append($"/root/Globals".PieceType.ROOK)
	elif string.to_lower() == 'q':
		toReturn.append($"/root/Globals".PieceType.QUEEN)
	elif string.to_lower() == 'k':
		toReturn.append($"/root/Globals".PieceType.KING)
	else:
		assert("Invalid piece string")

	if string == string.to_upper():
		toReturn.append($"/root/Globals".PieceColor.WHITE)
	else:
		toReturn.append($"/root/Globals".PieceColor.BLACK)
		
	toReturn.append(PieceManager.new().get_texture(string))

	return toReturn
