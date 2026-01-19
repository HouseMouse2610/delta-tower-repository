extends CanvasLayer

const GOMO_SCENE = preload("res://Scenes/health_hud.tscn")

# 1. Certifique-se que o caminho $Gomo/HBoxContainer está correto na sua árvore de nós
@onready var h_box_container: HBoxContainer = $Gomo/HBoxContainer

func setup_health(max_health: float):
	if h_box_container == null:
		print("ERRO: O HBoxContainer não foi encontrado!")
		return # O return tem que estar "dentro" do if (com tab) para só parar se der erro.
	
	print("Limpando gomos antigos...")
	for child in h_box_container.get_children():
		child.queue_free()
	
	print("Criando gomos novos...")
	# 2. O loop 'for' e o 'print' precisam estar alinhados dentro da função
	for i in range(float(max_health) / 2):
		var novo_gomo = GOMO_SCENE.instantiate()
		# 3. Aqui estava 'container', mas o nome da sua variável é 'h_box_container'
		
		h_box_container.add_child(novo_gomo)
		
		
	print("Setup finalizado!")

func update_display(current_health: float):
	if h_box_container == null: return
	
	var gomos = h_box_container.get_children()
	
	for i in range(gomos.size()):
		var gomo_atual = gomos[i]
		# Usamos find_child para ele procurar em toda a "árvore" daquele gomo específico
		var gomo_node = gomo_atual.find_child("AnimatedSprite2D", true, false)
		
		if gomo_node:
			var valor_deste_gomo = (i + 1) * 2 
			
			if current_health >= valor_deste_gomo:
				gomo_node.play("Full")
			elif current_health >= valor_deste_gomo - 1:
				gomo_node.play("Half")
			else:
				gomo_node.play("Hollow")
		else:
			# Isso vai nos dizer exatamente o que o Godot está vendo
			print("ERRO: O nó 'AnimatedSprite2D' não foi encontrado dentro do gomo ", i , gomo_atual.get_children())
