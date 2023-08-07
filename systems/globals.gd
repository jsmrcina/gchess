extends Object

class_name Globals

static var PieceManager = preload("res://systems/PieceManager.gd")

enum CastlingSide { KING = 0, QUEEN = 1, NONE = 2}

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

enum GameState {
	IDLE = 0,
	PLAYING = 1,
	UIFOCUS = 2,
	UICLOSING = 3,
	ANIMATING = 4,
	GAMEOVER = 5,
	PROMOTION = 6
}

static var WHITE_COLOR = Color("#ffffff")
static var BLACK_COLOR = Color("#000000")

static func get_opposite_color(color):
	if color == Globals.PieceColor.WHITE:
		return Globals.PieceColor.BLACK
	else:
		return Globals.PieceColor.WHITE

static func piece_info_from_fen_string(string):
	var toReturn = []
	if string.to_lower() == 'p':
		toReturn.append(Globals.PieceType.PAWN)
	elif string.to_lower() == 'n':
		toReturn.append(Globals.PieceType.KNIGHT)
	elif string.to_lower() == 'b':
		toReturn.append(Globals.PieceType.BISHOP)
	elif string.to_lower() == 'r':
		toReturn.append(Globals.PieceType.ROOK)
	elif string.to_lower() == 'q':
		toReturn.append(Globals.PieceType.QUEEN)
	elif string.to_lower() == 'k':
		toReturn.append(Globals.PieceType.KING)
	else:
		assert("Invalid piece string")

	if string == string.to_upper():
		toReturn.append(Globals.PieceColor.WHITE)
	else:
		toReturn.append(Globals.PieceColor.BLACK)
		
	toReturn.append(PieceManager.new().get_texture(string))

	return toReturn
