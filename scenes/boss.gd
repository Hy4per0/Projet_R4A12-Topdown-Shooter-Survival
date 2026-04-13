extends CharacterBody2D

# Références de scène

@onready var main = get_node("/root/Main")           # Pour instancier l'explosion et appeler boss_defeated()
@onready var player = get_node("/root/Main/Player")  # Pour la poursuite
 
var explosion_scene := preload("res://scenes/explosion.tscn")
 
signal hit_player   # Émis quand le boss touche le joueur

# Variables

var alive : bool          # True tant que le boss est en vie
var entered : bool        # False pendant l'entrée, True quand la poursuite commence
var speed : int = 60      # Plus lent que les rats (100) pour compenser sa taille et ses HP
var direction : Vector2   # Direction de déplacement courante
var hp : int = 10         # Points de vie : nécessite 10 touches pour mourir

# Initialisation

func _ready():
	var screen_rect = get_viewport_rect()
	alive = true
	entered = false
	scale = Vector2(2.0, 2.0)   # 2x plus grand que les rats normaux
	$AnimatedSprite2D.animation = "run"
	$AnimatedSprite2D.play()
 
	# Même logique d'entrée que le rat : vers le centre de l'écran
	var dist = screen_rect.get_center() - position
	if abs(dist.x) > abs(dist.y):
		direction.x = dist.x
		direction.y = 0
	else:
		direction.x = 0
		direction.y = dist.y
 
# Boucle physique

func _physics_process(_delta):
	if alive:
		if entered:
			direction = (player.position - position)
 
		direction = direction.normalized()
		velocity = direction * speed
		move_and_slide()
 
		if velocity.x != 0:
			$AnimatedSprite2D.flip_h = velocity.x < 0

# Système de dégâts

# Appelé par bullet.gd à chaque impact de projectile
func take_damage():
	# Ignore si déjà mort (évite les appels multiples avec async)
	if not alive:
		return
 
	hp -= 1
 
	# Effet visuel de flash : semi-transparent pendant 0.1 seconde
	$AnimatedSprite2D.modulate = Color(1, 1, 1, 0.5)
	await get_tree().create_timer(0.1).timeout
 
	# Vérifie à nouveau après l'await (le boss peut avoir été tué entretemps)
	if not alive:
		return
 
	$AnimatedSprite2D.modulate = Color(1, 1, 1, 1)   # Restore la couleur normale
 
	if hp <= 0:
		die()
 
# Mort

func die():
	# Verrou pour éviter les appels multiples
	if not alive:
		return
	alive = false
 
	$AnimatedSprite2D.animation = "dead"
	$AnimatedSprite2D.play()
	$Area2D/CollisionShape2D.set_deferred("disabled", true)
 
	# Instancie l'explosion de particules
	var explosion = explosion_scene.instantiate()
	explosion.position = position
	main.add_child(explosion)
	explosion.process_mode = Node.PROCESS_MODE_ALWAYS
 
	# Informe main.gd que le boss est vaincu → écran de victoire
	main.boss_defeated()
 

# Callbacks

func _on_entrance_timer_timeout():
	entered = true
 
func _on_area_2d_body_entered(_body):
	hit_player.emit()
