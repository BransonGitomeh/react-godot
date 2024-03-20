extends Marker3D

@export var step_target: Node3D
@export var max_step_distance: float = 3.0
@export var base_velocity: float = 5.0
@export var min_velocity: float = 1.0

var is_stepping := false
var spider_velocity: float = base_velocity

func _ready():
	# Initialize spider velocity
	spider_velocity = base_velocity

func _process(delta):
	# Update step size based on spider velocity
	var step_distance = max_step_distance * (spider_velocity / base_velocity)

	# Check if the spider is already stepping
	if !is_stepping && abs(global_position.distance_to(step_target.global_position)) > step_distance:
		step()

func step():
	var target_pos = step_target.global_position
	var half_way = (global_position + step_target.global_position) / 2
	is_stepping = true

	var t = get_tree().create_tween()
	t.tween_property(self, "global_position", half_way + owner.basis.y, 0.1)
	t.tween_property(self, "global_position", target_pos, 0.1)
	t.tween_callback(func(): is_stepping = false)

# Function to update spider velocity
func set_spider_velocity(new_velocity: float):
	# Ensure velocity is within bounds
	spider_velocity = clamp(new_velocity, min_velocity, base_velocity)
