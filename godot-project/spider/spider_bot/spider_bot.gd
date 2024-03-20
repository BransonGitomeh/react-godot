extends Node3D

@export var move_speed: float = 5.0
@export var turn_speed: float = 1.0
@export var ground_offset: float = 0.5

@onready var fl_leg = $FrontLeftIKTarget
@onready var fr_leg = $FrontRightIKTarget
@onready var bl_leg = $BackLeftIKTarget
@onready var br_leg = $BackRightIKTarget
@onready var body = $Body_2  # Assuming the body node is named Body_2

# Define a maximum distance the IK targets can move per frame
const MAX_DISTANCE_PER_FRAME = 5.0  # Adjust this value as needed

func _process(delta):
	# Calculate the average normal of the planes defined by the IK targets
	var plane1 = Plane(bl_leg.global_position, fl_leg.global_position, fr_leg.global_position)
	var plane2 = Plane(fr_leg.global_position, br_leg.global_position, bl_leg.global_position)
	var avg_normal = ((plane1.normal + plane2.normal) / 2).normalized()

	# Calculate the target basis from the average normal
	var target_basis = _basis_from_normal(avg_normal)

	# Smoothly interpolate the transform basis towards the target basis
	transform.basis = lerp(transform.basis, target_basis, move_speed * delta).orthonormalized()

	# Calculate the average position of the IK targets
	var avg = (fl_leg.position + fr_leg.position + bl_leg.position + br_leg.position) / 4
	var target_pos = avg + transform.basis.y * ground_offset
	
	# Calculate the maximum allowable distance the IK targets can move this frame
	var max_distance = MAX_DISTANCE_PER_FRAME * delta
	
	# Calculate the distance between the current position and the target position
	var distance = transform.basis.y.dot(target_pos - position)
	
	# Limit the distance to move within the maximum allowable distance
	var move_distance = clamp(distance, -max_distance, max_distance)
	
	# Update the position
	position += transform.basis.y * move_distance

	# Handle other movement logic
	_handle_movement(delta)


func _handle_movement(delta):
	var dir = Input.get_axis('ui_down', 'ui_up')
	translate(Vector3(0, 0, -dir) * move_speed * delta)

	var a_dir = Input.get_axis('ui_right', 'ui_left')
	rotate_object_local(Vector3.UP, a_dir * turn_speed * delta)

func _basis_from_normal(normal: Vector3) -> Basis:
	var result = Basis()
	result.x = normal.cross(transform.basis.z)
	result.y = normal
	result.z = transform.basis.x.cross(normal)

	result = result.orthonormalized()
	result.x *= scale.x
	result.y *= scale.y
	result.z *= scale.z

	return result

# New function for ground detection and body height adjustment
func _adjust_body_height(delta):
	var ground_ray = RayCast3D.new()
	ground_ray.origin = body.global_position + body.basis.y
	ground_ray.direction = body.basis.y * -1  # Raycast downwards
	ground_ray.length = 10.0  # Adjust length as needed

	var result = get_world_3d().space_cast_ray(ground_ray)
	if result.is_collision():
		var ground_normal = result.normal
		var target_height = ground_normal.dot(body.global_position) + ground_offset
		position.y = lerp(position.y, target_height, delta * 5.0)  # Adjust speed as needed
