extends CharacterBody2D

@onready var CoyoteTimer : Timer = $CoyoteTimer
@onready var JumpBufferTimer : Timer = $JumpBufferTimer

@export var SPEED : float = 80.0
@export var ACCELERATION : float = 1000.0
@export var FRICTION : float = 1200.0
@export var GRAVITY : int = 900
@export var JUMP_FORCE : int = 200
@export var HEAD_NUDGE_SPEED : float = 50.0 # Força do empurrão na quina

var was_on_floor : bool = false

func _physics_process(delta):
	var direction = Input.get_axis("Left", "Right")
	
	# 1. Movimentação e Fricção (Já implementados, mantidos para fluidez)
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		if is_on_floor(): $AnimatedSprite2D.play("Run")
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		if is_on_floor(): $AnimatedSprite2D.play("Idle")

	# 2. Lógica de Direção
	if direction != 0:
		$AnimatedSprite2D.flip_h = (direction < 0)

	# 3. Gravidade e Coyote Time
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		# Se ele acabou de sair do chão sem pular, inicia o Coyote Timer
		if was_on_floor and velocity.y >= 0:
			CoyoteTimer.start()
		
		if velocity.y > 0:
			$AnimatedSprite2D.play("Fall")
	
	# 4. Jump Buffer (Registra o clique antes de tocar o chão)
	if Input.is_action_just_pressed("Jump"):
		JumpBufferTimer.start()

	# 5. Execução do Pulo (Coyote + Buffer)
	# Se apertou pulo recentemente (Buffer) E está no chão ou saiu dele agora (Coyote)
	if JumpBufferTimer.time_left > 0 and (is_on_floor() or CoyoteTimer.time_left > 0):
		velocity.y = -JUMP_FORCE
		$AnimatedSprite2D.play("Jump")
		JumpBufferTimer.stop()
		CoyoteTimer.stop()

	# 6. Head Nudge (Empurrão de cabeça)
	# Se estiver subindo e bater no teto, tentamos deslizar o personagem
	if is_on_ceiling() and velocity.y < 0:
		handle_head_nudge()

	was_on_floor = is_on_floor()
	move_and_slide()

func handle_head_nudge():
	# Raio de detecção para saber se a cabeça bateu só de um lado
	var _query = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0 , -20))
	# Lógica simplificada: Se bater no teto, movemos levemente em X para desviar da quina
	# Para um Head Nudge perfeito, o ideal é usar Raycasts nas bordas da cabeça
	pass
