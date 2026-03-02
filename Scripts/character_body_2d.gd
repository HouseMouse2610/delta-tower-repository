extends CharacterBody2D

# -------------------- TIMERS & NODES --------------------
var buffer_time : float = 0.15
var jump_buffer_counter : float = 0
var dash_buffer_counter : float = 0
var attack_buffer_counter : float = 0
@onready var CoyoteTimer : Timer = $CoyoteTimer
@onready var attack_timer : Timer = $AttackTimer
@onready var dash_timer : Timer = $DashTimer

@onready var sprite = $PlayerAnimation
@onready var attack_hitbox = $AttackArea/CollisionAttack
@onready var attack_sound = $AttackSound
@onready var dust_particles = $GPUParticles2D

# -------------------- EXPORT VARIABLES --------------------
@export var SPEED : float = 75.0
@export var ACCELERATION : float = 750
@export var FRICTION : float = 1000
@export var GRAVITY : int = 600
@export var FALL_GRAVITY_MULTIPLIER : float = 1.2
@export var JUMP_FORCE : int = 220
@export var HEAD_NUDGE_SPEED : float = 35.0
@export var air_attack_count : int = 0
@export var max_health : float = 10.0
@export var current_health : float = 10.0
@export var max_jump_number : int = 1
@export var DASH_FORCE : int = 125
@export var COMBO_COUNTER : int = 0

# -------------------- STATE VARIABLES --------------------
var was_on_floor : bool = false
var is_attack : bool = false
var is_dash : bool = false
var have_dash : bool = true
var have_double_jump : bool = false
var have_down_attack : bool = false
var max_dash : int = 1

# -------------------- SIGNALS --------------------
func _on_attack_timer_timeout() -> void:
	is_attack = false
	toggle_hitbox(true)

func _on_player_animation_animation_finished() -> void:
	is_dash = false
	toggle_hitbox(true)

# -------------------- HITBOX --------------------
func toggle_hitbox(valor: bool):
	attack_hitbox.set_deferred("disabled", valor)

# -------------------- DAMAGE --------------------
func take_damage(amount: float):
	current_health -= amount
	current_health = clamp(current_health, 0, max_health)
	if current_health <= 0:
		print("faleceu")

# -------------------- PHYSICS --------------------
func _physics_process(delta):
	jump_buffer_counter = max(0, jump_buffer_counter - delta)
	dash_buffer_counter = max(0, dash_buffer_counter - delta)
	attack_buffer_counter = max(0, attack_buffer_counter - delta)
	
	if Input.is_action_just_pressed("Jump"):
		jump_buffer_counter = buffer_time
	if Input.is_action_just_pressed("Dash"):
		dash_buffer_counter = buffer_time
	if Input.is_action_just_pressed("Attack"):
		attack_buffer_counter = buffer_time
	
	logica_de_movimentacao_horizontal(delta)
	logica_de_dash()
	logica_de_ataque()
	logica_de_gravidade(delta)
	logica_de_pulo()
	atualizar_visual()
	aplicar_particulas()
	aplicar_squash_stretch()
	was_on_floor = is_on_floor()
	move_and_slide()

# -------------------- FUNÇÕES DE LÓGICA --------------------
func logica_de_movimentacao_horizontal(_delta):
	var direction = 0
	
	if not is_attack or not is_on_floor():
		direction = Input.get_axis("Left", "Right")
		
		# --- LÓGICA DE VELOCIDADE ---
		if not is_dash:
			if direction != 0:
				velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * _delta)
			else:
				velocity.x = move_toward(velocity.x, 0, FRICTION * _delta)
		
		# --- LÓGICA DE DIREÇÃO (FLIP E ATTACK AREA) ---
			if direction != 0:
				sprite.flip_h = (direction < 0)
				$AttackArea.position.x = abs($AttackArea.position.x) * direction
			
			if is_attack and is_on_floor() and not is_dash:
				velocity.x = move_toward(velocity.x, 0, FRICTION * _delta)
		return

func logica_de_gravidade(_delta):
	if is_dash:
		velocity.y = 0
		return
	
	if was_on_floor and not is_on_floor() and velocity.y >= 0:
		CoyoteTimer.start()
	if not is_on_floor():
		if velocity.y > 0:
			velocity.y += GRAVITY * FALL_GRAVITY_MULTIPLIER * _delta
		else:
			velocity.y += GRAVITY * _delta
	else:
		velocity.y = 0
		max_jump_number = 0
		CoyoteTimer.stop()

func logica_de_pulo():
	# ---------------- JUMP ----------------
	if jump_buffer_counter > 0 and not is_attack:
		if max_jump_number < 1:
			if is_on_floor() or not CoyoteTimer.is_stopped():
				velocity.y = -JUMP_FORCE
				max_jump_number += 1
				
				is_attack = false
				attack_timer.stop()
				toggle_hitbox(true)
				
				sprite.scale = Vector2(0.8, 1.2)
				create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.15)
				
				CoyoteTimer.stop()
				jump_buffer_counter = 0

	# ---------------- SHORT HOP ----------------
	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y *= 0.5

