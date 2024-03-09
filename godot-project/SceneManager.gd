extends Node3D

var PlayerScene = preload("res://Player/Player.tscn")

func find_and_print_node_path(node, target_name, current_path=""):
	if node.get_name() == target_name:
		print("Node found:", current_path + node.get_name())
		return

	for child in node.get_children():
		find_and_print_node_path(child, target_name, current_path + node.get_name() + "/")


func printSceneTree(node: Node, indent: String = "", isLast: bool = true) -> void:
	var children = node.get_children()
	var childCount = children.size()

	if isLast:
		print(indent + "└── " + node.get_name())
	else:
		print(indent + "├── " + node.get_name())

	for i in range(childCount):
		var child = children[i]
		var isLastChild = i == childCount - 1
		var newIndent = ""
		if isLast:
			newIndent = indent + "    "
		else:
			newIndent = indent + "│   "
		printSceneTree(child, newIndent, isLastChild)

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

	if multiplayer.get_unique_id() == 1:
		return
	
	add_child(currentPlayer)
	# Print the scene tree for debugging
	printSceneTree(get_tree().get_root())
	
	# Get references to the camera node and the current player node
	var pcam = get_node("/root/Playground/PlayerPhantomCamera3D")
	var currentPlayerNode = get_node("/root/Playground/" + str(multiplayer.get_unique_id()))

	# Set the follow target and other properties for the camera
	if pcam:
		pcam.set_follow_target_node(currentPlayer)
		pcam.set_spring_arm_spring_length(8)
		pcam.set_third_person_rotation(Vector3(-30, 0, 0))

		# Set mouse mode if the follow mode is third person
		if pcam.get_follow_mode() == pcam.Constants.FollowMode.THIRD_PERSON:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
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
