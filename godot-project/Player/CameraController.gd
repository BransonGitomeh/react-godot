class_name CameraController
extends Node3D

enum CAMERA_PIVOT { OVER_SHOULDER, THIRD_PERSON }

@export_node_path var player_path : NodePath
@export var invert_mouse_y := false
@export_range(0.0, 1.0) var mouse_sensitivity := 0.25
@export_range(0.0, 8.0) var joystick_sensitivity := 2.0
@export var tilt_upper_limit := deg_to_rad(-60.0)
@export var tilt_lower_limit := deg_to_rad(60.0)

@onready var camera: Camera3D = $PlayerCamera
@onready var _over_shoulder_pivot: Node3D = $CameraOverShoulderPivot
@onready var _camera_spring_arm: SpringArm3D = $CameraSpringArm
@onready var _third_person_pivot: Node3D = $CameraSpringArm/CameraThirdPersonPivot
@onready var _camera_raycast: RayCast3D = $PlayerCamera/CameraRayCast


@export var _aim_target : Vector3
@export var _aim_collider: Node
@export var _pivot: Node3D
@export var _current_pivot_type: CAMERA_PIVOT
@export var _rotation_input: float
@export var _tilt_input: float
@export var _mouse_input := false
@export var _offset: Vector3
@export var _anchor: CharacterBody3D
@export var _euler_rotation: Vector3


# FOV Parameters
var base_fov := 60
var zoomed_fov := 30

# Depth of Field Parameters
var base_blur_distance : float = 74.0
var focus_blur_distance : float = 2.0

# Screen Shake Parameters
var shake_intensity := 2.0

# Lerp Camera Parameters
var lerp_speed := 5.0

# Clamp Camera Height Parameters
var min_height := 2.0
var max_height := 20.0

# Zoom In/Out Parameters
var min_zoom := -5.0
var max_zoom := -15.0
var zoom_speed := 0.5
var zoom_factor := 0.0

# Look Ahead Parameters
var look_ahead_distance := 5.0

# Vignette Parameters
var base_vignette := 0.0
var intense_vignette := 0.5

# Check deadzone
var deadzone_radius = 5  # Adjust this for your desired deadzone size


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_handle_mouse_motion(event)
	elif event is InputEventKey:
		_handle_key_input(event)

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_rotation_input = -event.relative.x * mouse_sensitivity
		_tilt_input = -event.relative.y * mouse_sensitivity

func _toggle_mouse_capture() -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		
func _handle_key_input(event: InputEvent) -> void:
	_mouse_input = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if _mouse_input:
		_rotation_input = -event.relative.x * mouse_sensitivity
		_tilt_input = -event.relative.y * mouse_sensitivity
		
	if event.keycode == KEY_ESCAPE:
		_toggle_mouse_capture()

var base_arm_length := 20.0
var max_speed_arm_length := 40.0
var arm_length_lerp_speed := 4.0


# Interpolate spring arm length
func lerp_arm_length(target_length: float, delta) -> void:
	var player := self.get_parent()
	var camera_spring_arm := $CameraSpringArm

	var new_length :float= lerp(camera_spring_arm.spring_length, target_length, arm_length_lerp_speed * delta)
	camera_spring_arm.spring_length = new_length

# Add a deadzone variable for both rotation and tilt inputs
var deadzone_rotation: float = 0.1
var deadzone_tilt: float = 0.1

var rotation_input= 0.0
var tilt_input= 0.0

var character_offset: Vector2 = Vector2(0, 0)

# Function to implement the "look ahead" system
func _look_ahead():
	# Assuming offset is a child of CharacterRotationRoot, adjust as needed
	var offset_node = self.get_parent().get_node("CharacterRotationRoot").get_node("offset")
	#self.look_at(target_position, Vector3(0, 1, 0))  # The second parameter is the up vector (usually Y-axis)

	# Set the camera's rotation to face the look ahead position
	self.look_at(self.get_parent().get_node("CharacterRotationRoot").get_node("offset").global_transform.origin, Vector3.UP)
	#camera.look_at(-offset_node.position, Vector3.UP)


