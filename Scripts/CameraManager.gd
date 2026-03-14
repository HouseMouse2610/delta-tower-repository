extends Node

var current_room_pcam: PhantomCamera2D = null
var switching := false

func switch_to_room(new_pcam: PhantomCamera2D, player: Player):
	if new_pcam == current_room_pcam:
		return
	if switching:
		return
	
	# Só troca se o player estiver nos DOIS quartos ao mesmo tempo
	if current_room_pcam:
		var current_room = current_room_pcam.get_parent()
		var new_room = new_pcam.get_parent()
		if not (current_room.overlaps_body(player) and new_room.overlaps_body(player)):
			return  # Ainda não está na sobreposição, aguarda
	
	switching = true
	
	if current_room_pcam:
		current_room_pcam.priority = 0
	
	current_room_pcam = new_pcam
	current_room_pcam.follow_target = player
	current_room_pcam.priority = 20
	
	switching = false
