extends Node2D

const PLAYER_SCENE = preload("res://Scenes/character_body_2d.tscn")
const ROOM_SCENE = preload("res://Scenes/room_area.tscn")
const TILESET_SCENE = preload("res://Scenes/tileset_node.tscn")
const CAMERA_SCENE = preload("res://Scenes/camera_2d.tscn")

@onready var player: Player = $Player

func ready() -> void:
	pass
