@tool
extends Node3D

# Define parameters
@export var glb_directory = "res://kenney_modular-buildings/Models/GLB format"
@export var grid_size = 5 # Change the grid size as needed
@export var spacing = 2.0 # Change the spacing between models as needed

@export var positive_keywords: Array= [] 
@export var negative_keywords: Array= []

func _ready():
	# List all files in the GLB directory
	dir_contents(glb_directory)

func dir_contents(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var x = 0
		var z = 0
		while file_name != "":
			if not file_name.begins_with("."):
				# Ignore files starting with "." (like "." and "..")
				if not dir.current_is_dir() and file_name.ends_with(".glb"):
					# Check if the file matches the filter keywords
					if check_filter_keywords(file_name):
						# Load the GLB file
						var glb_path = path + "/" + file_name
						var glb_scene: PackedScene = load(glb_path)
						
						if glb_scene:
							# Instantiate the GLB scene
							var glb_model: Node3D = glb_scene.instantiate()
							
							# Calculate the position based on the grid
							var position = Vector3(x * spacing, 0.0, z * spacing)
							glb_model.position = position
							
							# Determine if the model is in a corner or in the middle
							if (x == 0 or x == grid_size - 1) and (z == 0 or z == grid_size - 1):
								pass;
								# Model is in a corner
								# Example: load_corner_model_and_apply_rotation(glb_model)
								# You would implement a function to load the corner model and apply rotation
								
							elif x == 0 or x == grid_size - 1 or z == 0 or z == grid_size - 1:
								# Model is on the edge but not in a corner
								# Determine rotation direction based on current row
								var rotation_angle = -90.0 if (x % 2 == 0) else 90.0
								glb_model.rotate_y(deg_to_rad(rotation_angle))  # Apply rotation
								
								
							# Create a MeshInstance for the visual model
							var visual_model = glb_model.duplicate()
							add_child(visual_model)

							# Create a MeshInstance for the collision model
							var collision_shape: CollisionShape3D = CollisionShape3D.new()
							#collision_shape.shape = glb_model.mesh # Set the collision shape
							#add_child(collision_shape)
							add_child(glb_model)


							
							print("Loaded and instantiated: " + file_name)
							
							# Increment grid position
							x += 1
							if x >= grid_size:
								x = 0
								z += 1

						else:
							print("Failed to load GLB file: " + file_name)
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")

# Function to check if the file name contains any of the filter keywords
func check_filter_keywords(file_name: String) -> bool:
	# Check negative keywords first
	for keyword in negative_keywords:
		if file_name.find(keyword) != -1:
			return false # File name contains a negative keyword, skip loading
	
	# Check positive keywords
	if positive_keywords.size() == 0:
		return true # No positive keywords specified, load all files
	else:
		for keyword in positive_keywords:
			if file_name.find(keyword) != -1:
				return true # File name contains a positive keyword, load the file
	
	return false # File name does not match any positive keyword, skip loading



