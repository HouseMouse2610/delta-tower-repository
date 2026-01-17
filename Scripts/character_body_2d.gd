extends CharacterBody2D

@onready var CoyoteTimer : Timer = $CoyoteTimer
@onready var JumpBufferTimer : Timer = $JumpBufferTimer
@onready var ray_left = $RayLeft
@onready var ray_right = $RayRight
@onready var attack_hitbox = $AttackArea/CollisionAttack
@onready var attack_sound = $AttackSound



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
		direction = Input.get_axis("Left", "Right") # Diz que Left é negativo e Right é positivo
		
		
		
	
		if direction != 0:
			# Caso a Direção seja diferente de 0,ele vai se mover horizontalmente, em que Left se torna X negativo e right se torna  X positivoo
			velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
			if is_on_floor(): $AnimatedSprite2D.play("Run") # Caso esteja no chão, equanto se move horizontalmente aplicará a animação run
		
			if direction > 0:
				$AttackArea.position.x = abs($AttackArea.position.x)  
			elif direction < 0:
				$AttackArea.position.x = -abs($AttackArea.position.x) 
		
		
		
		else:
			# Caso direction for igual a 0 e estiver no chão, aplicará a animação Idle
			velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
			if is_on_floor(): $AnimatedSprite2D.play("Idle")
	
		if direction != 0:
		# Caso a direction for diferente e menor que 0, vira ao contrário
			$AnimatedSprite2D.flip_h = (direction < 0)
	
	
	# --- LÓGICA DE GRAVIDADE ---
	
	if not is_on_floor():
		
		
		
		
		var current_gravity = GRAVITY
		
		# Caso não estiver no chão, a posição y será somada a gravidade * delta(por segundo), portanto, a gravidade puxa para baixo
		if velocity.y > 0:
			current_gravity = GRAVITY * FALL_GRAVITY_MULTIPLIER
		
		if abs(velocity.y) < 15:
			current_gravity = GRAVITY * 0.4
		
		velocity.y += current_gravity * delta
		
		
		
		
		if was_on_floor and velocity.y >= 0:
			# Caso não estiver no chão e a velocidade y for maior ou igual a 0, o coyotetimer começa
			CoyoteTimer.start()
		
		if velocity.y > 0 and not is_attack:
			# Caso a velocidade y for maior que 0, aplica a animação fall
			$AnimatedSprite2D.play("Fall")
		

	
	# --- LÓGICA DE PULO ---
	
	if Input.is_action_just_pressed("Jump"):
		# Caso o input Jump for precionado, o jumpbuffertimer começa
		JumpBufferTimer.start()
	
	
	if JumpBufferTimer.time_left > 0 and (is_on_floor() or CoyoteTimer.time_left > 0) and not is_attack:
		# Caso o jogador ainda possa pular, a jump force será negativa, e portanto irá para cima, além de aplicar a animação de pulo e encerrar os cronometros
		velocity.y = -JUMP_FORCE
		$AnimatedSprite2D.play("Jump")
		JumpBufferTimer.stop()
		CoyoteTimer.stop()
	
	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y *= 0.5
	
	
	
	if Input.is_action_just_pressed("Attack") and not is_attack:
		velocity.x = 0
		is_attack = true
		toggle_hitbox(false)
		attack_sound.pitch_scale = randf_range(0.85, 1.15)
		attack_sound.play()
		
		$AnimatedSprite2D.play("Attack")
		if not is_on_floor():
			if air_attack_count < 1:
			
				velocity.y = -150
				air_attack_count += 1
			
			$AnimatedSprite2D.play("Air Attack")
			
			
			
			
			
		
		
	
	
	
	
	
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



func _on_animated_sprite_2d_animation_finished() -> void:
	if $AnimatedSprite2D.animation == "Attack" or $AnimatedSprite2D.animation == "Air Attack": is_attack = false
	
	is_attack = false
	toggle_hitbox(true) 
