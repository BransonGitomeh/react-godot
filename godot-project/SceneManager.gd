extends Node3D

var PlayerScene = preload("res://Player/Player.tscn")

func find_and_print_node_path(node, target_name, current_path=""):
	if node.get_name() == target_name:
		print("Node found:", current_path + node.get_name())
		return

	for child in node.get_children():
		find_and_print_node_path(child, target_name, current_path + node.get_name() + "/")




func _ready():
	# Assuming you are calling this function in the root of your scene
	find_and_print_node_path(self, "CharacterSkin")

	var spawnLocations = $spawnLocations.get_children()
	
	print(multiplayer.get_unique_id()," Spawning in current player ")
	var currentPlayer = PlayerScene.instantiate()
	
	# Randomly select a spawn position
	var currentPlayerRandomSpawnNode = spawnLocations[randi() % spawnLocations.size()]
	
	#print(currentPlayerRandomSpawnNode)
	currentPlayer.position = currentPlayerRandomSpawnNode.position
	currentPlayer.name = str(multiplayer.get_unique_id())
	
	add_child(currentPlayer)
	
	#print(multiplayer.get_unique_id(), "FOUND PLAYERS", BrowlManager.Players)
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