func logica_de_ataque():
	if is_on_floor():
		air_attack_count = 0
		
	# ---------------- EXECUTAR ATAQUE ----------------
	if attack_buffer_counter > 0 and not is_attack and not is_dash:
		if is_on_floor():
			attack_sound.pitch_scale = randf_range(0.9, 1.1)
			attack_sound.play()
			is_attack = true
			attack_timer.start()
			attack_buffer_counter = 0
			toggle_hitbox(false)
			
			COMBO_COUNTER = (COMBO_COUNTER + 1) % 2
			
			if not is_dash:
				velocity.x = 0
			
		elif air_attack_count < 1 and not is_dash:
			attack_sound.pitch_scale = randf_range(0.9, 1.1)
			attack_sound.play()
			is_attack = true
			attack_timer.start()
			attack_buffer_counter = 0
			toggle_hitbox(false)
			velocity.y = -JUMP_FORCE * 0.6
			air_attack_count += 1
			max_dash = 1
			sprite.scale = Vector2(1.4, 0.8)
			create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.1)

func aplicar_squash_stretch():
	if is_dash:
		return
	
	if is_on_floor() and not was_on_floor:
		sprite.scale = Vector2(1.15, 0.85)
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	if not is_on_floor() and not is_attack:
		var stretch_factor = clamp(abs(velocity.y) * 0.0005, 0.0, 0.1)
		sprite.scale.y = 1.0 + stretch_factor
		sprite.scale.x = 1.0 - stretch_factor
		
	if is_on_ceiling():
		sprite.scale = Vector2(1.3, 0.7)
		create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.1)

func atualizar_visual():
	# Lógica de Dash
	if is_dash:
		sprite.play("Dash")
		return
	
# 2. Lógica de Ataque
	if is_attack:
		if is_on_floor():
			var anim_alvo = "Attack 1" if COMBO_COUNTER == 1 else "Attack 2"
			if sprite.animation != anim_alvo:
				sprite.play(anim_alvo)
		else:
			if sprite.animation != "Air Attack":
				sprite.play("Air Attack")
		return
	
	# 3. Lógica de Movimentação Aérea
	if not is_on_floor():
		if velocity.y < 0:
			sprite.play("Jump")
		else:
			sprite.play("Fall")
		return

	# 4. Lógica de Movimentação no Chão
	if abs(velocity.x) > 10:
		sprite.play("Run")
	else:
		sprite.play("Idle")

func logica_de_dash():
	if is_on_floor():
		max_dash = 1
	
	if not have_dash: return
	
	if dash_buffer_counter > 0 and not is_dash and not is_attack:
		if dash_timer.is_stopped() and (is_on_floor() or max_dash > 0):
			if not is_on_floor():
				max_dash = 0
			
			is_dash = true
			dash_buffer_counter = 0
			dash_timer.start()
			
			# --- SQUASH AND STRETCH DO DASH ---
			sprite.scale = Vector2(1.4, 0.8)
			create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
			
			# --- DISPARAR RASTROS ---
			for i in range(6):
				var tempo_espera = i * 0.06
				get_tree().create_timer(tempo_espera).timeout.connect(criar_rastro)
			
			attack_sound.pitch_scale = randf_range(0.6, 0.8)
			attack_sound.play()
			
			velocity.y = 0
			if sprite.flip_h:
				velocity.x = -DASH_FORCE
			else:
				velocity.x = DASH_FORCE
				
			toggle_hitbox(false)

func criar_rastro():
	var ghost = Sprite2D.new()
	
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)	
	
	var offset = 5.0 if sprite.flip_h else -5.0
	
	ghost.global_position = global_position + Vector2(offset, 0)
	
	ghost.flip_h = sprite.flip_h
	ghost.scale = Vector2.ONE
	
	ghost.modulate = Color(0.2, 0.1, 0.1, 1.0)
	
	ghost.z_index = z_index - 1
	
	get_parent().add_child(ghost)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.4)
	tween.tween_property(ghost, "modulate:r", 0.0, 0.4)
	
	tween.set_parallel(false)
	tween.tween_callback(ghost.queue_free)

func aplicar_particulas():
	if is_on_floor() and abs(velocity.x) > 10:
		dust_particles.emitting = true
		
		if sprite.flip_h:
			dust_particles.process_material.direction = Vector3(1, -0.5, 0)
		else:
				dust_particles.process_material.direction = Vector3(-1, -0.5, 0) # Sopra para a esquerda
	else:
		dust_particles.emitting = false
