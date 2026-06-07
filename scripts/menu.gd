extends Control

@onready var title_label = $VBoxContainer/TitleLabel
@onready var play_button = $VBoxContainer/ButtonsContainer/PlayButton
@onready var level_select_button = $VBoxContainer/ButtonsContainer/LevelSelectButton
@onready var settings_button = $VBoxContainer/ButtonsContainer/SettingsButton
@onready var quit_button = $VBoxContainer/ButtonsContainer/QuitButton
@onready var stats_label = $VBoxContainer/StatsLabel
@onready var animation_player = $AnimationPlayer

var particles_array: Array = []

func _ready():
	setup_background()
	update_stats()
	animate_title()
	create_background_particles()
	
	# Conectar botones
	if play_button:
		play_button.pressed.connect(_on_play_pressed)
	if level_select_button:
		level_select_button.pressed.connect(_on_level_select_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func setup_background():
	# Crear un degradado de fondo
	var color_rect = ColorRect.new()
	color_rect.name = "Background"
	add_child(color_rect)
	move_child(color_rect, 0)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var gradient_texture = GradientTexture2D.new()
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.1, 0.1, 0.3))
	gradient.set_color(1, Color(0.05, 0.05, 0.15))
	gradient_texture.gradient = gradient
	gradient_texture.fill_from = Vector2(0, 0)
	gradient_texture.fill_to = Vector2(0, 1)
	
	color_rect.texture = gradient_texture

func update_stats():
	if stats_label:
		var total_stars = GameManager.total_stars
		var max_stars = GameManager.unlocked_levels * 3
		var unlocked = GameManager.unlocked_levels
		
		stats_label.text = "⭐ Stars: %d/%d | 🔓 Levels: %d/%d" % [total_stars, max_stars, unlocked, GameManager.MAX_LEVELS]

func animate_title():
	if not title_label:
		return
		
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title_label, "scale", Vector2(1.1, 1.1), 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE)

func create_background_particles():
	for i in range(20):
		var particle = create_floating_particle()
		add_child(particle)
		particles_array.append(particle)

func create_floating_particle() -> Control:
	var particle = ColorRect.new()
	particle.size = Vector2(randf_range(2, 6), randf_range(2, 6))
	particle.color = Color(1, 1, 1, randf_range(0.1, 0.3))
	particle.position = Vector2(randf_range(0, 1280), randf_range(0, 720))
	
	var tween = create_tween()
	tween.set_loops()
	var duration = randf_range(3, 8)
	var target_y = particle.position.y + randf_range(-100, -300)
	
	tween.tween_property(particle, "position:y", target_y, duration)
	tween.tween_callback(func(): 
		particle.position.y = 720
		particle.position.x = randf_range(0, 1280)
	)
	
	return particle

func _on_play_pressed():
	# Ir al primer nivel o al último nivel jugado
	var level_to_load = 1
	if GameManager.unlocked_levels > 1:
		level_to_load = GameManager.unlocked_levels
		
	var level_path = "res://scenes/levels/level_%02d.tscn" % level_to_load
	if ResourceLoader.exists(level_path):
		get_tree().change_scene_to_file(level_path)
	else:
		get_tree().change_scene_to_file("res://scenes/levels/level_01.tscn")

func _on_level_select_pressed():
	get_tree().change_scene_to_file("res://scenes/ui/level_select.tscn")

func _on_settings_pressed():
	show_settings_popup()

func _on_quit_pressed():
	get_tree().quit()

func show_settings_popup():
	var popup = create_settings_popup()
	add_child(popup)
	popup.popup_centered()

func create_settings_popup() -> Window:
	var popup = Window.new()
	popup.title = "Settings"
	popup.size = Vector2i(400, 300)
	popup.unresizable = true
	popup.borderless = false
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 20)
	popup.add_child(vbox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	vbox.add_child(margin)
	
	var settings_vbox = VBoxContainer.new()
	settings_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(settings_vbox)
	
	# Music Volume
	var music_label = Label.new()
	music_label.text = "Music Volume"
	settings_vbox.add_child(music_label)
	
	var music_slider = HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 1
	music_slider.step = 0.1
	music_slider.value = GameManager.settings.music_volume
	music_slider.value_changed.connect(func(value): GameManager.settings.music_volume = value)
	settings_vbox.add_child(music_slider)
	
	# SFX Volume
	var sfx_label = Label.new()
	sfx_label.text = "SFX Volume"
	settings_vbox.add_child(sfx_label)
	
	var sfx_slider = HSlider.new()
	sfx_slider.min_value = 0
	sfx_slider.max_value = 1
	sfx_slider.step = 0.1
	sfx_slider.value = GameManager.settings.sfx_volume
	sfx_slider.value_changed.connect(func(value): GameManager.settings.sfx_volume = value)
	settings_vbox.add_child(sfx_slider)
	
	# Particles Toggle
	var particles_check = CheckButton.new()
	particles_check.text = "Particles Effects"
	particles_check.button_pressed = GameManager.settings.particles
	particles_check.toggled.connect(func(pressed): GameManager.settings.particles = pressed)
	settings_vbox.add_child(particles_check)
	
	# Screen Shake Toggle
	var shake_check = CheckButton.new()
	shake_check.text = "Screen Shake"
	shake_check.button_pressed = GameManager.settings.screen_shake
	shake_check.toggled.connect(func(pressed): GameManager.settings.screen_shake = pressed)
	settings_vbox.add_child(shake_check)
	
	# Reset Progress Button
	var reset_button = Button.new()
	reset_button.text = "Reset Progress"
	reset_button.pressed.connect(func():
		GameManager.reset_progress()
		update_stats()
		popup.queue_free()
	)
	settings_vbox.add_child(reset_button)
	
	# Close Button
	var close_button = Button.new()
	close_button.text = "Close"
	close_button.pressed.connect(func(): 
		GameManager.save_game()
		popup.queue_free()
	)
	settings_vbox.add_child(close_button)
	
	return popup