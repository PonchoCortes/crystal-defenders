extends Camera2D

var shake_amount: float = 0.0
var shake_duration: float = 0.0
var shake_timer: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready():
	original_offset = offset

func _process(delta):
	if shake_timer > 0:
		shake_timer -= delta
		
		# Generar shake aleatorio
		var shake_offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		
		offset = original_offset + shake_offset
		
		# Reducir gradualmente
		shake_amount = lerp(shake_amount, 0.0, delta * 5.0)
	else:
		offset = original_offset

func shake(duration: float, frequency: float, amplitude: float):
	shake_duration = duration
	shake_timer = duration
	shake_amount = amplitude