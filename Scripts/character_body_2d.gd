class_name Player

extends CharacterBody2D

# -------------------- TIMERS & NODES --------------------
var buffer_time : float = 0.15
var jump_buffer_counter : float = 0
var dash_buffer_counter : float = 0
var attack_buffer_counter : float = 0
var jump_count : int = 0
@onready var CoyoteTimer : Timer = $CoyoteTimer
@onready var attack_timer : Timer = $AttackTimer
@onready var dash_timer : Timer = $DashTimer
@onready var dash_cooldown : Timer = $DashCooldownTimer

@onready var sprite = $PlayerAnimation
@onready var anim_data = $PlayerAnimation.sprite_frames
@onready var attack_hitbox = $AttackArea/CollisionAttack
@onready var attack_sound = $AttackSound
@onready var parent = get_parent()

# -------------------- EXPORT VARIABLES --------------------
@export var SPEED : float = 75.0
@export var ACCELERATION : float = 750
@export var FRICTION : float = 1000
@export var GRAVITY : int = 600
@export var FALL_GRAVITY_MULTIPLIER : float = 1.2
@export var JUMP_FORCE : int = 220
@export var air_attack_count : int = 0
@export var max_health : float = 10.0
@export var current_health : float = 10.0
@export var max_jump_number : int = 1
@export var DASH_FORCE : int = 125
@export var COMBO_COUNTER : int = 0

# -------------------- STATE VARIABLES --------------------
var was_on_floor : bool = false
var have_dash : bool = true
var have_double_jump : bool = false
var have_down_attack : bool = false
var max_dash : int = 1

# -------------------- STATE MACHINE --------------------
enum States { IDLE, RUN, JUMP, FALL, ATTACK, DASH }
var current_state : States = States.IDLE

# -------------------- SIGNALS --------------------
func _on_attack_timer_timeout() -> void:
	change_state(States.IDLE)

func _on_player_animation_animation_finished() -> void:
	toggle_hitbox(true)
	if current_state == States.ATTACK:
		change_state(States.IDLE)

func _on_dash_timer_timeout() -> void:
	if is_on_floor():
		change_state(States.IDLE)
	else:
		change_state(States.FALL)

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
func _ready():
	var cache = Sprite2D.new()
	cache.texture = anim_data.get_frame_texture("Idle", 0)
	cache.modulate.a = 0
	add_child(cache)
	attack_sound.volume_db = -80
	attack_sound.play()
	await get_tree().create_timer(0.1).timeout
	attack_sound.stop()
	attack_sound.volume_db = 0
	cache.queue_free()

func _physics_process(delta):
	atualizar_buffers(delta)
	
	if Input.is_action_just_released("Jump") and velocity.y < 0:
		velocity.y *= 0.5
	
	if current_state != States.DASH:
		aplicar_gravidade_custom(delta)
	
	match current_state:
		States.IDLE: logic_idle(delta)
		States.RUN: logic_run(delta)
		States.JUMP: logic_jump(delta)
		States.FALL: logic_fall(delta)
		States.ATTACK: logic_attack(delta)
		States.DASH: logic_dash(delta)
	
	atualizar_visual()
	aplicar_squash_stretch()
	was_on_floor = is_on_floor()
	move_and_slide()
	atualizar_debug_hud()

# -------------------- FUNÇÕES DE LÓGICA --------------------
func aplicar_squash_stretch():
	if is_on_floor() and not was_on_floor:
		sprite.scale = Vector2(1.15, 0.85)
		var tween = create_tween()
		tween.tween_property(sprite, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	if not is_on_floor():
		var stretch_factor = clamp(abs(velocity.y) * 0.0005, 0.0, 0.1)
		sprite.scale.y = 1.0 + stretch_factor
		sprite.scale.x = 1.0 - stretch_factor
		
	if is_on_ceiling():
		sprite.scale = Vector2(1.3, 0.7)
		create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.1)

func atualizar_visual():
	match current_state:
		States.IDLE:
			sprite.play("Idle")
		States.RUN:
			sprite.play("Run")
		States.JUMP:
			sprite.play("Jump")
		States.FALL:
			sprite.play("Fall")
		States.DASH:
			sprite.play("Dash")
		States.ATTACK:
			if sprite.animation == "Air Attack":
				return
			if is_on_floor():
				var anim_alvo = "Attack 1" if COMBO_COUNTER == 1 else "Attack 2"
				sprite.play(anim_alvo)
			else:
				sprite.play("Air Attack")

