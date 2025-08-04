extends Enemy

enum State{
	Idle,
	Walk,
	Run,
	Hurt,
	Dying
}

const KNOCKBACK_AMOUNT := 500.0

@onready var wall_checker: RayCast2D = $Graphics/WallChecker
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
@onready var calm_timer: Timer = $CalmTimer
@onready var stats: Stats = $Stats

var pending_damage :Damage

func tick_phisics(state: State,delta :float) -> void:
	match state:
		State.Idle,State.Hurt,State.Dying:
			move(0.0,delta)
			
		State.Walk:
			move(max_speed/3,delta)
			
		State.Run:
			if wall_checker.is_colliding() || !floor_checker.is_colliding():
				direction*=-1
			move(max_speed,delta)
			if can_see_player():
				calm_timer.start()

func can_see_player() -> bool:
	if !player_checker.is_colliding():
		return false
	return player_checker.get_collider() is Player
	

func get_next_state(state :State) -> int:
	if !stats.health:
		
		return State.Dying if state != State.Dying else StateMachine.KEEP_CURRENT
	if pending_damage:
		return State.Hurt
	
	match state:
		State.Idle:
			if can_see_player():
				return State.Run
			if state_machine.state_time > 2:
				return State.Walk
		State.Walk:
			if can_see_player():
				return State.Run
			if wall_checker.is_colliding() || !floor_checker.is_colliding():
				return State.Idle
		State.Run:
			if !can_see_player() && calm_timer.is_stopped():
				return State.Walk
		State.Hurt:
			if !animation_player.is_playing():
				return State.Run
				
	
	return state_machine.KEEP_CURRENT
	

func transition_state(from: State,to: State) -> void:
	match to:
		State.Idle:
			animation_player.play("idle")
			if wall_checker.is_colliding():
				direction *= -1
				
			
		State.Walk:
			animation_player.play("walk")
			if !floor_checker.is_colliding():
				direction *= -1
			floor_checker.force_raycast_update()
			
		State.Run:
			animation_player.play("run")
			
		State.Hurt:
			animation_player.play("hit")
			
			stats.health-=pending_damage.amount
			
			var dir:=pending_damage.source.global_position.direction_to(global_position)
			velocity.x=dir.x*KNOCKBACK_AMOUNT
			if dir.x>0:
				direction=Direction.Left
			else:
				direction=Direction.Right
			pending_damage=null
			
		State.Dying:
			animation_player.play("die")
			


func _on_hurtbox_hurt(hitbox: Variant) -> void:
	
	pending_damage = Damage.new()
	pending_damage.amount=1;
	pending_damage.source=hitbox.owner

