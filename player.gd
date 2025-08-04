class_name Player
extends CharacterBody2D

enum Direction{
	Left=-1,
	Right=1,
}

enum State{
	IDLE,
	RUNNING,
	JUMP,
	FALL,
	LANDING,
	WALL_SLIDING,
	WALL_JUMP,
	Attack_1,
	Attack_2,
	Attack_3,
	Hurt,
	Dying,
	Slide_start,
	Slide_loop,
	Slide_end
}

const GROUND_STATES := [
	State.IDLE, State.RUNNING,State.LANDING,
	State.Attack_1,State.Attack_2,State.Attack_3
]
const RUN_SPEED := 160.0
const JUMP_SPEED := -320.0
const WALL_JUMP_SPEED := Vector2(700,-320)
const FLOOR_ACCELERATION := RUN_SPEED/0.02
const AIR_ACCELERATION := RUN_SPEED/0.02
const KNOCKBACK_AMOUNT := 1000.0
const SLIDE_DURATION := 0.25
const SLIDE_SPEED := 320.0
const SLIDE_ENERGY := 4.0
const LANING_HEIGHT := 150.0

@export var can_combo := false
@export var direction := Direction.Right:
	set(v):
		direction=v
		if !is_node_ready():
			await ready
		graphics.scale.x=direction
var default_gravity :=ProjectSettings.get("physics/2d/default_gravity") as float
var is_first_tick := false
var is_combo_requested := false
var pending_damage :Damage
var fall_from_y :float
var interacting_with :Array[Interactable]

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $CoyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var hand_checker: RayCast2D = $Graphics/HandChecker
@onready var foot_checker: RayCast2D = $Graphics/FootChecker
@onready var state_machine: StateMachine = $StateMachine
@onready var stats: Stats = Game.player_stats
@onready var invincible_timer: Timer = $InvincibleTimer
@onready var slide_request_timer: Timer = $SlideRequestTimer
@onready var interaction_icon: AnimatedSprite2D = $InteractionIcon
@onready var game_over_screen: Control = $CanvasLayer/GameOverScreen
@onready var pause_scene: Control = $CanvasLayer/PauseScene



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	if event.is_action_released("jump"):
		jump_request_timer.stop()
		if velocity.y < JUMP_SPEED / 2:
			velocity.y=JUMP_SPEED/2
	if event.is_action_pressed("attack") && can_combo:
		is_combo_requested = true
	if event.is_action_pressed("slide"):
		slide_request_timer.start()
	if event.is_action_pressed("interact")&&interacting_with:
		interacting_with.back().interact()
		unregister_interactable(interacting_with.back())
	if event.is_action_pressed("pause"):
		pause_scene.show_pause()

func tick_phisics(state :State, delta: float) -> void:
	interaction_icon.visible=!interacting_with.is_empty()
	
	if invincible_timer.time_left>0:
		graphics.modulate.a=sin(Time.get_ticks_msec()/45)*0.5+0.5
	else:
		graphics.modulate.a=1
	
	match state:
		State.IDLE:
			move(default_gravity,delta)
			
		State.RUNNING:
			move(default_gravity,delta)
			
		State.JUMP:
			move(0.0 if is_first_tick else default_gravity,delta)
			
		State.FALL:
			move(default_gravity,delta)
			
		State.LANDING:
			stand(default_gravity, delta)
			
		State.WALL_SLIDING:
			wall_slide(delta)
			
		State.WALL_JUMP:
			if(state_machine.state_time < 0.05):
				stand(0.0 if is_first_tick else default_gravity,delta)
			else:
				move(0.0 if is_first_tick else default_gravity,delta)
				
		State.Attack_1,State.Attack_2,State.Attack_3:
			stand(default_gravity,delta)
			
		State.Hurt,State.Dying:
			stand(default_gravity,delta)
		
		State.Slide_end:
			stand(default_gravity,delta)
		
		State.Slide_start,State.Slide_loop:
			slide(delta)
		
	
	is_first_tick = false

func slide(delta:float):
	velocity.x=graphics.scale.x*SLIDE_SPEED
	velocity.y+=default_gravity*delta
	
	move_and_slide()

func wall_slide(delta :float):
	var movement := Input.get_axis("move_left", "move_right")
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x=move_toward(velocity.x,movement*RUN_SPEED,acceleration*delta)
	velocity.y = move_toward(velocity.y, 200, default_gravity/3*delta)
	
	move_and_slide()
	
func move(gravity: float, delta :float):
	var movement := Input.get_axis("move_left", "move_right")
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x=move_toward(velocity.x,movement*RUN_SPEED,acceleration*delta)
	velocity.y+=gravity*delta
	
	if (!is_zero_approx(movement)):
		direction = Direction.Left if movement < 0 else Direction.Right
	
	move_and_slide()

func stand(gravity :float,delta :float) -> void:
	var acceleration := FLOOR_ACCELERATION if is_on_floor() else AIR_ACCELERATION
	velocity.x=move_toward(velocity.x,0.0,acceleration*delta)
	velocity.y+=gravity*delta
	
	move_and_slide()

func die():
	game_over_screen.show_game_over()

func register_interactabel(v:Interactable):
	if state_machine.current_state==State.Dying:
		return
	if v in interacting_with:
		return
	interacting_with.append(v)

func unregister_interactable(v:Interactable):
	interacting_with.erase(v)

func can_wall_slide() -> bool:
	return hand_checker.is_colliding() || foot_checker.is_colliding()
	

@onready var foot_checker_back: RayCast2D = $Graphics/FootChecker_back
@onready var hand_checker_back: RayCast2D = $Graphics/HandChecker_back
func can_still_slide() -> bool:
	return hand_checker_back.is_colliding() || foot_checker_back.is_colliding()

