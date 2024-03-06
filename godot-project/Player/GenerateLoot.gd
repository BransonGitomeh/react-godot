extends Node3D

# Number of loot objects to create
var numLootObjects = 10
# Spacing between loot objects in the grid
var spacing = Vector3(2, 0, 2)  # Adjust as per your preference

# Called when the node enters the scene tree for the first time.
func _ready():
	# Load the loot object scene
	var lootScene = preload("res://lootObject.tscn")

	# Get the reference point (first child of the current scene)
	var referencePoint = get_child(0)

	# Calculate the starting position for the grid based on the reference point
	var startPosition = referencePoint.global_transform.origin

	# Create a grid of loot objects as children of this scene
	for y in range(3):  # Adjust the range for rows
		for x in range(4):  # Adjust the range for columns
			var new_loot = lootScene.instantiate()
			new_loot.name = "LootObject_" + str(y * 4 + x)  # Assign a unique name to each loot object

			# Calculate the position for the current loot object in the grid
			var position = startPosition + Vector3(x * spacing.x, 0, y * spacing.z)
			new_loot.position = position

			add_child(new_loot)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
