extends RefCounted

class_name PositionTracker

var positions : Dictionary = {}

func _init():
	pass
	
func add_position(fen_string : String):
	var sha1 = fen_string.sha1_text()
	if positions.has(fen_string.sha1_text()):
		positions[sha1] = positions[sha1] + 1
	else:
		positions[sha1] = 1
	
func reset():
	positions = {}
	
func check_three_fold_repetition() -> bool:
	for key in positions.keys():
		if positions[key] >= 3:
			return true
	
	return false
	
func print():
	print("Position Tracker: ")
	print(positions)
