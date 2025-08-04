class_name Interactable
extends Area2D

signal interacted

func _init() -> void:
	collision_layer=0
	collision_mask=0
	set_collision_mask_value(2,true)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	

func interact():
	interacted.emit()

func _on_body_entered(player:Player):
	player.register_interactabel(self)

func _on_body_exited(player:Player):
	player.unregister_interactable(self)
