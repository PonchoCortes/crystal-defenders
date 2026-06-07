extends Area2D

signal collected

@export var points: int = 50
@export var collectible_type: String = "gem"

var is_collected: bool = false
var float_offset: float = 0.0
var float_speed: float = 2.0
var float_amplitude: float = 10.0

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var animation_player = $AnimationPlayer

func _ready():
	add_to_group("collectible")
	create_visual()
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	float_offset = randf() * TAU
	
	# Configurar capas
	collision_layer = 16  # Layer 5
	collision_mask = 4 + 8  # Enemy (3) + Projectile (4)

func create_visual():
	match collectible_type:
		"gem":
			sprite.texture = create_gem_texture()
		"star":
			sprite.texture = create_star_texture()
		"coin":
			sprite.texture = create_coin_texture()
			
	sprite.centered = true
	
	var circle = CircleShape2D.new()
	circle.radius = 16
	collision_shape.shape = circle
	
	setup_animation()

func create_gem_texture() -> ImageTexture:
	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var center = size / 2
	
	# Forma de diamante
	var points = [
		Vector2(center, 4),
		Vector2(center + 10, center),
		Vector2(center, size - 4),
		Vector2(center - 10, center)
	]
	
	# Rellenar el diamante
	for x in range(size):
		for y in range(size):
			var point = Vector2(x, y)
			if is_point_in_diamond(point, points):
				var dist_to_center = point.distance_to(Vector2(center, center))
				var brightness = 1.0 - (dist_to_center / center) * 0.3
				img.set_pixel(x, y, Color(0.3 * brightness, 1.0 * brightness, 1.0 * brightness))
				
	return ImageTexture.create_from_image(img)

func create_star_texture() -> ImageTexture:
	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var center = size / 2
	
	# Dibujar estrella simple
	for x in range(size):
		for y in range(size):
			var dx = x - center
			var dy = y - center
			var dist = Vector2(dx, dy).length()
			
			if dist < 12:
				var brightness = 1.0 - (dist / 12) * 0.4
				img.set_pixel(x, y, Color(1.0 * brightness, 1.0 * brightness, 0.3 * brightness))
				
	return ImageTexture.create_from_image(img)

func create_coin_texture() -> ImageTexture:
	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	var center = size / 2
	
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x - center, y - center).length()
			if dist <= 14:
				var brightness = 1.0 - (dist / 14) * 0.2
				img.set_pixel(x, y, Color(1.0 * brightness, 0.8 * brightness, 0.2 * brightness))
				
	return ImageTexture.create_from_image(img)

func is_point_in_diamond(point: Vector2, diamond_points: Array) -> bool:
	var c = false
	var j = diamond_points.size() - 1
	
	for i in range(diamond_points.size()):
		if ((diamond_points[i].y > point.y) != (diamond_points[j].y > point.y)) and \
		   (point.x < (diamond_points[j].x - diamond_points[i].x) * (point.y - diamond_points[i].y) / \
		   (diamond_points[j].y - diamond_points[i].y) + diamond_points[i].x):
			c = !c
		j = i
	return c

func setup_animation():
	if not animation_player:
		animation_player = AnimationPlayer.new()
		add_child(animation_player)
		
	var anim = Animation.new()
	var track_idx = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "Sprite2D:rotation")
	anim.track_insert_key(track_idx, 0.0, 0.0)
	anim.track_insert_key(track_idx, 1.0, TAU)
	anim.length = 2.0
	anim.loop_mode = Animation.LOOP_LINEAR
	
	var library = AnimationLibrary.new()
	library.add_animation("rotate", anim)
	animation_player.add_animation_library("", library)
	animation_player.play("rotate")

func _process(delta):
	if not is_collected:
		# Efecto de flotación
		float_offset += delta * float_speed
		sprite.position.y = sin(float_offset) * float_amplitude

func _on_area_entered(area):
	if not is_collected and area.get_parent().is_in_group("projectile"):
		collect()

func _on_body_entered(body):
	if not is_collected:
		if body.is_in_group("player") or body.is_in_group("enemy"):
			collect()

func collect():
	if is_collected:
		return
		
	is_collected = true
	collected.emit()
	create_collect_effect()
	
	queue_free()

func create_collect_effect():
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.z_index = 100
	
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.6
	particles.explosiveness = 1.0
	
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.initial_velocity_min = 80
	particles.initial_velocity_max = 150
	particles.gravity = Vector2(0, -100)
	
	particles.color = Color(0.3, 1.0, 1.0)
	particles.scale_amount_min = 4
	particles.scale_amount_max = 8
	
	await get_tree().create_timer(1.0).timeout
	particles.queue_free()