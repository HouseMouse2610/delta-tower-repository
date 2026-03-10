class_name Camera_Sala
extends Area2D

@export var room_pcam : PhantomCamera2D
@export var transition_time : float = 0.35

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Configura a velocidade da transição programaticamente
	if room_pcam:
		room_pcam.tween_duration = transition_time
	
	# Aguarda um frame para calcular limites (garante precisão)
	await get_tree().process_frame

func _on_body_entered(body):
	if body is Player:
		# VERIFICAÇÃO DE SEGURANÇA: Só executa se a câmera existir
		if room_pcam != null:
			room_pcam.follow_target = body
			room_pcam.priority = 20
			
			# Impulso para não cair de volta (correção do bug de subir sala)
			if body.velocity.y < -10:
				body.velocity.y -= 110 
		else:
			# Isso vai te avisar no console EXATAMENTE qual sala está sem câmera
			push_error("ERRO: A sala '" + name + "' não tem uma PhantomCamera conectada no Inspector!")

func _on_body_exited(body):
	if body is Player:
		if room_pcam != null:
			room_pcam.priority = 0
