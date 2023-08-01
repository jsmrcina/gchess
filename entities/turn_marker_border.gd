extends ColorRect

var count = 0.0
var old_color
var color_target
const TARGET_TIME = .5

var color_array = [Color(0,0,0), Color(1,1,1), Color(0,0,0), Color(1,1,1)]
var array_index = 0

func _ready():
	set_process(true)

func _process(delta):
	count += delta
	if count > TARGET_TIME:
		array_index += 1
		count = 0
	if array_index > (color_array.size() - 1):
		array_index = 0

	color_target = Color(color_array[array_index])
	old_color = self.get_modulate()
	self.set_modulate(Color(old_color.lerp(color_target, count)))
