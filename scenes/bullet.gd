extends Area2D

# Variables

var speed : int = 500                    # Vitesse de déplacement du projectile (pixels/sec)
var direction : Vector2                  # Direction normalisée, définie par BulletManager
var bullet_type : String = "normal"      # Type : "normal", "fire" ou "ice" (transmis par BulletManager)
 
const SPLASH_RADIUS : float = 150.0      # Rayon de l'effet splash en pixels
 
# Scènes préchargées pour les effets visuels
var explosion_scene := preload("res://scenes/explosion.tscn")
var fire_splash_scene := preload("res://scenes/fire_splash.tscn")
var ice_splash_scene := preload("res://scenes/ice_splash.tscn")

# Déplacement

func _process(delta):
	# Avance en ligne droite dans la direction donnée
	position += speed * direction * delta
	# Joue toujours l'animation fireball (même pour fire/ice, visuellement identique)
	$AnimatedSprite2D.animation = "fireball"
	$AnimatedSprite2D.play()

# Effets visuels

# Instancie le cercle de splash selon le type (rouge pour fire, bleu pour ice)
func show_splash_visual():
	var splash = fire_splash_scene.instantiate() if bullet_type == "fire" else ice_splash_scene.instantiate()
	splash.position = position
	splash.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().get_root().get_node("Main").add_child(splash)

# Explosion / Splash

# Déclenche l'explosion et applique les effets dans le rayon de splash
func explode():
	# Instancie les particules d'explosion
	var explosion = explosion_scene.instantiate()
	explosion.position = position
	var main = get_tree().get_root().get_node("Main")
	main.add_child(explosion)
	explosion.process_mode = Node.PROCESS_MODE_ALWAYS
 
	# Affiche le cercle de splash coloré
	show_splash_visual()
 
	# Applique les effets à tous les ennemis dans le rayon
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if e.alive and position.distance_to(e.position) <= SPLASH_RADIUS:
			if bullet_type == "fire":
				# Fire : inflige 1 dégât au boss, tue les rats d'un coup
				if e.has_method("take_damage"):
					e.take_damage()
				else:
					e.die()
			elif bullet_type == "ice":
				# Ice : ralentit seulement, ne tue pas (sauf l'ennemi touché directement)
				if e.has_method("slow_down"):
					e.slow_down()
 
	queue_free()

# Callbacks

# Le Timer du projectile expire : supprime le projectile s'il n'a touché personne
func _on_timer_timeout():
	queue_free()
 
# Collision avec un corps physique
func _on_body_entered(body):
	if body.name == "World":
		# Touche le décor : disparaît simplement
		queue_free()
	else:
		if body.alive:
			# Inflige des dégâts à l'ennemi touché directement
			if body.has_method("take_damage"):
				body.take_damage()   # Boss : 1 dégât
			else:
				body.die()           # Rat : mort immédiate
 
			# Si projectile spécial, déclenche l'explosion splash en plus
			if bullet_type == "fire" or bullet_type == "ice":
				explode()
			else:
				queue_free()         # Projectile normal : disparaît après impact