func logica_de_dash():
	if have_dash:
		max_dash = 0
		dash_buffer_counter = 0
		dash_timer.start(0.2) # Duração do movimento (curto)
		dash_cooldown.start(0.6)
		
		# Efeitos Visuais e Sonoros
		sprite.scale = Vector2(1.4, 0.8)
		create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.2)
		
		for i in range(12):
			get_tree().create_timer(i * 0.03).timeout.connect(criar_rastro)
		
		attack_sound.pitch_scale = randf_range(0.6, 0.8)
		attack_sound.play()
		
		# Física do Dash
		velocity.y = 0
		velocity.x = -DASH_FORCE if sprite.flip_h else DASH_FORCE
		toggle_hitbox(false)

func criar_rastro():
	if not is_instance_valid(self) or not is_inside_tree(): return
	var ghost = Sprite2D.new()
	
	ghost.texture = anim_data.get_frame_texture(sprite.animation, sprite.frame)
	
	var offset = 3.0 if sprite.flip_h else -3.0
	
	ghost.global_position = global_position + Vector2(offset, 0)
	
	ghost.flip_h = sprite.flip_h
	ghost.scale = Vector2.ONE
	
	ghost.modulate = Color(0.2, 0.1, 0.1, 1.0)
	
	ghost.z_index = z_index - 1
	
	parent.add_child(ghost)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.4)
	tween.tween_property(ghost, "modulate:r", 0.0, 0.4)
	
	tween.set_parallel(false)
	tween.tween_callback(ghost.queue_free)

func atualizar_buffers(delta):
	jump_buffer_counter = max(0, jump_buffer_counter - delta)
	dash_buffer_counter = max(0, dash_buffer_counter - delta)
	attack_buffer_counter = max(0, attack_buffer_counter - delta)
	
	if Input.is_action_just_pressed("Jump"):
		jump_buffer_counter = buffer_time
	if Input.is_action_just_pressed("Dash"):
		dash_buffer_counter = buffer_time
	if Input.is_action_just_pressed("Attack"):
		attack_buffer_counter = buffer_time

func change_state(new_state: States):
	if current_state == States.ATTACK and new_state == States.ATTACK:
		if not is_on_floor(): 
			return
	
	if current_state == new_state: return
	
	# SAÍDA do Estado Antigo
	match current_state:
		States.DASH:
			toggle_hitbox(true)
			dash_timer.stop()
		States.ATTACK:
			toggle_hitbox(true)
			attack_timer.stop()
			
	current_state = new_state
	
	match current_state:
		States.IDLE:
			pass
		States.JUMP:
			jump_buffer_counter = 0
			jump_count += 1
			velocity.y = -JUMP_FORCE
			sprite.scale = Vector2(0.8, 1.2)
			create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.15)
		States.DASH:
			logica_de_dash()
		States.ATTACK:
			attack_buffer_counter = 0
			
			if not is_on_floor():
				air_attack_count += 1
				velocity.y = 0
				velocity.y = -JUMP_FORCE * 0.5
			
			attack_sound.pitch_scale = randf_range(0.9, 1.1)
			attack_sound.play()
			attack_timer.start()
			toggle_hitbox(false)
			COMBO_COUNTER = (COMBO_COUNTER + 1) % 2

func logic_idle(delta):
	velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	if Input.get_axis("Left", "Right") != 0:
		change_state(States.RUN)
	elif jump_buffer_counter > 0:
		change_state(States.JUMP)
	elif attack_buffer_counter > 0:
		change_state(States.ATTACK)
	elif dash_buffer_counter > 0 and have_dash and max_dash > 0 and dash_cooldown.is_stopped():
		change_state(States.DASH)
	elif not is_on_floor():
		change_state(States.FALL)

func logic_run(delta):
	var dir = Input.get_axis("Left", "Right")
	velocity.x = move_toward(velocity.x, dir * SPEED, ACCELERATION * delta)
	
	if dir != 0:
		sprite.flip_h = (dir < 0)
		$AttackArea.position.x = abs($AttackArea.position.x) * dir
	
	if dir == 0:
		change_state(States.IDLE)
	elif jump_buffer_counter > 0:
		change_state(States.JUMP)
	elif attack_buffer_counter > 0:
		change_state(States.ATTACK)
	elif dash_buffer_counter > 0 and have_dash and max_dash > 0 and dash_cooldown.is_stopped():
		change_state(States.DASH)
	elif not is_on_floor():
		change_state(States.FALL)

