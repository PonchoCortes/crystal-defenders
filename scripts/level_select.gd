extends Control

@onready var grid_container = $ScrollContainer/GridContainer
@onready var back_button = $BackButton
@onready var title_label = $TitleLabel

const LEVELS_PER_ROW = 5
const LEVEL_BUTTON_SIZE = Vector2(120, 120)

func _ready():
	setup_background()
	create_level_buttons()
	
	if back_button:
		back_button.pressed.connect(_on_back_pressed)

func setup_background():
	var color_rect = ColorRect.new()
	color_rect.name = "Background"
	add_child(color_rect)
	move_child(color_rect, 0)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.color = Color(0.1, 0.1, 0.2)

func create_level_buttons():
	if not grid_container:
		return
		
	# Limpiar botones existentes
	for child in grid_container.get_children():
		child.queue_free()
		
	grid_container.columns = LEVELS_PER_ROW
	
	# Crear botones para cada nivel
	for i in range(1, GameManager.MAX_LEVELS + 1):
		var button = create_level_button(i)
		grid_container.add_child(button)

func create_level_button(level_id: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = LEVEL_BUTTON_SIZE
	
	var is_unlocked = GameManager.is_level_unlocked(level_id)
	var stars = GameManager.get_level_stars(level_id)
	
	# Crear el contenido del botón
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	button.add_child(vbox)
	
	# Número del nivel
	var level_label = Label.new()
	level_label.text = str(level_id)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(level_label)
	
	# Estrellas
	if is_unlocked:
		var stars_label = Label.new()
		var stars_text = ""
		for j in range(3):
			if j < stars:
				stars_text += "⭐"
			else:
				stars_text += "☆"
		stars_label.text = stars_text
		stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stars_label.add_theme_font_size_override("font_size", 16)
		vbox.add_child(stars_label)
	else:
		var lock_label = Label.new()
		lock_label.text = "🔒"
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_label.add_theme_font_size_override("font_size", 32)
		vbox.add_child(lock_label)
		
	# Estilo del botón
	var style_normal = StyleBoxFlat.new()
	if is_unlocked:
		style_normal.bg_color = Color(0.2, 0.4, 0.8)
		button.disabled = false
		button.pressed.connect(func(): _on_level_selected(level_id))
	else:
		style_normal.bg_color = Color(0.3, 0.3, 0.3)
		button.disabled = true
		
	style_normal.corner_radius_top_left = 10
	style_normal.corner_radius_top_right = 10
	style_normal.corner_radius_bottom_left = 10
	style_normal.corner_radius_bottom_right = 10
	button.add_theme_stylebox_override("normal", style_normal)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.5, 1.0)
	style_hover.corner_radius_top_left = 10
	style_hover.corner_radius_top_right = 10
	style_hover.corner_radius_bottom_left = 10
	style_hover.corner_radius_bottom_right = 10
	button.add_theme_stylebox_override("hover", style_hover)
	
	return button

func _on_level_selected(level_id: int):
	var level_path = "res://scenes/levels/level_%02d.tscn" % level_id
	if ResourceLoader.exists(level_path):
		get_tree().change_scene_to_file(level_path)
	else:
		print("Level not found: ", level_path)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")