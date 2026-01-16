extends CharacterBody2D


func apanhar():
		self.modulate = Color.RED
		await get_tree().create_timer(0.2).timeout
		self.modulate = Color.WHITE
		print ("Ai!")
