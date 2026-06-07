extends Line2D

@export var max_points: int = 50
@export var point_spacing: float = 0.08
@export var prediction_time: float = 2.5

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	width = 4
	default_color = Color(1, 1, 1, 0.6)
	z_index = 100
	
	var grad = Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.8))
	grad.set_color(1, Color(1, 1, 1, 0.1))
	gradient = grad

func calculate_trajectory(start_pos: Vector2, velocity: Vector2):
	clear_points()
	
	var pos = start_pos
	var vel = velocity
	var time = 0.0
	var points_added = 0
	
	while time < prediction_time and points_added < max_points:
		add_point(pos - global_position)
		points_added += 1
		
		vel.y += gravity * point_spacing
		pos += vel * point_spacing
		time += point_spacing
		
		if check_collision(pos):
			break
			
	visible = true

func check_collision(pos: Vector2) -> bool:
	var space_state = get_world_2d().direct_space_state
	var params = PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collision_mask = 1  # Solo world
	
	var result = space_state.intersect_point(params, 1)
	return result.size() > 0

func hide_trajectory():
	visible = false
	clear_points()