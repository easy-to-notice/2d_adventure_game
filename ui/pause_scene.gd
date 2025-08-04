extends Control

@onready var resum: Button = $VBoxContainer/Actions/HBoxContainer/Resum

func _ready() -> void:
	hide()
	SoundManager.setup_ui_sound(self)
	visibility_changed.connect(func():
		get_tree().paused=visible
		)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause")||event.is_action_pressed("ui_cancel"):
		hide()
		get_window().set_input_as_handled()

func show_pause():
	show()
	resum.grab_focus()

func _on_resum_pressed() -> void:
	hide()


func _on_quit_pressed() -> void:
	Game.back_to_title()
