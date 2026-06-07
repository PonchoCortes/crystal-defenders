extends Node2D

signal level_complete
signal level_failed

@export var level_id: int = 1
@export var grenades_available: int = 3
@export var par_grenades: int = 2

var grenades_used: int = 0
var enemies_killed: int = 0
var collectibles_collected: int = 0
var total_enemies: int = 0
var total_collectibles: int = 0

var is_aiming: bool = false
var aim_start_pos: Vector2
var current_power: float = 0.0
var max_power: float = 1500.0
var level_started: bool = false

@onready var camera = $Camera2D
@onready var trajectory = $Trajectory
@onready var grenade_spawn = $GrenadeSpawn
@onready var hud = $CanvasLayer/HUD

const GRENADE_SCENE = preload("res://scenes/grenade.tscn")

func _ready():
	GameManager.start_level(level_id, grenades_available)
	
	# Contar enemigos y coleccionables
	await get_tree().process_frame
	total_enemies = get_tree().get_nodes_in_group("enemy").size()
	total_collectibles = get_tree().get_nodes_in_group("collectible").size()
	
	update_hud()
	
	# Conectar señales de enemigos
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy.is_connected("tree_exiting", _on_enemy_died):
			enemy.tree_exiting.connect(_on_enemy_died)
			
	# Conectar señales de coleccionables
	for collectible in get_tree().get_nodes_in_group("collectible"):
		if collectible.has_signal("collected"):
			collectible.collected.connect(_on_collectible_collected)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				start_aiming(event.position)
			else:
				release_grenade()
	elif event is InputEventMouseMotion and is_aiming:
		update_aim(event.position)
	elif event.is_action_pressed("restart"):
		restart_level()

func start_aiming(mouse_pos: Vector2):
	if GameManager.get_grenades_remaining() <= 0:
		if hud:
			hud.show_message("No grenades left!", 1.5)
		return
		
	is_aiming = true
	aim_start_pos = get_global_mouse_position()
	if trajectory:
		trajectory.visible = true

func update_aim(mouse_pos: Vector2):
	if not is_aiming:
		return
		
	var current_pos = get_global_mouse_position()
	var direction = aim_start_pos - current_pos
	current_power = min(direction.length() * 3, max_power)
	
	# Actualizar trayectoria
	if trajectory and grenade_spawn:
		var velocity = direction.normalized() * current_power
		trajectory.calculate_trajectory(grenade_spawn.global_position, velocity)
		
	# Actualizar HUD con power
	if hud:
		hud.update_power(current_power / max_power)

func release_grenade():
	if not is_aiming:
		return
		
	is_aiming = false
	
	if trajectory:
		trajectory.hide_trajectory()
		
	if hud:
		hud.update_power(0)
		
	if not GameManager.use_grenade():
		return
		
	level_started = true
	grenades_used += 1
	
	# Crear granada
	var grenade = GRENADE_SCENE.instantiate()
	add_child(grenade)
	grenade.global_position = grenade_spawn.global_position
	
	# Lanzar
	var current_pos = get_global_mouse_position()
	var direction = aim_start_pos - current_pos
	grenade.launch(direction.normalized(), current_power)
	
	if grenade.has_signal("exploded"):
		grenade.exploded.connect(_on_grenade_exploded)
		
	update_hud()
	
	# Verificar si fue la última granada
	if GameManager.get_grenades_remaining() <= 0:
		await get_tree().create_timer(3.0).timeout
		check_level_completion()

func _on_grenade_exploded(pos: Vector2):
	# Shake de cámara
	if camera and camera.has_method("shake"):
		camera.shake(0.5, 20, 15)

func _on_enemy_died():
	enemies_killed += 1
	
	await get_tree().create_timer(0.1).timeout
	
	var remaining = get_tree().get_nodes_in_group("enemy").size()
	update_hud()
	
	if remaining == 0 and level_started:
		level_completed()

func _on_collectible_collected():
	collectibles_collected += 1
	GameManager.add_score(50)
	update_hud()

func level_completed():
	GameManager.complete_level(enemies_killed, grenades_used, collectibles_collected, total_collectibles)
	
	show_victory_screen()
	level_complete.emit()

func check_level_completion():
	var remaining_enemies = get_tree().get_nodes_in_group("enemy").size()
	
	if remaining_enemies == 0 and level_started:
		level_completed()
	elif level_started:
		level_failed.emit()
		show_failure_screen()

func update_hud():
	if not hud:
		return
		
	hud.update_grenades(GameManager.get_grenades_remaining())
	hud.update_enemies(total_enemies - enemies_killed, total_enemies)
	hud.update_score(GameManager.current_score)
	hud.update_collectibles(collectibles_collected, total_collectibles)

func show_victory_screen():
	var stars = GameManager.calculate_stars(enemies_killed, grenades_used, collectibles_collected, total_collectibles)
	
	if hud:
		hud.show_victory(stars, GameManager.current_score)

func show_failure_screen():
	if hud:
		hud.show_failure()

func restart_level():
	get_tree().reload_current_scene()

func next_level():
	var next_level_id = level_id + 1
	if next_level_id <= GameManager.MAX_LEVELS:
		var next_scene = "res://scenes/levels/level_%02d.tscn" % next_level_id
		if ResourceLoader.exists(next_scene):
			get_tree().change_scene_to_file(next_scene)
		else:
			return_to_menu()
	else:
		return_to_menu()

func return_to_menu():
	get_tree().change_scene_to_file("res://scenes/ui/menu.tscn")