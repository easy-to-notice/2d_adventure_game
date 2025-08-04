class_name EntryPoint
extends Marker2D

@export var direction :=Player.Direction.Right

func _ready() -> void:
	add_to_group("entry_points")
