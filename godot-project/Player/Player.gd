class_name Player
extends CharacterBody3D

signal weapon_switched(weapon_name: String)

const BULLET_SCENE := preload("Bullet.tscn")
const COIN_SCENE := preload("Coin/Coin.tscn")

enum WEAPON_TYPE { DEFAULT, GRENADE }

## Character maximum run speed on the ground.
@export var move_speed := 8.0
## Speed of shot bullets.
@export var bullet_speed := 10.0
## Forward impulse after a melee attack.
@export var attack_impulse := 10.0
## Movement acceleration (how fast character achieve maximum speed)
@export var acceleration := 4.0
## Jump impulse
@export var jump_initial_impulse := 12.0
## Jump impulse when player keeps pressing jump
@export var jump_additional_force := 4.5
## Player model rotaion speed
@export var rotation_speed := 12.0
## Minimum horizontal speed on the ground. This controls when the character's animation tree changes
## between the idle and running states.
@export var stopping_speed := 1.0
## Max throwback force after player takes a hit
@export var max_throwback_force := 15.0
## Projectile cooldown
@export var shoot_cooldown := 0.5
## Grenade cooldown
@export var grenade_cooldown := 0.5

@onready var _rotation_root: Node3D = $CharacterRotationRoot
@onready var _camera_controller: CameraController = $CameraController
@onready var _attack_animation_player: AnimationPlayer = $CharacterRotationRoot/MeleeAnchor/AnimationPlayer
@onready var _ground_shapecast: ShapeCast3D = $GroundShapeCast
@onready var _grenade_aim_controller: GrenadeLauncher = $GrenadeLauncher
@onready var _character_skin: CharacterSkin = $CharacterRotationRoot/CharacterSkin
@onready var _ui_aim_recticle: ColorRect = %AimRecticle
@onready var _ui_coins_container: HBoxContainer = %CoinsContainer
@onready var _step_sound: AudioStreamPlayer3D = $StepSound
@onready var _landing_sound: AudioStreamPlayer3D = $LandingSound

@onready var _equipped_weapon: WEAPON_TYPE = WEAPON_TYPE.DEFAULT
@export var _move_direction := Vector3.ZERO
@onready var _last_strong_direction := Vector3.FORWARD
@onready var _gravity: float = -30.0
@onready var _ground_height: float = 0.0
@onready var _start_position := global_transform.origin
@onready var _coins := 0
@onready var _is_on_floor_buffer := false

@onready var _shoot_cooldown_tick := shoot_cooldown
@onready var _grenade_cooldown_tick := grenade_cooldown



# Variables for interpolation
var target_rotation_basis := Basis()
var current_rotation_basis := Basis()
var interpolation_alpha: float = 0.1  # Adjust this value for the desired smoothness


# Add these variables to your script
var target_position: Vector3 = Vector3.ZERO
var current_position: Vector3 = Vector3.ZERO

@export var _position_before: Vector3
@export var _position_after: Vector3
@export var _velocity_before: Vector3
@export var _last_position_received: Vector3 = Vector3.ZERO
@export var _last_velocity_received: Vector3 = Vector3.ZERO
@export var _last_update_time: float = 0.0

var _input_buffer: Array = []
const INPUT_BUFFER_SIZE: int = 10

@export var _predicted_position: Vector3

# Constants for interpolation
@export var network_position_interpolation_duration: float = 1000.0

# Flag to determine if the player has authority
var has_authority: bool = false

# Declare predicted_position and smoothed_input at a higher scope
@export var _smoothed_input: Vector3 = Vector3.ZERO

@export var _last_velocity_before: Vector3

@export var _predicted_positions : Array = []
# Add this variable to store predicted velocity
@export var _predicted_velocity: Vector3 = Vector3.ZERO
@export var _predicted_velocity_current: Vector3
@export var _predicted_velocity_previous: Vector3

