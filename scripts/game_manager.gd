extends Node

# Singleton para gestionar el estado global del juego
signal score_changed(new_score)
signal stars_changed(new_stars)
signal level_completed(level_id, stars)
signal grenade_count_changed(count)

const MAX_LEVELS = 30
const SAVE_PATH = "user://crystal_defenders_save.dat"

var current_level: int = 1
var current_score: int = 0
var total_stars: int = 0
var grenades_remaining: int = 3

# Progreso del jugador
var level_progress: Dictionary = {}
var unlocked_levels: int = 1

var settings: Dictionary = {
	"music_volume": 0.8,
	"sfx_volume": 1.0,
	"particles": true,
	"screen_shake": true
}

func _ready():
	load_game()

func start_level(level_id: int, grenades: int = 3):
	current_level = level_id
	grenades_remaining = grenades
	current_score = 0
	grenade_count_changed.emit(grenades_remaining)

func add_score(points: int):
	current_score += points
	score_changed.emit(current_score)

func use_grenade() -> bool:
	if grenades_remaining > 0:
		grenades_remaining -= 1
		grenade_count_changed.emit(grenades_remaining)
		return true
	return false

func get_grenades_remaining() -> int:
	return grenades_remaining

func complete_level(enemies_killed: int, grenades_used: int, collectibles: int, total_collectibles: int):
	var stars = calculate_stars(enemies_killed, grenades_used, collectibles, total_collectibles)
	
	# Guardar progreso
	if not level_progress.has(current_level) or level_progress[current_level] < stars:
		var old_stars = level_progress.get(current_level, 0)
		level_progress[current_level] = stars
		total_stars += (stars - old_stars)
		stars_changed.emit(total_stars)
	
	# Desbloquear siguiente nivel
	if current_level == unlocked_levels and current_level < MAX_LEVELS:
		unlocked_levels += 1
		save_game()
		
	level_completed.emit(current_level, stars)

func calculate_stars(enemies: int, grenades: int, collectibles: int, total_collectibles: int) -> int:
	var stars = 0
	
	# 1 estrella: completar el nivel
	if enemies > 0:
		stars = 1
	
	# 2 estrellas: usar pocas granadas
	if grenades <= 2:
		stars = 2
	
	# 3 estrellas: perfección (1 granada + todos los coleccionables)
	if grenades == 1 and collectibles == total_collectibles:
		stars = 3
		
	return stars

func is_level_unlocked(level_id: int) -> bool:
	return level_id <= unlocked_levels

func get_level_stars(level_id: int) -> int:
	return level_progress.get(level_id, 0)

func save_game():
	var save_data = {
		"level_progress": level_progress,
		"unlocked_levels": unlocked_levels,
		"total_stars": total_stars,
		"settings": settings
	}
	
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(save_data)
		file.close()

func load_game():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var save_data = file.get_var()
			level_progress = save_data.get("level_progress", {})
			unlocked_levels = save_data.get("unlocked_levels", 1)
			total_stars = save_data.get("total_stars", 0)
			settings = save_data.get("settings", settings)
			file.close()

func reset_progress():
	level_progress.clear()
	unlocked_levels = 1
	total_stars = 0
	current_score = 0
	save_game()