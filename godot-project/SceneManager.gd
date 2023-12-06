extends Node3D

var PlayerScene = preload("res://Player/Player.tscn")

func _ready():
	var spawnLocations = $spawnLocations.get_children()
	
	print(multiplayer.get_unique_id(), "FOUND PLAYERS", BrowlManager.Players)
	for i in BrowlManager.Players:
		if(BrowlManager.Players[i].id == 1):
			return;
			
		print(multiplayer.get_unique_id()," Spawning in player ", BrowlManager.Players[i].id)
		var currentPlayer = PlayerScene.instantiate()
		
		# Randomly select a spawn position
		var randomSpawnNode = spawnLocations[randi() % spawnLocations.size()]
		
		print(randomSpawnNode)
		currentPlayer.position = randomSpawnNode.position
		currentPlayer.name = str(BrowlManager.Players[i].id)
		
		add_child(currentPlayer)
