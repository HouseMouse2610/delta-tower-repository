extends CharacterBody2D

@onready var CoyoteTimer : Timer = $CoyoteTimer
@onready var JumpBufferTimer : Timer = $JumpBufferTimer
@onready var ray_left = $RayLeft
@onready var ray_right = $RayRight
@onready var attack_hitbox = $AttackArea/CollisionAttack
@onready var attack_sound = $AttackSound
@onready var attack_timer = $AttackTimer
@onready var attack_buffer_timer = $AttackBufferTimer



@export var SPEED : float = 80.0
@export var ACCELERATION : float = 1000.0
@export var FRICTION : float = 1200.0
@export var GRAVITY : int = 650
@export var FALL_GRAVITY_MULTIPLIER : float = 1.2
@export var JUMP_FORCE : int = 225
@export var HEAD_NUDGE_SPEED : float = 50.0 
@export var air_attack_count : int = 0




var was_on_floor : bool = false
var is_attack : bool = false







func _physics_process(delta):
	
	# --- LÓGICA DE MOVIMENTAÇÃO HORIZONTAL ---
	
	var direction = 0
	
	if not is_attack or not is_on_floor():
		direction = Input.get_axis("Left", "Right") 
		
		
		
	
		if direction != 0:
			
			velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
			if is_on_floor(): $AnimatedSprite2D.play("Run") 
		
			if direction > 0:
				$AttackArea.position.x = abs($AttackArea.position.x)  
			elif direction < 0:
				$AttackArea.position.x = -abs($AttackArea.position.x) 
		
		
		
		else:
			
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			if is_on_floor(): $AnimatedSprite2D.play("Idle")
	
		if direction != 0:
		
			$AnimatedSprite2D.flip_h = (direction < 0)
	
	
	# --- LÓGICA DE GRAVIDADE ---
	
	if not is_on_floor():
		
		
		
		
		var current_gravity = GRAVITY
		
		
		if velocity.y > 0:
			current_gravity = GRAVITY * FALL_GRAVITY_MULTIPLIER
		
		if abs(velocity.y) < 15:
			current_gravity = GRAVITY * 0.4
		
		velocity.y += current_gravity * delta
		
		
		
		
		if was_on_floor and velocity.y >= 0:
			
			CoyoteTimer.start()
		
		if velocity.y > 0 and not is_attack:
			
			$AnimatedSprite2D.play("Fall")
		

	
	# --- LÓGICA DE PULO ---
	
	if Input.is_action_just_pressed("Jump"):
		
		JumpBufferTimer.start()
	
	
	if JumpBufferTimer.time_left > 0 and (is_on_floor() or CoyoteTimer.time_left > 0) and not is_attack:
		 
		velocity.y = -JUMP_FORCE
		$AnimatedSprite2D.play("Jump")
		JumpBufferTimer.stop()
		CoyoteTimer.stop()
	
	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y *= 0.5
	
	
	
	
	
	
	
	# --- LÓGICA DE ATAQUE ---
	
	if Input.is_action_just_pressed("Attack"):
		attack_buffer_timer.start()
		
	if attack_buffer_timer.time_left > 0 and not is_attack and (is_on_floor() or air_attack_count < 1) :
		attack_buffer_timer.stop()
		velocity.x = 0
		is_attack = true
		attack_timer.start()
		toggle_hitbox(false)
		attack_sound.pitch_scale = randf_range(0.9, 1.1)
		attack_sound.play()
		
		
		
		if not is_on_floor() or velocity.y != 0:
			if air_attack_count < 1:
				
				velocity.y = -150
				air_attack_count += 1
			$AnimatedSprite2D.play("Air Attack")
		else:
					$AnimatedSprite2D.play("Attack")
			
			
			
			
			
		
		
	
	
	
	
	
	if is_on_ceiling() and velocity.y < 0:
		handle_head_nudge()
	was_on_floor = is_on_floor()
	
	if is_on_floor():
		air_attack_count = 0
		
	
	
	
	
	
	move_and_slide()
	
	
func handle_head_nudge():
	
	
	
	
		velocity.y = 0 
	
	
	
	
		var _left_hit = ray_left.is_colliding()
		var _right_hit = ray_right.is_colliding()
	
		if _left_hit and not _right_hit:
			global_position.x += 200.0
			velocity.x = HEAD_NUDGE_SPEED
	
		elif _right_hit and not _left_hit:
			global_position.x -= 200.0
			velocity.x = -HEAD_NUDGE_SPEED
	



func toggle_hitbox(valor: bool):
		
		attack_hitbox.set_deferred("disabled", valor)


func _on_attack_timer_timeout() -> void:
	is_attack = false
	toggle_hitbox(true) 
