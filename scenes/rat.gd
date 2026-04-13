extends CharacterBody2D

# Références de scène

@onready var main = get_node("/root/Main")           # Référence au nœud principal pour add_child
@onready var player = get_node("/root/Main/Player")  # Référence au joueur pour la poursuite
 
var explosion_scene := preload("res://scenes/explosion.tscn")  # Particules à la mort
var item_scene := preload("res://scenes/item.tscn")            # Item droppable
 
signal hit_player   # Émis quand le rat touche le joueur

# Variables

var alive : bool          # True tant que le rat est en vie
var entered : bool        # False pendant l'entrée en scène, True quand la poursuite commence
var speed : int = 100     # Vitesse de déplacement (réduite à 40 par slow_down())
var direction : Vector2   # Direction de déplacement courante
 
const DROP_CHANCE : float = 0.15   # Probabilité de lâcher un item à la mort (35%)

# Initialisation

func _ready():
	var screen_rect = get_viewport_rect()
	alive = true
	entered = false
	$AnimatedSprite2D.animation = "run"
	$AnimatedSprite2D.play()
 
	# Calcule la direction vers le centre de l'écran
	# Si la distance horizontale est plus grande : entre par les côtés
	# Sinon : entre par le haut ou le bas
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
		# Après l'EntranceTimer, commence à poursuivre le joueur
		if entered:
			direction = (player.position - position)
 
		direction = direction.normalized()
		velocity = direction * speed
		move_and_slide()
 
		# Retourne le sprite selon la direction horizontale
		if velocity.x != 0:
			$AnimatedSprite2D.flip_h = velocity.x < 0

# Mort

func die():
	alive = false
	$AnimatedSprite2D.animation = "dead"
	$AnimatedSprite2D.play()
	$Area2D/CollisionShape2D.set_deferred("disabled", true)   # Désactive la collision sans erreur
 
	# Chance de drop d'un item
	if randf() <= DROP_CHANCE:
		drop_item()
 
	# Instancie l'explosion de particules à la position du rat
	var explosion = explosion_scene.instantiate()
	explosion.position = position
	main.add_child(explosion)
	explosion.process_mode = Node.PROCESS_MODE_ALWAYS   # Fonctionne même en pause
 
# Instancie un item aléatoire à la position du rat
func drop_item():
	var item = item_scene.instantiate()
	item.position = position
	item.item_type = randi_range(0, 4)   # 0=café, 1=soin, 2=mana, 3=fire staff, 4=ice staff
	main.call_deferred("add_child", item)
	item.add_to_group("items")

# Ralentissement (effet du projectile glace)

# Réduit la vitesse et colore le sprite en bleu pendant 3 secondes
func slow_down():
	speed = 40
	$AnimatedSprite2D.modulate = Color(0.3, 0.6, 1.0)   # Teinte bleue
	await get_tree().create_timer(3.0).timeout
	if alive:
		speed = 100
		$AnimatedSprite2D.modulate = Color(1, 1, 1)       # Restore la couleur normale

# Callbacks

# Déclenché par l'EntranceTimer : active la poursuite du joueur
func _on_entrance_timer_timeout():
	entered = true
 
# Déclenché quand le rat entre en collision avec le joueur
func _on_area_2d_body_entered(_body):
	hit_player.emit()
