extends Node2D

var color : Color = Color.GREEN

func set_color(c):
	color = c

func _draw():
	draw_rect(Rect2(0, 0, Constants.TILE_WIDTH, Constants.TILE_WIDTH), color, false, 3)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
