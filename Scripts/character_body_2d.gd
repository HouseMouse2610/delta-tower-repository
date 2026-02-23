extends CharacterBody2D

# -------------------- TIMERS & NODES --------------------
@onready var CoyoteTimer : Timer = $CoyoteTimer
@onready var JumpBufferTimer : Timer = $JumpBufferTimer
@onready var attack_timer : Timer = $AttackTimer
@onready var attack_buffer_timer : Timer = $AttackBufferTimer
@onready var dash_timer : Timer = $DashTimer

@onready var sprite = $PlayerAnimation
@onready var attack_hitbox = $AttackArea/CollisionAttack
@onready var attack_sound = $AttackSound

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
	logica_de_movimentacao_horizontal(delta)
	lógica_de_dash()
	logica_de_ataque()
	logica_de_gravidade(delta)
	logica_de_pulo()
	atualizar_visual()
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
	# ---------------- INPUT BUFFER ----------------
	if Input.is_action_just_pressed("Jump"):
		JumpBufferTimer.start()
		

	# ---------------- JUMP ----------------
	if not JumpBufferTimer.is_stopped() and not is_attack:
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
				JumpBufferTimer.stop()

	# ---------------- SHORT HOP ----------------
	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y *= 0.5

func logica_de_ataque():
	if is_on_floor():
		air_attack_count = 0
		
	# ---------------- INPUT BUFFER ----------------
	if Input.is_action_just_pressed("Attack"):
		attack_buffer_timer.start()
		
	# ---------------- EXECUTAR ATAQUE ----------------
	if not attack_buffer_timer.is_stopped() and not is_attack and not is_dash:
		if is_on_floor():
			attack_sound.pitch_scale = randf_range(0.9, 1.1)
			attack_sound.play()
			is_attack = true
			attack_timer.start()
			attack_buffer_timer.stop()
			toggle_hitbox(false)
			if not is_dash:
				velocity.x = 0
			
		
		elif air_attack_count < 1 and not is_dash:
			attack_sound.pitch_scale = randf_range(0.9, 1.1)
			attack_sound.play()
			is_attack = true
			attack_timer.start()
			attack_buffer_timer.stop()
			toggle_hitbox(false)
			velocity.y = -JUMP_FORCE * 0.6
			air_attack_count += 1
			max_dash = 1
			sprite.scale = Vector2(1.4, 0.8)
			create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.1)

func handle_head_nudge():
	pass

func aplicar_squash_stretch():
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
	if is_dash:
		sprite.play("Dash")
	if is_attack and not is_dash:
		if is_on_floor() and sprite.animation == "Air Attack":
			is_attack = false
		else:
			if is_on_floor() and not is_dash:
				sprite.play("Attack")
			elif not is_on_floor() and not is_dash:
				sprite.play("Air Attack")
		return

	if not is_on_floor() and not is_dash:
		if velocity.y < 0:
			sprite.play("Jump")
		else:
			sprite.play("Fall")
		return

	if abs(velocity.x) > 10 and not is_dash:
		sprite.play("Run")
	elif abs(velocity.x) == 0 and not is_dash:
		sprite.play("Idle")

func lógica_de_dash():
	
	if is_on_floor():
		max_dash = 1
	
	if not have_dash: return
	
	if Input.is_action_just_pressed("Dash") and not is_dash and not is_attack:
		if dash_timer.is_stopped() and (is_on_floor() or max_dash > 0):
			if not is_on_floor():
				max_dash = 0
			
			is_dash = true
			dash_timer.start()
			
			velocity.y = 0
			if sprite.flip_h:
				velocity.x = -DASH_FORCE
			else:
				velocity.x = DASH_FORCE
				
			toggle_hitbox(false)
