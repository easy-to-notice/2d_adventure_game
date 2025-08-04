extends Node

signal camera_should_shake(amount:float)

const SAVE_PATH:="user://data.sav"
const CONFIG_PATH:="user://config.ini"

var saved:bool=false
@onready var player_stats: Stats = $PlayerStats
@onready var color_rect: ColorRect = $ColorRect
@onready var default_player_stats:=player_stats.to_dict()

var world_states:={}

func _ready() -> void:
	color_rect.color.a=0
	load_config()

func change_scene(path:String,params:={}):
	var duration:=params.get("duration",0.2) as float
	
	var tree:=get_tree()
	tree.paused=1
	
	var tween:=create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)#
	tween.tween_property(color_rect,"color:a",1,duration)
	await tween.finished
	
	if tree.current_scene is World:
		var old_name:=tree.current_scene.scene_file_path.get_file().get_basename()
		world_states[old_name]=tree.current_scene.to_dict()
	
	if "init"in params:
		params.init.call()
	
	tree.change_scene_to_file(path)
	await tree.tree_changed
	
	if tree.current_scene is World:
		var new_name:=tree.current_scene.scene_file_path.get_file().get_basename()
		if new_name in world_states:	
			tree.current_scene.from_dict(world_states[new_name])
		
		if "entry_point" in params:
			for node in tree.get_nodes_in_group("entry_points"):
				if node.name==params.entry_point:
					tree.current_scene.update_player(node.global_position,node.direction)
					break
		if "position"in params &&"direction"in params:
			tree.current_scene.update_player(params.position,params.direction)
	
	tree.paused=0
	tween=create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect,"color:a",0,duration)
	

func save_game():
	var scene:=get_tree().current_scene
	var scene_name:=scene.scene_file_path.get_file().get_basename()
	world_states[scene_name]=scene.to_dict()
	
	var data:={
		world_states=world_states,
		stats=player_stats.to_dict(),
		scene=scene.scene_file_path	,
		player={
			direction=scene.player.direction,
			position={
				x=scene.player.global_position.x,
				y=scene.player.global_position.y,
			}
		}
	}
	
	var json:=JSON.stringify(data)
	var file:=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if !file:
		return
	file.store_string(json)

func load_game():
	var file:=FileAccess.open(SAVE_PATH,FileAccess.READ)
	if !file:
		return
	
	var json:=file.get_as_text()
	var data:=JSON.parse_string(json) as Dictionary
	
	
	change_scene(data.scene,{
		direction=data.player.direction,
		position=Vector2(
			data.player.position.x,
			data.player.position.y,
		),
		init=func():
			world_states=data.world_states
			player_stats.from_dict(data.stats)
	})

func new_game():
	change_scene("res://worlds/forests.tscn",{
		duration=1,
		init=func():
			world_states={}
			player_stats.from_dict(default_player_stats)
	})

func back_to_title():
	change_scene("res://ui/title_screen.tscn",{
		duration=1
	})

func has_save()->bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_config():
	var config:=ConfigFile.new()
	
	config.set_value("audio","master",SoundManager.get_volume(SoundManager.Bus.Master))
	config.set_value("audio","sfx",SoundManager.get_volume(SoundManager.Bus.Sfx))
	config.set_value("audio","bgm",SoundManager.get_volume(SoundManager.Bus.Bgm))
	
	config.save(CONFIG_PATH)

func load_config():
	var config:=ConfigFile.new()
	config.load(CONFIG_PATH)
	
	SoundManager.set_volume(
		SoundManager.Bus.Master,
		config.get_value("audio","master",0.5)
	)
	SoundManager.set_volume(
		SoundManager.Bus.Sfx,
		config.get_value("audio","Sfx",0.5)
	)
	SoundManager.set_volume(
		SoundManager.Bus.Bgm,
		config.get_value("audio","Bgm",0.5)
	)

func shake_camera(amount:float):
	camera_should_shake.emit(amount)
