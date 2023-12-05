extends Node3D

var PlayerScene = preload("res://Player/Player.tscn")

func _ready():
	var spawnLocations = $spawnLocations.get_children()
	
	for i in BrowlManager.Players:
		var currentPlayer = PlayerScene.instantiate()
		
		# Randomly select a spawn position
		var randomSpawnNode = spawnLocations[randi() % spawnLocations.size()]
		currentPlayer.position = randomSpawnNode.position
		currentPlayer.name = str(BrowlManager.Players[i].id)
		
		add_child(currentPlayer)
