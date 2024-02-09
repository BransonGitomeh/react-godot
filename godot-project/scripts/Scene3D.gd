extends Node3D

@onready var camera = get_viewport().get_camera_3d()
const MOVE_SPEED = 5.0
const ROTATE_SPEED = 60.0
	
func _ready():
#	if $Effect.effect:
#		$GUI/Controller/ResourceName.text = $Effect.effect.resource_path
#	$GUI/Controller/System/EffectMenu.connect("effect_choosed", self._on_effect_choosed)
#	$GUI/Controller/Player/PlayButton.connect("pressed", self._on_play_button_pressed)
#	$GUI/Controller/Player/StopButton.connect("pressed", self._on_stop_button_pressed)
#	$GUI/Controller/Player/PauseButton.connect("pressed", self._on_pause_button_pressed)
#	for i in range(4):
#		$GUI/Controller/Triggers/Buttons.get_child(i).connect("pressed", Callable(self, "_on_trigger_button_pressed").bind(i))

	#$Effect.target_position = $Effect.global_transform.origin + Vector3(0, 15, 0)
	
	# Specify the directory path
	var directory_path = "res://effects"
	
	# Call the setup function to populate the effect_data array
	var file_count = setup_effects(directory_path)
	
	# Print the array to check the result
	# print(effect_data)
	
	# Define the grid parameters
	var grid_spacing = Vector2(20, 20)  # Adjust as needed
	var grid_rows = 3
	var grid_columns = file_count / grid_rows  # Assuming even distribution

	# Loop through effect_data and add instances to the scene in a grid
	for i in range(min(file_count, 2)):
		if !effect_data[i]:
			return
		# Calculate grid position
		var row = i % grid_rows
		var col = i / grid_rows

		# Create a new instance of the effect
		var effect_instance = preload("res://effect.tscn").instantiate()

		# Set position in the grid
		effect_instance.transform.origin = Vector3(col * grid_spacing.x, 0, row * grid_spacing.y)

		# Add the effect as a child of the current scene
		add_child(effect_instance)
		
		# Load effect and start playing
		effect_instance.effect = load(effect_data[i].path)
		# print(effect_data[i].path)
		
		var _on_finished = func ():
			# Create a new instance of the effect
			var effect_instance2 = preload("res://effect.tscn").instantiate()

			# Set position in the grid
			effect_instance2.transform.origin = Vector3(col * grid_spacing.x, 0, row * grid_spacing.y)

			# Add the effect as a child of the current scene
			add_child(effect_instance2)
			
			# Load effect and start playing
			effect_instance2.effect = load(effect_data[i].path)
			# print(effect_data[i].path)
			
			#effect_instance.connect("on_finished", _on_finished)
			effect_instance.play()
		
		effect_instance.connect("on_finished", _on_finished)
		effect_instance.play()





func _on_effect_choosed(effect_path: String):
	$GUI/Controller/ResourceName.text = effect_path
	$Effect.effect = load(effect_path)

func _on_play_button_pressed():
	$Effect.play()

func _on_stop_button_pressed():
	$Effect.stop()

func _on_pause_button_pressed():
	$Effect.paused = $GUI/Controller/Player/PauseButton.button_pressed
	# get_tree().paused = $GUI/Controller/Player/PauseButton.button_pressed

func _on_trigger_button_pressed(index: int):
	$Effect.send_trigger(index)

func _process(delta: float):
	if Input.is_action_pressed("act_move_left"):
		$Effect.transform.origin += camera.basis.z.cross(Vector3.UP).normalized() * MOVE_SPEED * delta
	if Input.is_action_pressed("act_move_right"):
		$Effect.transform.origin -= camera.basis.z.cross(Vector3.UP).normalized() * MOVE_SPEED * delta
	if Input.is_action_pressed("act_move_up"):
		$Effect.transform.origin -= camera.basis.x.cross(Vector3.UP).normalized() * MOVE_SPEED * delta
	if Input.is_action_pressed("act_move_down"):
		$Effect.transform.origin += camera.basis.x.cross(Vector3.UP).normalized() * MOVE_SPEED * delta
	if Input.is_action_pressed("act_rot_left"):
		$Effect.rotate_y(deg_to_rad(-ROTATE_SPEED) * delta)
	if Input.is_action_pressed("act_rot_right"):
		$Effect.rotate_y(deg_to_rad(ROTATE_SPEED) * delta)


# Declare an array to store dictionaries
var effect_data = []

func setup_effects(path: String):
	var file_count := 0
	var dir := DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var asset_name = dir.get_next()
		while asset_name != "":
			if dir.current_is_dir():
				# Recursive call for subdirectories
				file_count += setup_effects(path + "/" + asset_name)
			elif asset_name.ends_with("efkefc.import"):
				asset_name = asset_name.substr(0, asset_name.rfind(".import"))
				file_count += 1
				var effect_path = path + "/" + asset_name
				var effect_dict = {"name": asset_name, "path": effect_path}
				effect_data.append(effect_dict)
			asset_name = dir.get_next()
		dir.list_dir_end()
	return file_count
