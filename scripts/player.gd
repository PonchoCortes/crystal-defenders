extends CharacterBody2D

@export var health: int = 100
@export var max_health: int = 100

var is_alive: bool = true

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	add_to_group("player")
	create_visual()

func create_visual():
	# Crear sprite del jugador (cuadrado azul)
	sprite.texture = create_player_texture()
	sprite.centered = true
	
	# Collision shape
	var rect = RectangleShape2D.new()
	rect.size = Vector2(40, 40)
	collision_shape.shape = rect

func create_player_texture() -> ImageTexture:
	var size = 40
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	
	# Cuerpo azul
	for x in range(4, size - 4):
		for y in range(4, size - 4):
			img.set_pixel(x, y, Color(0.2, 0.5, 1.0))
			
	# Borde
	for i in range(size):
		for thickness in range(3):
			if i + thickness < size:
				img.set_pixel(thickness, i, Color(0.1, 0.3, 0.7))
				img.set_pixel(size - 1 - thickness, i, Color(0.1, 0.3, 0.7))
				img.set_pixel(i, thickness, Color(0.1, 0.3, 0.7))
				img.set_pixel(i, size - 1 - thickness, Color(0.1, 0.3, 0.7))
				
	# Cara
	for eye_x in [15, 25]:
		for dx in range(-2, 3):
			for dy in range(-2, 3):
				if Vector2(dx, dy).length() <= 2:
					img.set_pixel(eye_x + dx, 15 + dy, Color.BLACK)
					
	return ImageTexture.create_from_image(img)

func take_damage(amount: int):
	if not is_alive:
		return
		
	health -= amount
	health = max(0, health)
	
	flash_damage()
	
	if health <= 0:
		die()

func flash_damage():
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 0.3, 0.3), 0.1)
	tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.1)

func die():
	is_alive = false
	create_death_effect()
	
	# Esperar un poco antes de eliminar
	await get_tree().create_timer(0.5).timeout
	queue_free()

func create_death_effect():
	var particles = CPUParticles2D.new()
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 30
	particles.lifetime = 1.0
	particles.explosiveness = 0.8
	
	particles.direction = Vector2(0, -1)
	particles.spread = 180
	particles.initial_velocity_min = 100
	particles.initial_velocity_max = 200
	particles.gravity = Vector2(0, 400)
	
	particles.color = Color(0.2, 0.5, 1.0)
	particles.scale_amount_min = 4
	particles.scale_amount_max = 8
	
	await get_tree().create_timer(1.5).timeout
	particles.queue_free()