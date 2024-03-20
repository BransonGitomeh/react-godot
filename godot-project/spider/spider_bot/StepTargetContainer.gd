extends Node3D

@export var offset: float = 20.0
@export var interpolation_factor: float = 0.1  # Adjust the interpolation factor as needed


@onready var parent = get_parent_node_3d()
@onready var previous_position = parent.global_position

func _process(delta):
	var velocity = parent.global_position - previous_position
	var target_position = parent.global_position + velocity * offset
	global_position = global_position.lerp(target_position, interpolation_factor)
	
	previous_position = parent.global_position
