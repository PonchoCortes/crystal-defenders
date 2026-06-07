extends RigidBody2D

@export var health: int = 100
@export var max_health: int = 100
@export var points: int = 100
@export_enum("basic", "heavy", "flying") var enemy_type: String = "basic"

var is_alive: bool = true

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D
@onready var health_bar = $HealthBar

func _ready():
	add_to_group("enemy")
	contact_monitor = true
	max_contacts_reported = 4
	
	create_visual()
	setup_health_bar()

func create_visual():
	match enemy_type:
		"basic":
			sprite.texture = create_enemy_texture(Color(1, 0.2, 0.2))
			mass = 1.0
		"heavy":
			sprite.texture = create_enemy_texture(Color(0.6, 0, 0))
			mass = 3.0
			health = 200
			max_health = 200
			points = 200
		"flying":
			sprite.texture = create_enemy_texture(Color(1, 0.6, 0))
			gravity_scale = 0.1
			points = 150
			
	var circle = CircleShape2D.new()
	circle.radius = 20
	collision_shape.shape = circle

func create_enemy_texture(color: Color) -> ImageTexture:
	var size = 40
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center = size / 2
	
	# Cuerpo circular
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x - center, y - center).length()
			if dist <= center - 2:
				var brightness = 1.0 - (dist / center) * 0.2
				img.set_pixel(x, y, Color(color.r * brightness, color.g * brightness, color.b * brightness))
				
	# Ojos malvados
	for eye_x in [center - 8, center + 8]:
		for dx in range(-3, 4):
			for dy in range(-3, 4):
				if Vector2(dx, dy).length() <= 2:
					img.set_pixel(eye_x + dx, center - 5 + dy, Color.BLACK)
					
	# Boca
	for x in range(-6, 7):
		img.set_pixel(center + x, center + 8, Color.BLACK)
		
	return ImageTexture.create_from_image(img)

func setup_health_bar():
	health_bar = ProgressBar.new()
	add_child(health_bar)
	
	health_bar.position = Vector2(-20, -35)
	health_bar.size = Vector2(40, 6)
	health_bar.max_value = max_health
	health_bar.value = health
	health_bar.show_percentage = false
	
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.3, 0.3, 0.3)
	health_bar.add_theme_stylebox_override("background", style_bg)
	
	var style_fill = StyleBoxFlat.new()
	style_fill.bg_color = Color(0, 0.8, 0)
	health_bar.add_theme_stylebox_override("fill", style_fill)

func take_damage(amount: int):
	if not is_alive:
		return
		
	health -= amount
	health = max(0, health)
	
	if health_bar:
		health_bar.value = health
		
	flash_damage()
	create_damage_numbers(amount)
	
	if health <= 0:
		die()

func flash_damage():
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.08)
	tween.tween_property(sprite, "modulate", Color(1, 0.5, 0.5), 0.08)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.08)

func create_damage_numbers(amount: int):
	var label = Label.new()
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(randf_range(-20, 20), -40)
	label.text = "-" + str(int(amount))
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(1, 0.8, 0))
	label.z_index = 100
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	
	await tween.finished
	label.queue_free()

func die():
	if not is_alive:
		return
		
	is_alive = false
	
	GameManager.add_score(points)
	create_death_effect()
	
	queue_free()

func create_death_effect():
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.z_index = 10
	
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 40
	particles.lifetime = 1.0
	particles.explosiveness = 0.9
	
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.initial_velocity_min = 150
	particles.initial_velocity_max = 300
	particles.gravity = Vector2(0, 500)
	
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 0.3, 0.3, 1))
	gradient.set_color(1, Color(1, 0, 0, 0))
	particles.color_ramp = gradient
	
	particles.scale_amount_min = 4
	particles.scale_amount_max = 10
	
	await get_tree().create_timer(1.5).timeout
	particles.queue_free()