func should_slide() -> bool:
	if slide_request_timer.is_stopped()||stats.energy<SLIDE_ENERGY:
		return false
	return !foot_checker.is_colliding()

func get_next_state(state: State) -> int:
	if !stats.health:
		return State.Dying if state != State.Dying else StateMachine.KEEP_CURRENT
	if pending_damage:
		return State.Hurt
	
	var should_jump := is_on_floor() && jump_request_timer.time_left > 0
	if should_jump:
		return State.JUMP
		
	var movement := Input.get_axis("move_left", "move_right")
	var is_still := is_zero_approx(movement)&& is_zero_approx(velocity.x)
	
	if !is_on_floor() && state in GROUND_STATES:
		return State.FALL
	
	match state:
		State.IDLE:
			if Input.is_action_just_pressed("attack"):
				return State.Attack_1
			if should_slide():
				return State.Slide_start
			if !is_still:
				return State.RUNNING
			
		State.RUNNING:
			if Input.is_action_just_pressed("attack"):
				return State.Attack_1
			if should_slide():
				return State.Slide_start
			if is_still:
				return State.IDLE
			
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
			
		State.FALL:
			if is_on_floor():
				var height=global_position.y-fall_from_y
				return State.LANDING if height>=LANING_HEIGHT else State.RUNNING
			if is_on_wall():
				velocity.y = min(velocity.y,200)
				return State.WALL_SLIDING
		
		State.LANDING:
			if !animation_player.is_playing():
				return State.IDLE
			
		State.WALL_SLIDING:
			if jump_request_timer.time_left > 0:
				return State.WALL_JUMP
			if is_on_floor():
				return State.IDLE
			if !is_on_wall():
				return State.FALL
				
		State.WALL_JUMP:
			if velocity.y >= 0:
				return State.FALL
				
		State.Attack_1:
			if !animation_player.is_playing():
				return State.Attack_2 if is_combo_requested else State.IDLE				
		
		State.Attack_2:
			if !animation_player.is_playing():
				return State.Attack_3 if is_combo_requested else State.IDLE				
				
		State.Hurt:
			if !animation_player.is_playing():
				return State.IDLE
		State.Attack_3:
			if !animation_player.is_playing():
				return State.IDLE
		
		State.Slide_start:
			if !animation_player.is_playing():
				return State.Slide_loop
				
		State.Slide_end:
			if !animation_player.is_playing():
				return State.IDLE
				
		State.Slide_loop:
			if state_machine.state_time>SLIDE_DURATION || is_on_wall():
				return State.Slide_end
		
		
	return StateMachine.KEEP_CURRENT
	
func transition_state(from: State,to: State):
	
	if !from in GROUND_STATES && to in GROUND_STATES:
		coyote_timer.stop()
	match to:
		State.IDLE:
			animation_player.play("idle")
			
		State.RUNNING:
			animation_player.play("running")
			
			
		State.JUMP:
			velocity.y=JUMP_SPEED
			coyote_timer.stop()
			jump_request_timer.stop()
			animation_player.play("jump")
			SoundManager.play_sfx("Jump")
			
			
		State.FALL:
			animation_player.play("fall")
			if from in GROUND_STATES:
				coyote_timer.start()
			fall_from_y=global_position.y
				
		State.LANDING:
			animation_player.play("landing")
			
		State.WALL_SLIDING:
			animation_player.play("wall_sliding")
			direction=Direction.Left if get_wall_normal().x<0 else Direction.Right
			
		State.WALL_JUMP:
			velocity = WALL_JUMP_SPEED
			velocity.x *= get_wall_normal().x
			jump_request_timer.stop()
			animation_player.play("jump")
			SoundManager.play_sfx("Jump")
		
		State.Attack_1:
			animation_player.play("attack_1")
			is_combo_requested = false
			SoundManager.play_sfx("Attack")
			
		State.Attack_2:
			animation_player.play("attack_2")
			is_combo_requested = false
			SoundManager.play_sfx("Attack2")
			
		State.Attack_3:
			animation_player.play("attack_3")
			is_combo_requested = false
			SoundManager.play_sfx("Attack3")
			
		State.Hurt:
			invincible_timer.start()
			animation_player.play("hurt")
			Game.shake_camera(4)
			SoundManager.play_sfx("Hurt")
			
			stats.health-=pending_damage.amount
			
			var dir:=pending_damage.source.global_position.direction_to(global_position)
			velocity.x=dir.x*KNOCKBACK_AMOUNT
			if dir.x>0:
				direction = Direction.Left
			else:
				direction = Direction.Right
			pending_damage=null
		
		State.Dying:
			animation_player.play("die")
			invincible_timer.stop()
			interacting_with.clear()
			SoundManager.play_sfx("Death")
		
		State.Slide_start:
			animation_player.play("slide_start")
			slide_request_timer.stop()
			stats.energy -= SLIDE_ENERGY
			SoundManager.play_sfx("Slide")
			
		State.Slide_loop:
			animation_player.play("slide_loop")
			
		State.Slide_end:
			animation_player.play("slide_end")
	
	is_first_tick = true
	


func _on_hurtbox_hurt(hitbox: Variant) -> void:
	if invincible_timer.time_left > 0:
		return
	
	pending_damage = Damage.new()
	pending_damage.amount=1;
	pending_damage.source=hitbox.owner


func _on_hitbox_hit(hurtbox: Variant) -> void:
	Game.shake_camera(2)
	
	Engine.time_scale=0.01
	SoundManager.play_sfx("Hit")
	await get_tree().create_timer(0.05,true,false,true).timeout
	Engine.time_scale=1
