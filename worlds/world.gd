class_name World
extends Node2D

@export var bgm:AudioStream

@onready var tile_map: TileMap = $TileMap
@onready var camera_2d: Camera2D = $Player/Camera2D
@onready var player: Player = $Player

func _ready() -> void:
	var used := tile_map.get_used_rect().grow(-1)
	var tile_size = tile_map.tile_set.tile_size
	

	camera_2d.limit_top = used.position.y * tile_size.y
	camera_2d.limit_right = used.end.x * tile_size.x
	camera_2d.limit_bottom = used.end.y * tile_size.y
	camera_2d.limit_left = used.position.x * tile_size.x
	camera_2d.reset_smoothing()
	
	if bgm:
		SoundManager.play_bgm(bgm)

func update_player(pos:Vector2,direction:Player.Direction):
	player.global_position=pos
	player.direction=direction
	camera_2d.reset_smoothing()

func to_dict():
	var enemies_alive:=[]
	for node in get_tree().get_nodes_in_group("enemies"):
		var path:=get_path_to(node) as String
		enemies_alive.append(path)
	
	return{
		enemies_alive=enemies_alive
	}

func from_dict(dict:Dictionary):
	for node in get_tree().get_nodes_in_group("enemies"):
		var path:=get_path_to(node) as String
		if !path in dict.enemies_alive:
			node.queue_free()
