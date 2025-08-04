extends Control

@onready var new_game: Button = $VBoxContainer/NewGame
@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var load_game: Button = $VBoxContainer/LoadGame

func _ready() -> void:
	load_game.disabled=!Game.has_save()
	new_game.grab_focus()
	
	SoundManager.setup_ui_sound(self)
	SoundManager.play_bgm(preload("res://assets/bgm/02 1 titles LOOP.mp3"))


func _on_new_game_pressed() -> void:
	Game.new_game()


func _on_load_game_pressed() -> void:
	Game.load_game()


func _on_exit_game_pressed() -> void:
	get_tree().quit()
