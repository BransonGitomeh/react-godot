extends Node3D

# Number of nodes to create
var numNodes = 100

# Called when the node enters the scene tree for the first time.
func _ready():
	# Create a number of Node3D nodes as children of this scene
	for i in range(numNodes):
		var new_node = Node3D.new()
		new_node.name = "Node3D_" + str(i)  # Assign a unique name to each node
		add_child(new_node)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
