extends Node2D
 
@export var bullet_scene : PackedScene   # Scène du projectile assignée dans l'éditeur
 
# Appelé par le signal shoot du joueur : crée et configure un nouveau projectile
func _on_player_shoot(pos, dir):
	var bullet = bullet_scene.instantiate()
	add_child(bullet)
	bullet.position = pos
	bullet.direction = dir.normalized()
	# Transmet le type de projectile actif du joueur au projectile créé
	bullet.bullet_type = get_parent().get_node("Player").bullet_type
	bullet.add_to_group("bullets")
