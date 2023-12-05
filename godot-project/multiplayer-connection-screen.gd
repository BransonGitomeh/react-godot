extends Control


@export var address = "2604:a880:4:1d0::4a2:c000"
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
	
	print("Dropping user in scene", address) 	
	_on_start_browl_pressed()
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func peer_connected(id):
	SendPlayerInformation.rpc_id(1,$Name.text,multiplayer.get_unique_id())	
	print("peer_connected " ,id)


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
	var player = {
			"name": name,
			"id": id,
			"score":0
		}	
	BrowlManager.Players[id] = player
	
	print("Added", BrowlManager.Players, player)
	if multiplayer.is_server():
		for i in BrowlManager.Players:
			SendPlayerInformation.rpc(BrowlManager.Players[i].name, i)

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
	print("Waiting for Player")
	SendPlayerInformation($Name.text,multiplayer.get_unique_id())
	pass # Replace with function body.


func _on_join_pressed():
	peer = ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	pass # Replace with function body.


func _on_start_browl_pressed():
	# do RPC call - call function accross all the peers or to one
	StartBrowl.rpc()
	pass # Replace with function body.
