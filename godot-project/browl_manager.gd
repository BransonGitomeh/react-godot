# PlayerManager.gd

extends Node

# Dictionary to store player information.
@export var Players = {}

# Signal to notify when a new player is added.
signal player_added(player_id: int, player_info: Dictionary)

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect to the signal emitted when a new player is added.
	$PlayerManager.connect("player_added", self, "_on_player_added")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Function to handle adding a new player.
func _on_player_added(player_id: int, player_info: Dictionary):
	# Add the new player to the Players dictionary.
	Players[player_id] = player_info
	# Notify all clients about the new player.
	multiplayer.rpc("update_players", player_id, player_info)

# RPC function to update players on the clients.
remote func update_players(player_id: int, player_info: Dictionary):
	# Add the new player to the Players dictionary.
	Players[player_id] = player_info
