extends AnimatedSprite2D

# 触屏设备 DisplayServer.is_touchscreen_available()

const STICK_DEADZONE:=0.3
const MOUSE_DEADZONE:=16.0

func _ready() -> void:
	if Input.get_connected_joypads():
		play("nintendo")
		#show_joypad_icon(0)
	else:
		play("keyboard")


func _input(event: InputEvent) -> void:
	if(
		event is InputEventJoypadButton||
		(event is InputEventJoypadButton&&abs(event.axis_value)>STICK_DEADZONE)
	):
		play("nintendo")
		#show_joypad_icon(event.device)
	if(
		event is InputEventKey||
		event is InputEventMouseMotion&&event.velocity.length()>MOUSE_DEADZONE||
		event is InputEventMouseButton
	):
		play("keyboard")


func show_joypad_icon(device:int):
	var joypad_name:=Input.get_joy_name(device)
	
	if "Nintendo" in joypad_name:
		play("nintendo")
	elif "DualShock" in joypad_name || "PS"in joypad_name:
		play("PlayStation")
	else:
		play("Xbox")
