extends Node

var asset_map : Dictionary

func _init():
	asset_map["p"] = load('sprites/pb.png')
	asset_map["P"] = load('sprites/pw.png')
	asset_map["R"] = load('sprites/rw.png')
	asset_map["r"] = load('sprites/rb.png')
	asset_map["B"] = load('sprites/bw.png')
	asset_map["b"] = load('sprites/bb.png')
	asset_map["N"] = load('sprites/nw.png')
	asset_map["n"] = load('sprites/nb.png')
	asset_map["Q"] = load('sprites/qw.png')
	asset_map["q"] = load('sprites/qb.png')
	asset_map["K"] = load('sprites/kw.png')
	asset_map["k"] = load('sprites/kb.png')

func get_texture(key: String):
	return asset_map[key]
