# PlayerManager.gd

extends Node

# Dictionary to store player information.
@export var Players = {}

# Signal to notify when a new player is added.
signal player_added(player_id: int, player_info: Dictionary)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# Function to add a new player to the Players dictionary.
func add_player(player_id: int, player_info: Dictionary):
	Players[player_id] = player_info
	emit_signal("player_added", player_id, player_info)

# Function to get player information by player_id.
func get_player(player_id: int) -> Dictionary:
	return Players.get(player_id, {})

# Function to set a callback for new player events.
#func set_new_player_callback(callback_object: Object, callback_method: Func):
#	connect("player_added", callback_object, callback_method)