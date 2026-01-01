extends CharacterBody2D

@onready var CoyoteTimer : Timer = $CoyoteTimer
@onready var JumpBufferTimer : Timer = $JumpBufferTimer

@export var SPEED : float = 80.0
@export var ACCELERATION : float = 1000.0
@export var FRICTION : float = 1200.0
@export var GRAVITY : int = 650
@export var JUMP_FORCE : int = 225
@export var HEAD_NUDGE_SPEED : float = 50.0 

var was_on_floor : bool = false

func _physics_process(delta):
	var direction = Input.get_axis("Left", "Right")
	
	
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		if is_on_floor(): $AnimatedSprite2D.play("Run")
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		if is_on_floor(): $AnimatedSprite2D.play("Idle")

	
	if direction != 0:
		$AnimatedSprite2D.flip_h = (direction < 0)

	
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		#
		if was_on_floor and velocity.y >= 0:
			CoyoteTimer.start()
		
		if velocity.y > 0:
			$AnimatedSprite2D.play("Fall")
	
	
	if Input.is_action_just_pressed("Jump"):
		JumpBufferTimer.start()

	
	
	if JumpBufferTimer.time_left > 0 and (is_on_floor() or CoyoteTimer.time_left > 0):
		velocity.y = -JUMP_FORCE
		$AnimatedSprite2D.play("Jump")
		JumpBufferTimer.stop()
		CoyoteTimer.stop()

	
	
	if is_on_ceiling() and velocity.y < 0:
		handle_head_nudge()

	was_on_floor = is_on_floor()
	move_and_slide()

func handle_head_nudge():
	
	var _query = PhysicsRayQueryParameters2D.create(global_position, global_position + Vector2(0 , -20))

	pass
