extends CanvasLayer

@onready var grenades_label = $MarginContainer/TopBar/HBoxContainer/GrenadesLabel
@onready var enemies_label = $MarginContainer/TopBar/HBoxContainer/EnemiesLabel
@onready var score_label = $MarginContainer/TopBar/HBoxContainer/ScoreLabel
@onready var collectibles_label = $MarginContainer/TopBar/HBoxContainer/CollectiblesLabel

@onready var power_bar = $MarginContainer/BottomBar/VBoxContainer/PowerBar
@onready var message_label = $MessageLabel

@onready var victory_panel = $VictoryPanel
@onready var failure_panel = $FailurePanel

func _ready():
	hide_panels()
	if message_label:
		message_label.visible = false

func update_grenades(count: int):
	if grenades_label:
		grenades_label.text = "🎯 Grenades: " + str(count)

func update_enemies(remaining: int, total: int):
	if enemies_label:
		enemies_label.text = "👹 Enemies: " + str(remaining) + "/" + str(total)

func update_score(score: int):
	if score_label:
		score_label.text = "⭐ Score: " + str(score)

func update_collectibles(collected: int, total: int):
	if collectibles_label:
		collectibles_label.text = "💎 Gems: " + str(collected) + "/" + str(total)

func update_power(percentage: float):
	if power_bar:
		power_bar.value = percentage * 100

func show_victory(stars: int, score: int):
	if victory_panel:
		victory_panel.visible = true
		
		var stars_container = victory_panel.get_node_or_null("Panel/VBoxContainer/StarsContainer")
		if stars_container:
			for child in stars_container.get_children():
				child.queue_free()
				
			for i in range(3):
				var star_label = Label.new()
				if i < stars:
					star_label.text = "⭐"
				else:
					star_label.text = "☆"
				star_label.add_theme_font_size_override("font_size", 64)
				star_label.add_theme_color_override("font_color", Color(1, 0.9, 0))
				stars_container.add_child(star_label)
				
		var score_label_victory = victory_panel.get_node_or_null("Panel/VBoxContainer/ScoreLabel")
		if score_label_victory:
			score_label_victory.text = "Score: " + str(score)

func show_failure():
	if failure_panel:
		failure_panel.visible = true

func hide_panels():
	if victory_panel:
		victory_panel.visible = false
	if failure_panel:
		failure_panel.visible = false

func show_message(text: String, duration: float = 2.0):
	if message_label:
		message_label.text = text
		message_label.visible = true
		
		await get_tree().create_timer(duration).timeout
		
		if is_instance_valid(message_label):
			message_label.visible = false

func _on_retry_pressed():
	var level = get_tree().current_scene
	if level and level.has_method("restart_level"):
		level.restart_level()

func _on_next_pressed():
	var level = get_tree().current_scene
	if level and level.has_method("next_level"):
		level.next_level()

func _on_menu_pressed():
	var level = get_tree().current_scene
	if level and level.has_method("return_to_menu"):
		level.return_to_menu()