extends CharacterBody2D

# Signaux

signal shoot                              # Émis lors d'un tir : transmet position et direction
signal mana_changed(current, maximum)     # Émis à chaque changement de mana pour mettre à jour le HUD

# Références HUD

@onready var staff_label = get_node("/root/Main/Hud/StaffLabel")   # Label affichant le timer du staff actif
@onready var boost_label = get_node("/root/Main/Hud/BoostLabel")   # Label affichant le timer du boost de vitesse

# Constantes de déplacement et de tir

const START_SPEED : int = 200     # Vitesse de déplacement de base
const BOOST_SPEED : int = 400     # Vitesse de déplacement pendant le boost (item café)
const NORMAL_SHOT : float = 0.5   # Cooldown normal entre deux tirs (secondes)
const FAST_SHOT : float = 0.1     # Cooldown réduit avec l'item pistolet rapide

# Variables de jeu

var speed : int                       # Vitesse actuelle (modifiable par upgrades/boost)
var can_shoot : bool                  # Verrou de tir : false pendant le cooldown du ShotTimer
var screen_size : Vector2             # Dimensions de l'écran, utilisées pour le clamping
 
# Système de mana
var max_mana : float = 100.0          # Mana maximale (augmentable via upgrade)
var mana_cost : float = 25.0          # Coût en mana par tir (réductible via upgrade)
var mana_regen : float = 10.0         # Régénération de mana par seconde (augmentable via upgrade)
var mana : float                      # Mana courante
 
# Système de projectiles
var bullet_type : String = "normal"   # Type de projectile actif : "normal", "fire" ou "ice"
var staff_active : bool = false       # True si un staff est actuellement actif

# Initialisation

func _ready():
	screen_size = get_viewport_rect().size
	reset()
 
# Réinitialise le joueur au début de chaque vague
func reset():
	can_shoot = true
	position = screen_size / 2        # Repositionne au centre de l'écran
	speed = START_SPEED
	$ShotTimer.wait_time = NORMAL_SHOT
	mana = max_mana                   # Recharge la mana au maximum

# Entrées joueur

func get_input():
	# Déplacement clavier (ZQSD ou flèches directionnelles)
	var input_dir = Input.get_vector("left", "right", "up", "down")
	velocity = input_dir.normalized() * speed
 
	# Tir à la souris : clic gauche, pas en cooldown, et assez de mana
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and can_shoot and mana >= mana_cost:
		var dir = get_global_mouse_position() - position
		shoot.emit(position, dir)      # Informe BulletManager de créer un projectile
		mana -= mana_cost              # Consomme la mana
		mana_changed.emit(mana, max_mana)
		can_shoot = false              # Active le cooldown
		$ShotTimer.start()

# Système d'améliorations (upgrades)

# Applique une amélioration permanente au joueur
func apply_upgrade(type: String):
	match type:
		"max_mana":
			max_mana += 15.0
			mana = max_mana           # Recharge immédiatement au nouveau maximum
		"mana_regen":
			mana_regen += 3.0
		"mana_cost":
			mana_cost = max(3.0, mana_cost - 3.0)   # Minimum 3.0 pour éviter le tir gratuit
		"speed":
			speed += 15

# Boucle physique

func _physics_process(_delta):
	get_input()
	move_and_slide()
 
	# Empêche le joueur de sortir des limites de l'écran
	position = position.clamp(Vector2.ZERO, screen_size)
 
	# Régénération automatique de mana chaque frame
	mana = min(mana + mana_regen * _delta, max_mana)
	mana_changed.emit(mana, max_mana)
 
	# ── Animation directionnelle ──
	# Calcule l'angle vers la souris et le quantifie en 8 directions (pas de 45°)
	var mouse = get_local_mouse_position()
	var angle = snappedf(mouse.angle(), PI / 4) / (PI / 4)
	angle = wrapi(int(angle), 0, 8)   # Valeurs de 0 à 7 en boucle
 
	var new_anim : String
	var new_flip : bool = false
 
	# Correspondance angle → animation
	# Les directions 3, 4, 5 utilisent le flip horizontal des animations existantes
	match angle:
		0: new_anim = "walk0"                          # Droite
		1: new_anim = "walk1"                          # Bas-droite
		2: new_anim = "walk2"                          # Bas
		3: new_anim = "walk1"; new_flip = true         # Bas-gauche (miroir de walk1)
		4: new_anim = "walk0"; new_flip = true         # Gauche (miroir de walk0)
		5: new_anim = "walk3"; new_flip = true         # Haut-gauche (miroir de walk3)
		6: new_anim = "walk4"                          # Haut
		7: new_anim = "walk3"                          # Haut-droite
 
	# Ne change l'animation que si nécessaire pour éviter de reset le frame courant
	if $AnimatedSprite2D.animation != new_anim or $AnimatedSprite2D.flip_h != new_flip:
		$AnimatedSprite2D.animation = new_anim
		$AnimatedSprite2D.flip_h = new_flip
 
	# Joue l'animation si le joueur se déplace, sinon la met en pause sur le frame 0
	if velocity.length() != 0:
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.frame = 0
 
	# ── Affichage du timer de staff ──
	if staff_active:
		var time_left = $StaffTimer.time_left
		if bullet_type == "fire":
			staff_label.text = "🔥 " + "%.1f" % time_left + "s"
		elif bullet_type == "ice":
			staff_label.text = "❄️ " + "%.1f" % time_left + "s"
	else:
		staff_label.text = ""
 
	# ── Affichage du timer de boost ──
	if $BoostTimer.time_left > 0:
		boost_label.text = "☕ " + "%.1f" % $BoostTimer.time_left + "s"
	else:
		boost_label.text = ""

# Items actifs

# Active le boost de vitesse (item café)
func boost():
	$BoostTimer.start()
	speed = BOOST_SPEED
 
# Active le mode tir rapide (ancien item pistolet)
func quick_fire():
	$FastFireTimer.start()
	$ShotTimer.wait_time = FAST_SHOT
 
# Active un staff (fire ou ice) pendant 15 secondes
func apply_staff(type: String):
	bullet_type = type
	staff_active = true
	$ShotTimer.wait_time = 0.8   # Cooldown plus long pour compenser la puissance du splash
	$StaffTimer.start()

# Callbacks des timers

# Fin du cooldown de tir : autorise à nouveau le tir
func _on_shot_timer_timeout():
	can_shoot = true
 
# Fin du boost de vitesse : retour à la vitesse normale
func _on_boost_timer_timeout():
	speed = START_SPEED
 
# Fin du tir rapide : retour au cooldown normal
func _on_fast_fire_timer_timeout():
	$ShotTimer.wait_time = NORMAL_SHOT
 
# Fin du buff de staff : retour au projectile normal
func _on_staff_timer_timeout():
	bullet_type = "normal"
	staff_active = false
	$ShotTimer.wait_time = NORMAL_SHOT
