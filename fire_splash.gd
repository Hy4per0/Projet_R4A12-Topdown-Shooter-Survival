extends Node2D
 
var radius = 0.0                          # Rayon actuel du cercle (part de 0)
var color = Color(1, 0.3, 0, 0.4)        # Orange-rouge semi-transparent
const MAX_RADIUS = 100.0                  # Rayon final = même valeur que SPLASH_RADIUS dans bullet.gd
 
# Dessine un cercle plein à l'origine locale
func _draw():
	draw_circle(Vector2.ZERO, radius, color)
 
func _process(delta):
	# Augmente le rayon rapidement (atteint MAX_RADIUS en 0.25s)
	radius = min(radius + MAX_RADIUS * 4 * delta, MAX_RADIUS)
	# Fade out : opacité diminue proportionnellement à l'expansion
	modulate.a = 1.0 - (radius / MAX_RADIUS)
	queue_redraw()   # Force le redessinage chaque frame
	# Supprime le nœud quand complètement transparent
	if modulate.a <= 0:
		queue_free()
 
