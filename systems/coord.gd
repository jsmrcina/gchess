extends Node2D

var rank : int
var file : String

var Coord = load("res://systems/coord.gd")
var Constants = preload("res://systems/constants.gd")
var Globals = preload("res://systems/globals.gd")

func _init(r: int, f: String):
	rank = r
	file = f

func set_rank_from_index(index : int):
	# The top of the board is 8, but our array is indexed from 0
	rank = Constants.BOARD_HEIGHT - index

func set_file(str : String):
	file = str

func get_rank() -> int:
	return rank

func get_row() -> int:
	return Constants.BOARD_HEIGHT - rank

#	@classmethod
#	def get_file_generator(cls):
#		for c in range(ord('A'), ord('H') + 1):
#			yield chr(c)

static func file_from_col(col) -> String:
	return char(col + 65)

func get_file() -> String:
	return file

func get_col() -> int:
	print(file + " " + str(file.unicode_at(0)))
	var file_as_col = file.unicode_at(0) - 65
	return file_as_col

func get_file_up():
	return Coord.file_from_col(get_col() + 1)

func get_file_down():
	return Coord.file_from_col(get_col() - 1)

func get_rank_down():
	return get_rank() - 1

func get_rank_up():
	return get_rank() + 1

func get_in_direction(direction):
	if direction == Globals.Direction.RANK_UP:
		return Coord.new(get_rank_up(), get_file())
	elif direction == Globals.Direction.RANK_DOWN:
		return Coord.new(get_rank_down(), get_file())
	elif direction == Globals.Direction.FILE_UP:
		return Coord.new(get_rank(), get_file_up())
	elif direction == Globals.Direction.FILE_DOWN:
		return Coord.new(get_rank(), get_file_down())
	elif direction == Globals.Direction.RANK_UP_FILE_UP:
		return Coord.new(get_rank_up(), get_file_up())
	elif direction == Globals.Direction.RANK_UP_FILE_DOWN:
		return Coord.new(get_rank_up(), get_file_down())
	elif direction == Globals.Direction.RANK_DOWN_FILE_UP:
		return Coord.new(get_rank_down(), get_file_up())
	elif direction == Globals.Direction.RANK_DOWN_FILE_DOWN:
		return Coord.new(get_rank_down(), get_file_down())

	assert("Invalid direction")

func is_on_board():
	if get_row() < 0 or get_row() > 7 or get_col(
	) < 0 or get_col() > 7:
		return false

	return true

func __eq__(other):
	if other == null:
		return false

	if rank == other.rank and file == other.file:
		return true
	else:
		return false

func __str__():
	return str(get_rank()) + " " + str(get_file())
