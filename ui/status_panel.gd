class_name StatusPanel
extends HBoxContainer

@export var stats:Stats
@onready var health_bar: TextureProgressBar = $VBoxContainer/HealthBar
@onready var eased_health_bar: TextureProgressBar = $VBoxContainer/HealthBar/EasedHealthBar
@onready var energy_bar: TextureProgressBar = $VBoxContainer/EnergyBar


func _ready() -> void:
	if !stats:
		stats=Game.player_stats
	
	stats.health_changed.connect(update_health)
	update_health(1)
	
	stats.energy_changed.connect(update_energy)
	update_energy()
	
	
	tree_exited.connect(func():
		stats.health_changed.disconnect(update_health)
		stats.energy_changed.disconnect(update_energy)
		)

func update_health(skip_animation:=false):
	var	percentage := stats.health/float(stats.max_health)
	health_bar.value=percentage
	
	if skip_animation:
		eased_health_bar.value=percentage
	else:
		create_tween().tween_property(eased_health_bar,"value",percentage,0.3)
	

func update_energy():
	var percentage := stats.energy/stats.max_energy
	create_tween().tween_property(energy_bar,"value",percentage,0.3)
	