func _ready() -> void:
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_camera_controller.setup(self)
	_grenade_aim_controller.visible = false
	emit_signal("weapon_switched", WEAPON_TYPE.keys()[0])
	
	# When copying this character to a new project, the project may lack required input actions.
	# In that case, we register input actions for the user at runtime.
	if not InputMap.has_action("move_left"):
		_register_input_actions()
		
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		$CameraController/PlayerCamera.current = true
		return;


func ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 0.1)

func ease_out_quartic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 0.1)


func interpolate_quadratic(p0, p1, p2, t):
	var u : float= 1.0 - t
	return u * u * p0 + 2 * u * t * p1 + t * t * p2


func interpolate_cubic(p0, p1, p2, p3, t):
	var u : float= 1.0 - t
	var tt : float= t * t
	var uu : float= u * u
	var uuu : float= uu * u
	var ttt : float= tt * t

	var p : Vector3 = uuu * p0  # (1-t)^3 * p0
	p += 3 * uu * t * p1        # 3 * (1-t)^2 * t * p1
	p += 3 * u * tt * p2        # 3 * (1-t) * t^2 * p2
	p += ttt * p3               # t^3 * p3

	return p
	
	
func _predict_and_set_network_player_position(delta):
  # Log client and server timestamps, multiplayer ID
	# print("Client:", $MultiplayerSynchronizer.get_multiplayer_authority(), "Timestamp:", Time.get_datetime_string_from_system(), "Position:", global_position)
	# print("Server:", multiplayer.get_unique_id(), "Timestamp:", Time.get_datetime_string_from_system())

	# Calculate time since last update
	var time_since_update = delta

	# Calculate t for interpolation
	var t = clamp(delta / network_position_interpolation_duration, 0, 1)

	# Calculate predicted position based on client input (if not server)
	var predicted_position: Vector3
	if multiplayer.is_server() and $MultiplayerSynchronizer.get_multiplayer_authority() != 1:
		predicted_position = global_position + _last_velocity_before * delta
	else:
		# Client prediction
		predicted_position = interpolate_quadratic(global_position, global_position + _last_velocity_before * delta, global_position + _last_velocity_before * (delta * 2), t)

	# Log predicted position
	print("Predicted Position:", predicted_position)

	# Set network player's position
	global_position = predicted_position

	# Save predicted position and velocity for future calculations
	_predicted_position = predicted_position
	_predicted_velocity = (_position_after - _position_before) / time_since_update


func _update_predicted_velocity(time_since_update, _position_before, _position_after, delta):
  # Calculate constant acceleration
	var acceleration = (_predicted_velocity_current - _predicted_velocity_previous) / delta

	# Update predicted velocity
	_predicted_velocity += acceleration * time_since_update


func _predict_future_positions(delta):
	var time_since_update = delta
	var acceleration = (_predicted_velocity_current - _predicted_velocity_previous) / delta
	# Clear old predictions
	_predicted_positions.clear()

	# Predict positions for the next few frames
	for i in range(10):
		var time_delta = time_since_update + i * delta

		# Correct the predicted position calculation
		var velocity_term = _predicted_velocity * time_delta
		var acceleration_term = 0.5 * acceleration * (time_delta * time_delta)
		var predicted_position = _position_after + velocity_term + acceleration_term

		_predicted_positions.append(predicted_position)


# On the client side
func _move_client_smoothly(delta):
	_move_direction = _get_camera_oriented_input()

	# Calculate time since last update
	var time_since_update = delta

	# Separate out the y velocity to not interpolate on gravity
	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.lerp(_move_direction * move_speed, acceleration * delta)

	if _move_direction.length() == 0 and velocity.length() < stopping_speed:
		velocity = Vector3.ZERO
		
	if(velocity.y != _predicted_velocity.y):
		velocity.y = y_velocity

	# Store the predicted position based on the client's input
	_predicted_position = global_position + velocity * delta

	# Smooth rotation
	current_rotation_basis = current_rotation_basis.slerp(target_rotation_basis, interpolation_alpha)
	_rotation_root.transform.basis = Basis(current_rotation_basis)