# Function to calculate the distance between two points in 3D space
func distance(point1: Vector3, point2: Vector3) -> float:
	return (point1 - point2).length()

func _ready():
	_toggle_mouse_capture()


var rule_of_thirds_size : Vector2 = Vector2(3, 3)
var rule_of_thirds_lerp_speed: float = 2.0
# Rotate the camera based on player input or other factors
func rotate_camera(rotation_speed: float, delta: float) -> void:
	var player_rotation = self.get_parent().get_rotation()
	var new_camera_rotation = $CameraSpringArm.rotation
	new_camera_rotation.y += Input.get_action_strength("turn_right") - Input.get_action_strength("turn_left") * rotation_speed * delta
	$CameraSpringArm.rotation = new_camera_rotation

# Interpolate camera position for Rule of Thirds
func lerp_to_rule_of_thirds(target_position: Vector3, delta: float) -> void:
	var current_position = global_transform.origin
	var new_position = current_position.lerp(target_position, rule_of_thirds_lerp_speed * delta)
	global_transform.origin = new_position

func _handle_rule_of_thirds(delta):
	var target_position: Vector3 = self.get_parent().get_node("CharacterRotationRoot").get_node("offset").global_transform.origin
	var player_world_pos = _anchor.global_position
	var camera_offset = global_position - player_world_pos

	# Calculate the distance from the camera to the target position
	var distance_to_target = distance(global_position, target_position)

	# Check if the distance is greater than the deadzone_radius
#	if distance_to_target > deadzone_radius:
#		# Lerp camera position only if outside deadzone
	_handle_lerp_camera(delta)
	#_look_ahead()
#		pass;
#	else:
#		pass
		# Keep camera position fixed within dead zone
		#global_position = target_position + camera_offset

	# Calculate the rule-of-thirds region
	var rule_of_thirds_region = Rect2(
		target_position.x - rule_of_thirds_size.x / 2,
		target_position.y - rule_of_thirds_size.y / 2,
		rule_of_thirds_size.x,
		rule_of_thirds_size.y
	)
	
	#print(rule_of_thirds_region, Vector2(player_world_pos.x, player_world_pos.y))
	# Ensure character placement within the central two squares with an additional offset
	#if not rule_of_thirds_region.has_point(Vector2(player_world_pos.x, player_world_pos.y)):
		# Character is outside the rule-of-thirds region, adjust camera
	var new_camera_pos = Vector2(
		clamp(player_world_pos.x, rule_of_thirds_region.position.x, rule_of_thirds_region.position.x + rule_of_thirds_region.size.x),
		clamp(player_world_pos.y, rule_of_thirds_region.position.y, rule_of_thirds_region.position.y + rule_of_thirds_region.size.y)
	)
	# Apply additional offset
	#print("new_camera_pos", "Apply additional offset", new_camera_pos)
	#new_camera_pos += character_offset
	#global_position = Vector3(new_camera_pos.x, new_camera_pos.y, global_position.z)

	# Use lerp to smoothly interpolate to the optimal camera position
	#lerp_to_rule_of_thirds(target_position, delta)

	# Clamp camera height
	_handle_clamp_camera_height()


func _physics_process(delta: float) -> void:
	if not _anchor:
		return

	# Get the player's speed
	var player_speed :float= self.get_parent().velocity.length()

	# Map the player's speed to the arm length
	var target_arm_length :float= lerp(base_arm_length, max_speed_arm_length, player_speed / self.get_parent().move_speed)

	

	# Handle camera effects based on character's speed
	#_handle_speed_based_effects()

	# Handle FOV changes
	#_handle_fov()

	# Handle Depth of Field (DOF) effects
	_handle_dof()

	# Handle screen shake
	#_handle_screen_shake(delta)

	# Handle zoom in/out
	#_handle_zoom()
	
	#var target_position : Vector3 = self.get_parent().global_transform.origin
