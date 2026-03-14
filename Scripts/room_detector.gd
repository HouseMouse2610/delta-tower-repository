class_name Camera_Sala

extends Area2D

@export var room_pcam : PhantomCamera2D
@export var transition_time : float = 0.35

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	if room_pcam:
		room_pcam.tween_duration = transition_time

func _on_body_entered(body):
	if body is Player:
		if room_pcam:
			# 1. Troca a câmera no Manager
			GameCamera.switch_to_room(room_pcam, body)
			
			var vel = body.velocity
			# Lógica de Impulsos Direcionais
			
			# Verificamos se a transição é prioritariamente Horizontal ou Vertical
			if abs(vel.x) > abs(vel.y):
				# --- TRANSIÇÃO HORIZONTAL ---
				if vel.x < 0:
					# O jogador está à esquerda do centro: Impulso para a ESQUERDA
					body.velocity.x -= 100
				elif vel.x > 0:
					# O jogador está à direita do centro: Impulso para a DIREITA
					body.velocity.x += 100
			else:
				# --- TRANSIÇÃO VERTICAL ---
				body.velocity.x = 0 # Limpa o drift lateral para não bater na quina
				
				if vel.y < 0:
					# O jogador está acima do centro: Impulso para CIMA
					body.velocity.y -= body.JUMP_FORCE
					
		else:
			push_error("Sala sem PhantomCamera!")