# On the server side
func _update_position_with_input(delta: float, input_vector: Vector3) -> void:
	
	# Apply input to movement
	var move_direction = input_vector.normalized()

	# Separate out the y velocity to not interpolate on gravity
	var y_velocity := velocity.y
	velocity.y = 0.0
	velocity = velocity.lerp(move_direction * move_speed, acceleration * delta)

	if move_direction.length() == 0 and velocity.length() < stopping_speed:
		velocity = Vector3.ZERO

	if(velocity.y != _predicted_velocity.y):
		velocity.y = y_velocity

	velocity.y += _gravity * delta

	_position_before = global_position

	# Move and slide on the server side
	move_and_slide()

	_position_after = global_position

	# If there's a significant position change, adjust the predicted position on the client
	var delta_position := _position_after - _position_before
	var epsilon := 0.001
	if delta_position.length() > epsilon:
		# Notify the client about the authoritative position
		_predicted_position = _position_after

	# Smoothen rotation
	current_rotation_basis = current_rotation_basis.slerp(target_rotation_basis, interpolation_alpha)
	_rotation_root.transform.basis = Basis(current_rotation_basis)

var interpolated_position;
var _velocity_history := []
func _physics_process(delta: float) -> void:
  
  # Declare variables
	var time_since_update := delta
	var max_history_size := 5
  # Log server timestamp and multiplayer ID

  # Handle input and update position if server and looking at that client
	if multiplayer.is_server():
		if multiplayer.get_unique_id() != 1:
			print("Server:", multiplayer.get_unique_id(), "Timestamp:", Time.get_datetime_string_from_system())
			
			if $MultiplayerSynchronizer.get_multiplayer_authority() != multiplayer.get_unique_id():
				print(multiplayer.get_unique_id() ," _update_position_with_input and _predict_and_set_network_player_position ", $MultiplayerSynchronizer.get_multiplayer_authority()," _smoothed_input ", _smoothed_input)
				# Update position with input
				_update_position_with_input(delta, _smoothed_input)

				# Predict and set network player's position
				_predict_and_set_network_player_position(delta)
				
				# Update _velocity_before if velocity changed (client-side only)
				# Check if velocity changed
				var has_velocity_changed := false
				for hist_velocity in _velocity_history:
					if hist_velocity != velocity.normalized():
						has_velocity_changed = true
						break
					
				if has_velocity_changed:
					_velocity_before = velocity.normalized()

					# Log updated _velocity_before
					print(multiplayer.get_unique_id(), " Velocity changed Timestamp:", Time.get_datetime_string_from_system(), "Updated _velocity_before:", _velocity_before)
				
				return

		# Client-side processing for movement()
		elif $MultiplayerSynchronizer.get_multiplayer_authority() != multiplayer.get_unique_id():
			print(multiplayer.get_unique_id() ," _update_predicted_velocity and _predict_future_positions and _move_client_smoothly ", $MultiplayerSynchronizer.get_multiplayer_authority(), " _predicted_velocity " + str(_predicted_velocity))
			# Store previous predicted velocity
			_predicted_velocity_previous = _predicted_velocity

			# Update predicted velocity (client-side only)
			_update_predicted_velocity(time_since_update, _position_before, _position_after, delta)
			# Predict future positions (client-side only)
			_predict_future_positions(delta)

			# Move client smoothly with collision detection
			_move_client_smoothly(delta)
			#return

		  # Store velocity history for client-side prediction
			_velocity_history.append(velocity.normalized())

		  # Limit history size
			while _velocity_history.size() > max_history_size:
				_velocity_history.pop_front()

		  # Check if velocity changed
			var has_velocity_changed := false
			for hist_velocity in _velocity_history:
				if hist_velocity != velocity.normalized():
					has_velocity_changed = true
					break


			print( multiplayer.get_unique_id(), "Handling Local Input - Timestamp:", Time.get_datetime_string_from_system(), "Updated _velocity_before:", _velocity_before)

			# Get input and movement state
			var is_attacking := Input.is_action_pressed("attack") and not _attack_animation_player.is_playing()
			var is_just_attacking := Input.is_action_just_pressed("attack")
			var is_just_jumping := Input.is_action_just_pressed("jump") and is_on_floor()
			var is_aiming := Input.is_action_pressed("aim") and is_on_floor()
			var is_air_boosting := Input.is_action_pressed("jump") and not is_on_floor() and velocity.y > 0.0
			var is_just_on_floor := is_on_floor() and not _is_on_floor_buffer

			_is_on_floor_buffer = is_on_floor()
			_move_direction = _get_camera_oriented_input()

			# To not orient quickly to the last input, we save a last strong direction,
			# this also ensures a good normalized value for the rotation basis.
			if _move_direction.length() > 0.2:
				_last_strong_direction = _move_direction.normalized()
			if is_aiming:
				_last_strong_direction = (_camera_controller.global_transform.basis * Vector3.BACK).normalized()

			# Set aiming camera and UI
			if is_aiming:
				_camera_controller.set_pivot(_camera_controller.CAMERA_PIVOT.OVER_SHOULDER)
				_grenade_aim_controller.throw_direction = _camera_controller.camera.quaternion * Vector3.FORWARD
				_grenade_aim_controller.from_look_position = _camera_controller.camera.global_position
				_ui_aim_recticle.visible = true
			else:
				_camera_controller.set_pivot(_camera_controller.CAMERA_PIVOT.THIRD_PERSON)
				_grenade_aim_controller.throw_direction = _last_strong_direction
				_grenade_aim_controller.from_look_position = global_position
				_ui_aim_recticle.visible = false

			# Update attack state and position

			_shoot_cooldown_tick += delta
			_grenade_cooldown_tick += delta
			
			if is_just_jumping:
				velocity.y += jump_initial_impulse
			elif is_air_boosting:
				velocity.y += jump_additional_force * delta

			# Set character animation
			if is_just_jumping:
				_character_skin.jump.rpc()
				#_character_skin.jump()
			elif not is_on_floor() and velocity.y < 0:
				_character_skin.fall.rpc()
				#_character_skin.fall()
			elif is_on_floor():
				var xz_velocity := Vector3(velocity.x, 0, velocity.z)
				if xz_velocity.length() > stopping_speed:
					_character_skin.set_moving.rpc(true)
					#_character_skin.set_moving(true)
					_character_skin.set_moving_speed.rpc(inverse_lerp(0.0, move_speed, xz_velocity.length()))
				else:
					_character_skin.set_moving.rpc(false)

					#_character_skin.set_moving(false)

			if is_just_on_floor:
				_landing_sound.play()
			
			# Input smoothing using moving average
			_input_buffer.append(_last_strong_direction)
			while _input_buffer.size() > INPUT_BUFFER_SIZE:
				_input_buffer.pop_front()
			for input_vector in _input_buffer:
				_smoothed_input += input_vector
			if _input_buffer.size() > 0:
				_smoothed_input /= _input_buffer.size()
			
			# Update attack state and position (client-side only)
			_shoot_cooldown_tick += delta
			_grenade_cooldown_tick += delta

			if is_attacking:
				match _equipped_weapon:
					WEAPON_TYPE.DEFAULT:
						if is_aiming and is_on_floor():
							if _shoot_cooldown_tick > shoot_cooldown:
								_shoot_cooldown_tick = 0.0
								shoot.rpc()
						elif is_just_attacking:
							attack.rpc()
					WEAPON_TYPE.GRENADE:
						if _grenade_cooldown_tick > grenade_cooldown:
							_grenade_cooldown_tick = 0.0
							_grenade_aim_controller.throw_grenade()
		
	

		