#
#
	#var player_world_pos = _anchor.global_position
	#var camera_offset = global_position - player_world_pos
	#
	## Calculate the distance from the camera to the target position
	#var distance_to_target = distance(global_position, target_position)
	
	# Interpolate spring arm length
	#lerp_arm_length(target_arm_length, delta)
	
	#print("distance_to_target, deadzone_radius",distance_to_target, deadzone_radius, distance_to_target > deadzone_radius)
	#if distance_to_target > deadzone_radius:
		## Lerp camera position only if outside deadzone
		#_handle_lerp_camera(delta)
		#_look_ahead()
	#else:
		## Keep camera position fixed within dead zone
		#global_position = target_position + camera_offset
	
	_handle_rule_of_thirds(delta)

	# Check if the game is paused or stopped
	if get_tree().paused or !is_instance_valid(self):
		# Release the mouse when paused or stopped
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Handle camera rotation
	_rotation_input += Input.get_action_raw_strength("ui_left") - Input.get_action_raw_strength("ui_right")
	_tilt_input += Input.get_action_raw_strength("ui_up") - Input.get_action_raw_strength("ui_down")

	if invert_mouse_y:
		_tilt_input *= -1

	# Camera raycast and aim handling
	if _camera_raycast.is_colliding():
		_aim_target = _camera_raycast.get_collision_point()
		_aim_collider = _camera_raycast.get_collider()
	else:
		_aim_target = _camera_raycast.global_transform * _camera_raycast.target_position
		_aim_collider = null

	# Update global position based on deadzone check
	#global_position = target_position

	# Rotates camera using euler rotation
	_euler_rotation.x += _tilt_input * delta
	_euler_rotation.x = clamp(_euler_rotation.x, tilt_lower_limit, tilt_upper_limit)
	_euler_rotation.y += _rotation_input * delta

	transform.basis = Basis.from_euler(_euler_rotation)

	if camera.global_transform != _pivot.global_transform:
		camera.global_transform = _pivot.global_transform
		camera.rotation.z = 0

		_rotation_input = 0.0
		_tilt_input = 0.0


func _handle_lerp_camera(delta: float):
	# Set lerp speeds
	var position_lerp_speed = .7
	var rotation_lerp_speed = 0.004  # Adjust this value to control rotation speed

	var target_position = self.get_parent().get_node("CharacterRotationRoot").get_node("offset").global_transform.origin

	# Lerp camera position
	global_position = global_position.lerp(target_position, position_lerp_speed * delta)

	# Calculate the rotated offset based on the player's rotation
	var player_rotation_y = self.get_parent().global_transform.basis.get_euler().y
	var rotated_offset = _offset.rotated(Vector3(0, 1, 0), player_rotation_y)

	# Lerp camera rotation
	#var target_rotation = Basis().rotated(Vector3(0, 1, 0), player_rotation_y)
	#_pivot.global_transform.origin = _pivot.global_transform.origin.lerp(target_position + rotated_offset, position_lerp_speed * delta)
	
	# print(self.get_parent().velocity)
	#if self.get_parent().velocity > Vector3.ZERO:
		# Player is moving, update target_position based on velocity
	_pivot.look_at(_pivot.global_transform.origin.lerp(target_position, rotation_lerp_speed * delta))
	#else:
		# Player is not moving, set target_position to the player's current position
	#_pivot.look_at(_pivot.global_transform.origin.lerp(self.get_parent().global_transform.origin, rotation_lerp_speed * delta))
	# Use a separate lerp for look-at rotation
	


# Function to handle linear interpolation for camera movement
func _handle_lerp_camera_old(delta: float):
	# Set the lerp speed (adjust as needed)
	var lerp_speed = .1

	# Calculate the target position (in this example, it's the target_position)
	var target_position : Vector3 = self.get_parent().get_node("CharacterRotationRoot").get_node("offset").global_transform.origin
	
	#print("_handle_lerp_camera", _handle_lerp_camera)
	# Use lerp to smoothly move the camera towards the target position
	global_position = global_position.lerp(target_position, lerp_speed * delta)

