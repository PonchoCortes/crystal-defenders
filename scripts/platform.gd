extends StaticBody2D

@export_enum("ground", "wood", "metal", "ice") var platform_type: String = "ground"
@export var platform_width: float = 200.0
@export var platform_height: float = 40.0

@onready var sprite = $Sprite2D
@onready var collision_shape = $CollisionShape2D

func _ready():
	create_platform()

func create_platform():
	# Crear textura
	sprite.texture = create_platform_texture()
	sprite.centered = false
	sprite.position = Vector2(-platform_width / 2, -platform_height / 2)
	
	# Crear collision shape
	var rect = RectangleShape2D.new()
	rect.size = Vector2(platform_width, platform_height)
	collision_shape.shape = rect
	
	# Configurar capas
	collision_layer = 1  # World layer
	collision_mask = 0

func create_platform_texture() -> ImageTexture:
	var img = Image.create(int(platform_width), int(platform_height), false, Image.FORMAT_RGBA8)
	
	var color: Color
	match platform_type:
		"ground":
			color = Color(0.4, 0.3, 0.2)
		"wood":
			color = Color(0.6, 0.4, 0.2)
		"metal":
			color = Color(0.5, 0.5, 0.6)
		"ice":
			color = Color(0.7, 0.9, 1.0)
			
	# Rellenar con color base
	img.fill(color)
	
	# Agregar textura/patrón
	for x in range(int(platform_width)):
		for y in range(int(platform_height)):
			var noise_value = (sin(x * 0.1) + sin(y * 0.1)) * 0.05
			var pixel_color = Color(
				color.r + noise_value,
				color.g + noise_value,
				color.b + noise_value
			)
			img.set_pixel(x, y, pixel_color)
			
	# Borde superior más claro
	for x in range(int(platform_width)):
		for y in range(3):
			var lighter = color.lightened(0.2)
			img.set_pixel(x, y, lighter)
			
	# Borde inferior más oscuro
	for x in range(int(platform_width)):
		for y in range(int(platform_height) - 3, int(platform_height)):
			var darker = color.darkened(0.2)
			img.set_pixel(x, y, darker)
			
	return ImageTexture.create_from_image(img)

func get_friction() -> float:
	match platform_type:
		"ice":
			return 0.1
		"metal":
			return 0.3
		"wood":
			return 0.5
		_:
			return 1.0