@rpc
func attack() -> void:
	_attack_animation_player.play("Attack")
	_character_skin.punch.rpc()
	#_character_skin.punch()
	velocity = _rotation_root.transform.basis * Vector3.BACK * attack_impulse

@rpc
func shoot() -> void:
	var bullet := BULLET_SCENE.instantiate()
	bullet.shooter = self
	var origin := global_position + Vector3.UP
	var aim_target := _camera_controller.get_aim_target()
	var aim_direction := (aim_target - origin).normalized()
	bullet.velocity = aim_direction * bullet_speed
	bullet.distance_limit = 14.0
	get_parent().add_child(bullet)
	bullet.global_position = origin


func reset_position() -> void:
	transform.origin = _start_position


func collect_coin() -> void:
	_coins += 1
	_ui_coins_container.update_coins_amount(_coins)


func lose_coins() -> void:
	var lost_coins: int = min(_coins, 5)
	_coins -= lost_coins
	for i in lost_coins:
		var coin := COIN_SCENE.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position
		coin.spawn(1.5)
	_ui_coins_container.update_coins_amount(_coins)


func _get_camera_oriented_input() -> Vector3:
	if _attack_animation_player.is_playing():
		return Vector3.ZERO

	var raw_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var input := Vector3.ZERO
	# This is to ensure that diagonal input isn't stronger than axis aligned input
	input.x = -raw_input.x * sqrt(1.0 - raw_input.y * raw_input.y / 2.0)
	input.z = -raw_input.y * sqrt(1.0 - raw_input.x * raw_input.x / 2.0)

	input = _camera_controller.global_transform.basis * input
	input.y = 0.0
	return input


