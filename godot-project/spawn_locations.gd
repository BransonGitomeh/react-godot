extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	# Number of rows and columns in the grid
	var rows = 5
	var columns = 4

	# Spacing between nodes in the grid
	var spacing = 2.0

	# Loop to spawn nodes in the grid
	for row in range(rows):
		for col in range(columns):
			# Create a new instance of Node3D
			var node = Node3D.new()

			# Calculate position based on row and column indices
			var x = col * spacing
			var y = 0.0  # You can set a specific height if needed
			var z = row * spacing

			# Set the position of the node
			node.position = Vector3(x, y, z)

			# Add the node as a child of this node (the grid node)
			add_child(node)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