func logic_jump(_delta):
	processar_movimento_aereo(_delta)
	if jump_buffer_counter > 0 and have_double_jump and jump_count < 2:
		change_state(States.JUMP)
		return
	
	if velocity.y >= 0:
		change_state(States.FALL)
		
	if attack_buffer_counter > 0:
		if air_attack_count == 0: # Se ainda não atacou no ar, pode atacar
			change_state(States.ATTACK)
			
	elif dash_buffer_counter > 0 and have_dash and max_dash > 0 and dash_cooldown.is_stopped():
		change_state(States.DASH)

func logic_fall(_delta):
	processar_movimento_aereo(_delta)
	
	if is_on_floor():
		change_state(States.IDLE)
	
	# Se apertar pulo e o Timer do Coyote ainda estiver ativo, pula.
	elif jump_buffer_counter > 0:
		if not CoyoteTimer.is_stopped():
			CoyoteTimer.stop()
			change_state(States.JUMP)
		elif have_double_jump and jump_count < 2:
			change_state(States.JUMP)
		
	elif dash_buffer_counter > 0 and have_dash and max_dash > 0 and dash_cooldown.is_stopped():
		change_state(States.DASH)
	elif attack_buffer_counter > 0:
		if is_on_floor() or air_attack_count == 0:
			change_state(States.ATTACK)

func logic_dash(_delta):
	# O Dash é controlado pelo DashTimer ou Animação
	# Apenas mantemos a velocidade constante se quiser
	pass

func logic_attack(_delta):
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, FRICTION * _delta)
		if sprite.animation == "Air Attack":
			change_state(States.IDLE)
	else:
		# ADICIONE ESTA LINHA: Permite mover-se horizontalmente durante o ataque aéreo
		processar_movimento_aereo(_delta)
		
		# Mantém a sua trava de segurança para não repetir o ataque
		if attack_buffer_counter > 0:
			attack_buffer_counter = 0

func processar_movimento_aereo(delta):
	var dir = Input.get_axis("Left", "Right")
	velocity.x = move_toward(velocity.x, dir * SPEED, ACCELERATION * delta)
	if dir != 0:
		sprite.flip_h = (dir < 0)
		$AttackArea.position.x = abs($AttackArea.position.x) * dir

func aplicar_gravidade_custom(delta):
	if is_on_floor():
		if have_dash:
			max_dash = 1
		else:
			max_dash = 0
		air_attack_count = 0
		jump_count = 0
		# Reset de pulos se você tiver double jump futuramente
	else:
		if was_on_floor and velocity.y >= 0:
			CoyoteTimer.start()
		
		var mult = FALL_GRAVITY_MULTIPLIER if velocity.y > 0 else 1.0
		velocity.y += GRAVITY * mult * delta

func atualizar_debug_hud():
	# Transforma o Enum em String legível
	var state_name = States.keys()[current_state]
	
	var pode_atacar_ar : String
	if is_on_floor():
		pode_atacar_ar = "🟢 No Chão"
	elif air_attack_count == 0:
		pode_atacar_ar = "🟢 Disponível"
	else:
		pode_atacar_ar = "🔴 Gasto"
	
	var debug_text = ""
	debug_text += "[ ESTADO ]: %s\n" % state_name
	debug_text += "[ VELOCIDADE ]: %s\n" % str(velocity.round())
	debug_text += "[ NO CHÃO ]: %s\n" % ("🟢 Sim" if is_on_floor() else "🔴 Não")
	debug_text += "[ COMBO ]: %d\n" % (COMBO_COUNTER + 1)
	debug_text += "[ ATAQUE NO AR ]: %s\n" % pode_atacar_ar
	
	
	debug_text += "\n--- HABILIDADES ---\n"
	debug_text += "DASH: %s (Disp: %d)\n" % [("🟢 Sim" if have_dash else "🔴 Não"), max_dash]
	debug_text += "PULO DUPLO: %s\n" % ("🟢 Sim" if have_double_jump else "🔴 Não")
	debug_text += "ATAQUE BAIXO: %s\n" % ("🟢 Sim" if have_down_attack else "🔴 Não")
	
	debug_text += "\n--- BUFFERS ---\n"
	debug_text += "Pulo: %.2f | Ataque: %.2f" % [jump_buffer_counter, attack_buffer_counter]
	
	if Input.is_action_just_pressed("debug_key"):
		$CanvasLayer.visible = not $CanvasLayer.visible
	
	# Atualiza o nó Label
	$CanvasLayer/DebugLabel.text = debug_text