func setup(anchor: CharacterBody3D) -> void:
	_anchor = anchor
	_offset = global_transform.origin - anchor.global_transform.origin
	set_pivot(CAMERA_PIVOT.THIRD_PERSON)
	camera.global_transform = camera.global_transform.interpolate_with(_pivot.global_transform, 0.1)
	_camera_spring_arm.add_excluded_object(_anchor.get_rid())
	_camera_raycast.add_exception_rid(_anchor.get_rid())


func set_pivot(pivot_type: CAMERA_PIVOT) -> void:
	if pivot_type == _current_pivot_type:
		return

	match(pivot_type):
		CAMERA_PIVOT.OVER_SHOULDER:
			_over_shoulder_pivot.look_at(_aim_target)
			_pivot = _over_shoulder_pivot
		CAMERA_PIVOT.THIRD_PERSON:
			_pivot = _third_person_pivot

	_current_pivot_type = pivot_type


func get_aim_target() -> Vector3:
	return _aim_target


func get_aim_collider() -> Node:
	if is_instance_valid(_aim_collider):
		return _aim_collider
	else:
		return null


# Handle FOV changes based on parent node's velocity
func _handle_fov() -> void:
	# Assuming the parent node has a "velocity" property
	var parent_velocity : Vector3 = get_parent().velocity
	
	# Calculate the speed (magnitude of velocity) to determine the zoom factor
	var speed : float = parent_velocity.length()

	# Normalize the speed to a range between 0 and 1
	var normalized_speed : float = speed / get_parent().move_speed  # Assuming max_speed is the maximum speed the parent can achieve

	# Using linear interpolation (lerp) to smoothly transition between base and zoomed FOV based on speed
	camera.fov = lerp(base_fov, zoomed_fov, -normalized_speed)

# Handle Depth of Field (DOF) effects
func _handle_dof() -> void:
	#camera.attributes.dof_blur_far_size = lerp(base_blur_size, focus_blur_size, zoom_factor)
	camera.attributes.set_dof_blur_far_distance(lerp(base_blur_distance, focus_blur_distance, zoom_factor))
	#camera.dof_blur_far_size = lerp(base_blur_size, focus_blur_size, zoom_factor)

# Handle screen shake in 3D
func _handle_screen_shake(delta: float) -> void:
	# Generate random offset for each axis
	var shake_offset = Vector3(
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity),
		randf_range(-shake_intensity, shake_intensity)
	)
	
	# Apply the offset to the camera's global position
	camera.global_transform.origin += shake_offset * delta


# Clamp camera height
func _handle_clamp_camera_height() -> void:
	camera.global_transform.origin.y = clamp(camera.global_transform.origin.y, min_height, max_height)

# Handle zoom in/out
func _handle_zoom() -> void:
	if Input.is_action_pressed("zoom_in"):
		zoom_factor = clamp(zoom_factor - zoom_speed, 0.0, 1.0)
	elif Input.is_action_pressed("zoom_out"):
		zoom_factor = clamp(zoom_factor + zoom_speed, 0.0, 1.0)
	else:
		zoom_factor = lerp(zoom_factor, 0.0, zoom_speed * 2.0)


# Handle camera effects based on character's speed
func _handle_speed_based_effects() -> void:
	# Assuming you have a variable for character speed (e.g., player.speed)
	var speed_ratio :float= clamp(self.get_parent().velocity.length() / self.get_parent().move_speed, 0.0, 1.0)

	# Adjust camera effects based on character speed
	lerp_speed = lerp(5.0, 20.0, speed_ratio)
	shake_intensity = lerp(2.0, 0.0, speed_ratio)
	look_ahead_distance = lerp(5.0, 10.0, speed_ratio)
	base_vignette = lerp(0.0, 0.2, speed_ratio)
	intense_vignette = lerp(0.5, 0.8, speed_ratio)
