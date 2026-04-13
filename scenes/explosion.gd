extends CPUParticles2D
 
func _ready():
	emitting = true   # Démarre immédiatement l'émission de particules
 
func _process(_delta):
	# Supprime le nœud une fois que toutes les particules ont été émises
	if !emitting:
		queue_free()
