extends Node2D

var tile_preload = preload("res://entities/tile.tscn")

var black_tile_tex = preload("res://sprites/black.png") 
var white_tile_tex = preload("res://sprites/white.png") 

var tiles : Array = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for r in range(0, Constants.BOARD_HEIGHT_IN_TILES):
		tiles.append([])
		for c in range(0, Constants.BOARD_WIDTH_IN_TILES):
			var tile = tile_preload.instantiate()
			tile.position.x = c * Constants.TILE_WIDTH
			tile.position.y = r * Constants.TILE_HEIGHT
			
			if ((r - 1) + (c - 1)) % 2 == 0:
				tile.get_node("Sprite2D").texture = white_tile_tex
			else:
				tile.get_node("Sprite2D").texture = black_tile_tex
			
			tiles[r].append(tile)
			add_child(tiles[r][c])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
