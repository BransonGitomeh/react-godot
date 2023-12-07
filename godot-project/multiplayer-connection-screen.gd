extends Control

var PlayerScene = preload("res://Player/Player.tscn")


@export var address = "137.184.112.15"
@export var port = 8910
var peer;

# Called when the node enters the scene tree for the first time.
func _ready():
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	if "--server" in OS.get_cmdline_args():
		_on_host_pressed()
		return
	print("Automatically joining", address)
	_on_join_pressed()
	await get_tree().create_timer(1).timeout
	#
	#print("Dropping user in scene", address) 	
	#_on_start_browl_pressed()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func peer_connected(id):
	var spawnLocations = get_node("../spawnLocations")
	print(multiplayer.get_unique_id(), " peer_connected " ,id, BrowlManager.Players)
	
	print(multiplayer.get_unique_id()," Spawning in network player ", id)
	var newPlayer = PlayerScene.instantiate()
	
	var spawnLocationsChildren = spawnLocations.get_children()
	
	# Randomly select a spawn position
	var randomSpawnNode = spawnLocationsChildren[randi() % spawnLocationsChildren.size()]
	
	print(randomSpawnNode)
	newPlayer.position = randomSpawnNode.position
	newPlayer.name = str(id)
	
	add_child(newPlayer)
	


func peer_disconnected(id):
	print("peer_disconnected " ,id)
	
func connected_to_server(id):
	print("connected_to_server! :" ,id)
	SendPlayerInformation.rpc_id(1,$Name.text,multiplayer.get_unique_id())
	
func connection_failed(id):
	print("connection_failed :" ,id)

@rpc("any_peer","call_local")
func StartBrowl():
	var scene = load("res://Main.tscn").instantiate()
	get_tree().root.add_child(scene)
	
	# add transition 
	self.hide()
	
@rpc("any_peer")
func SendPlayerInformation(name, id):
	if multiplayer.is_server():
		print("SendPlayerInformation", BrowlManager.Players)
		for i in BrowlManager.Players:
			print(i)
			SendPlayerInformation.rpc(BrowlManager.Players[i].name, i)
	else:
		if !BrowlManager.Players.has(id):
			var player = {
				"name": name,
				"id": id,
				"score":0
			}	
			print("Attempting to add ", player)
			BrowlManager.Players[id] = player
		
			print("Added", BrowlManager.Players, player)

func _on_host_pressed():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 32)
	if error!= OK:
		print("error creating server", error)
		return;
		
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER);
	
	# allow you to host and play at the same time
	multiplayer.set_multiplayer_peer(peer)

	print("Started server successfully on ", address,":", port)
	print("Waiting for Player v2")
	SendPlayerInformation($Name.text,multiplayer.get_unique_id())
	pass # Replace with function body.


func _on_join_pressed():
	# Not running in a browser, use ENetMultiplayerPeer
	print("Not running in a browser. Using ENetMultiplayerPeer.")
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port, 32, 0, 0)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	
	# Call SendPlayerInformation only on the server (host)
	if multiplayer.is_server():
		SendPlayerInformation.rpc(1, $Name.text, multiplayer.get_unique_id())


func _on_join_pressed_old():
	peer = ENetMultiplayerPeer.new()
	# peer.create_client(address, port)
	peer.create_client(address, port, 32, 0, 0)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	pass # Replace with function body.


func _on_start_browl_pressed():
	# do RPC call - call function accross all the peers or to one
	StartBrowl.rpc()
	pass # Replace with function body.