func play_foot_step_sound() -> void:
	_step_sound.pitch_scale = randfn(1.2, 0.2)
	_step_sound.play()


func damage(_impact_point: Vector3, force: Vector3) -> void:
	# Always throws character up
	force.y = abs(force.y)
	velocity = force.limit_length(max_throwback_force)
	lose_coins()




@rpc("any_peer", "call_local", "reliable", 0)
func _orient_character_to_direction(direction: Vector3, delta: float) -> void:
	var left_axis := Vector3.UP.cross(direction)
	target_rotation_basis = Basis(left_axis, Vector3.UP, direction).get_rotation_quaternion()



#@rpc("any_peer", "call_local", "reliable", 0)
#func _orient_character_to_direction(direction: Vector3, delta: float) -> void:
	#var left_axis := Vector3.UP.cross(direction)
	#var rotation_basis := Basis(left_axis, Vector3.UP, direction).get_rotation_quaternion()
	#
	## Update the target rotation for interpolation
	#target_rotation_basis = rotation_basis
	#
	## Interpolate the rotation
	#var current_rotation := _rotation_root.transform.basis.get_rotation_quaternion()
	#var interpolated_rotation := current_rotation.slerp(target_rotation_basis, delta * interpolation_alpha)
	#
	#var model_scale := _rotation_root.transform.basis.get_scale()
	#_rotation_root.transform.basis = Basis(interpolated_rotation).scaled(model_scale)




## Used to register required input actions when copying this character to a different project.
func _register_input_actions() -> void:
	const INPUT_ACTIONS := {
		"move_left": KEY_A,
		"move_right": KEY_D,
		"move_up": KEY_W,
		"move_down": KEY_S,
		"jump": KEY_SPACE,
		"attack": MOUSE_BUTTON_LEFT,
		"aim": MOUSE_BUTTON_RIGHT,
		"swap_weapons": KEY_TAB,
		"pause": KEY_ESCAPE,
		"camera_left": KEY_Q,
		"camera_right": KEY_E,
		"camera_up": KEY_R,
		"camera_down": KEY_F,
	}
	for action in INPUT_ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var input_key = InputEventKey.new()
		input_key.keycode = INPUT_ACTIONS[action]
		InputMap.action_add_event(action, input_key)



func _on_multiplayer_synchronizer_delta_synchronized(delta_data):
	# Capture and store delta_data, which may include position information
	# For example, you might capture the target position from delta_data
	target_position = delta_data.get("position", Vector3.ZERO)
	#print("target_position", target_position)



func _on_multiplayer_synchronizer_synchronized():
	#print("---------------MulitplayerSynchronizer.syncronized!!!!----------------")
	pass # Replace with function body.
