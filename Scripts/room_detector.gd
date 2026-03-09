class_name Camera_Sala

extends Area2D

@onready var room_pcam : PhantomCamera2D = $PhantomCamera2D

func _ready():
	# Conecta os sinais de entrada e saída
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body is Player:
		# Aumenta a prioridade para 10.
		# fará a transição suave para esta câmera.
		room_pcam.follow_target = body
		room_pcam.priority = 10

func _on_body_exited(body):
	if body is Player:
		# Abaixa a prioridade. Quando o player entrar na próxima sala, 
		# a câmera de lá terá prioridade 10 e assumirá o controle.
		room_pcam.priority = 0
