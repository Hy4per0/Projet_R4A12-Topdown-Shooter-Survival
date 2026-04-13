extends Node2D
 
var radius = 0.0                          # Rayon actuel du cercle
var color = Color(0, 0.5, 1, 0.4)        # Bleu semi-transparent
const MAX_RADIUS = 150.0
 
# Dessine un cercle plein à l'origine locale
func _draw():
	draw_circle(Vector2.ZERO, radius, color)
 
func _process(delta):
	# Même logique que fire_splash mais avec couleur bleue
	radius = min(radius + MAX_RADIUS * 4 * delta, MAX_RADIUS)
	modulate.a = 1.0 - (radius / MAX_RADIUS)
	queue_redraw()
	if modulate.a <= 0:
		queue_free()
