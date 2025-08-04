extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	hide()
	set_process_input(false)

func _input(event: InputEvent) -> void:
	get_window().set_input_as_handled()
	
	if animation_player.is_playing():
		return
	
	if (event is InputEventKey || 
	event is InputEventMouseButton || 
	event is InputEventJoypadButton):
		if event.is_pressed()&&!event.is_echo():
			if Game.saved:
				Game.load_game()
			else:
				Game.back_to_title()

func show_game_over():
	show()
	set_process_input(true)
	animation_player.play("enter")
	

func close_bgm():
	var tween=create_tween()
	tween.tween_property(SoundManager.bgm_player,"volume_db",-30,1.0)
