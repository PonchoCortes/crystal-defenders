extends RigidBody2D

signal exploded(position)

@export var explosion_radius: float = 150.0
@export var explosion_force: float = 800.0
@export var damage: int = 100
@export var bounce_damping: float = 0.6

var has_exploded: bool = false
var lifetime: float = 0.0
var max_lifetime: float = 5.0

var trail_points: Array = []
var max_trail_points: int = 30

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var fuse_timer = $FuseTimer
@onready var trail = $Trail2D

func _ready():
	contact_monitor = true
	max_contacts_reported = 4
	
	create_grenade_visual()
	setup_trail()
	
	body_entered.connect(_on_body_entered)
	fuse_timer.timeout.connect(explode)
	
	collision_layer = 16  # Layer 5
	collision_mask = 1 + 4  # Colisiona con World (1) y Enemy (4)

func create_grenade_visual():
	sprite.texture = create_circle_texture(14, Color(0.2, 0.8, 0.3))
	sprite.centered = true
	
	var circle = CircleShape2D.new()
	circle.radius = 14
	collision_shape.shape = circle

func create_circle_texture(radius: int, color: Color) -> ImageTexture:
	var size = radius * 2
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x - radius, y - radius).length()
			if dist <= radius:
				var alpha = 1.0 - (dist / radius) * 0.2
				img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
				
	return ImageTexture.create_from_image(img)

func setup_trail():
	if trail:
		trail.width = 6
		trail.default_color = Color(0.3, 1, 0.4, 0.6)
		
		var grad = Gradient.new()
		grad.set_color(0, Color(0.3, 1, 0.4, 0.8))
		grad.set_color(1, Color(0.3, 1, 0.4, 0))
		trail.gradient = grad

func launch(direction: Vector2, power: float):
	var launch_force = direction * power
	apply_central_impulse(launch_force)
	fuse_timer.start(2.5)

func _physics_process(delta):
	lifetime += delta
	
	if lifetime > max_lifetime and not has_exploded:
		explode()
		
	sprite.rotation += angular_velocity * delta
	
	# Actualizar trail
	if trail:
		trail_points.append(global_position)
		if trail_points.size() > max_trail_points:
			trail_points.pop_front()
			
		trail.clear_points()
		for point in trail_points:
			trail.add_point(point)

func _on_body_entered(body):
	linear_velocity *= bounce_damping
	
	if body.is_in_group("enemy") and not has_exploded:
		await get_tree().create_timer(0.1).timeout
		explode()

func explode():
	if has_exploded:
		return
		
	has_exploded = true
	
	create_explosion_effect()
	detect_and_damage_enemies()
	
	exploded.emit(global_position)
	
	queue_free()

func detect_and_damage_enemies():
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = explosion_radius
	query.shape = circle_shape
	query.transform = global_transform
	query.collision_mask = 4  # Layer 3: Enemies
	
	var results = space_state.intersect_shape(query)
	
	for result in results:
		var body = result.collider
		if body.has_method("take_damage"):
			var distance = global_position.distance_to(body.global_position)
			var damage_multiplier = 1.0 - (distance / explosion_radius)
			body.take_damage(damage * damage_multiplier)
			
		if body is RigidBody2D:
			var direction = (body.global_position - global_position).normalized()
			var distance = global_position.distance_to(body.global_position)
			var force_multiplier = 1.0 - (distance / explosion_radius)
			var force = direction * explosion_force * force_multiplier
			body.apply_central_impulse(force)

func create_explosion_effect():
	# Partículas principales
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.z_index = 50
	
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = 60
	particles.lifetime = 0.8
	particles.speed_scale = 2.0
	
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.initial_velocity_min = 200
	particles.initial_velocity_max = 500
	particles.gravity = Vector2(0, 600)
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 0.5, 1))
	gradient.set_color(0.5, Color(1, 0.5, 0, 1))
	gradient.set_color(1, Color(0.5, 0, 0, 0))
	particles.color_ramp = gradient
	
	particles.scale_amount_min = 6
	particles.scale_amount_max = 14
	
	# Onda expansiva
	create_shockwave()
	
	await get_tree().create_timer(1.0).timeout
	particles.queue_free()

func create_shockwave():
	var shockwave = Line2D.new()
	get_parent().add_child(shockwave)
	shockwave.global_position = global_position
	shockwave.z_index = 49
	shockwave.width = 8
	shockwave.default_color = Color(1, 0.8, 0, 0.8)
	
	# Crear círculo
	var points = 32
	for i in range(points + 1):
		var angle = (float(i) / points) * TAU
		var point = Vector2(cos(angle), sin(angle)) * 20
		shockwave.add_point(point)
		
	var tween = create_tween()
	tween.set_parallel(true)
	
	for i in range(points + 1):
		var angle = (float(i) / points) * TAU
		var end_point = Vector2(cos(angle), sin(angle)) * explosion_radius
		tween.tween_method(
			func(value): 
				if is_instance_valid(shockwave) and i < shockwave.get_point_count():
					shockwave.set_point_position(i, value),
			shockwave.get_point_position(i),
			end_point,
			0.4
		)
		
	tween.tween_property(shockwave, "modulate:a", 0.0, 0.4)
	tween.tween_property(shockwave, "width", 2.0, 0.4)
	
	await tween.finished
	shockwave.queue_free()