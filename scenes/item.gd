extends Area2D
 
@onready var main = get_node("/root/Main")
@onready var lives_label = get_node("/root/Main/Hud/LivesLabel")
 
# Type d'item : 0=café, 1=soin, 2=mana, 3=fire staff, 4=ice staff
var item_type : int
 
# Textures préchargées pour chaque type d'item
var coffee_box = preload("res://assets/items/coffee_box.png")
var health_box = preload("res://assets/items/health_box.png")
var mana_potion = preload("res://assets/items/manaBottle.png")
var fire_staff = preload("res://assets/items/fire_staff.png")
var ice_staff = preload("res://assets/items/ice_staff.png")
var textures = [coffee_box, health_box, mana_potion, fire_staff, ice_staff]
 
func _ready():
	# Assigne la texture correspondant au type d'item
	$Sprite2D.texture = textures[item_type]
 
# Appelé quand le joueur marche sur l'item
func _on_body_entered(body):
	if item_type == 0:
		body.boost()                                             # Café : boost de vitesse temporaire
	elif item_type == 1:
		main.lives += 1                                          # Soin : +1 vie
		lives_label.text = "X " + str(main.lives)
	elif item_type == 2:
		body.mana = min(body.mana + 50.0, body.max_mana)        # Mana : +50 sans dépasser le max
	elif item_type == 3:
		body.apply_staff("fire")                                 # Fire staff : projectiles de feu
	elif item_type == 4:
		body.apply_staff("ice")                                  # Ice staff : projectiles de glace
	queue_free()   # Supprime l'item après ramassage
