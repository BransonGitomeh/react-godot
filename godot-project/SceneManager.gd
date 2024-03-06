extends Node3D

var PlayerScene = preload("res://Player/Player.tscn")
var currentPlayer
var groundLevel = 0.0
var offset = 0.1

func find_and_print_node_path(node, target_name, current_path=""):
	if node.get_name() == target_name:
		print("Node found:", current_path + node.get_name())
		return

	for child in node.get_children():
		find_and_print_node_path(child, target_name, current_path + node.get_name() + "/")


func _physics_process(delta: float) -> void:
	# Assuming this code is part of the physics process function of your script

	# Get the current player's position from the PlayerCharacterBody3D
	pass;


func _ready():
	var delta  = get_physics_process_delta_time()
	# Assuming you are calling this function in the root of your scene
	find_and_print_node_path(self, "CharacterSkin")

	#var spawnLocations = $spawnLocations.get_children()
	
	# print(multiplayer.get_unique_id()," Spawning in current player ")
	currentPlayer = PlayerScene.instantiate()
	
	# Randomly select a spawn position
	#var currentPlayerRandomSpawnNode = spawnLocations[randi() % spawnLocations.size()]
	
	#print(currentPlayerRandomSpawnNode)
	#currentPlayer.position = $"PlayerCharacterBody3D".global_transform.origin
	currentPlayer.name = str(multiplayer.get_unique_id())
	
	#$"PlayerCharacterBody3D".position = Vector3(0,0,0)
	
	$"PlayerCharacterBody3D".add_child(currentPlayer)
	
	# Apply gravity to the PlayerCharacterBody3D
	#var gravity = Vector3(0, -9.8, 0) # Adjust the gravity as per your game's requirements
	#var gravityVelocity = gravity * delta

	# Move the PlayerCharacterBody3D downward with gravity
	#$"PlayerCharacterBody3D".translate(gravityVelocity * delta)
	
	
	
	print(multiplayer.get_unique_id(), "FOUND PLAYERS", BrowlManager.Players)
	#for i in BrowlManager.Players:
		#if(BrowlManager.Players[i].id == 1):
			#return;
			#
		#print(multiplayer.get_unique_id()," Spawning in network player ", BrowlManager.Players[i].id)
		#var networkPlayer = PlayerScene.instantiate()
		#
		## Randomly select a spawn position
		#var randomSpawnNode = spawnLocations[randi() % spawnLocations.size()]
		#
		#print(randomSpawnNode)
		#currentPlayer.position = randomSpawnNode.position
		#currentPlayer.name = str(BrowlManager.Players[i].id)
		#
		#add_child(currentPlayer)
