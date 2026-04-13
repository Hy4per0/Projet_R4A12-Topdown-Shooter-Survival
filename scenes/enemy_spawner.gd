extends Node2D
 
@onready var main = get_node("/root/Main")
 
signal hit_p   # Relaie le signal hit_player des ennemis vers main.gd
 
var rat_scene := preload("res://scenes/rat.tscn")
var boss_scene := preload("res://scenes/boss.tscn")
var spawn_points := []   # Liste des Marker2D disponibles comme points de spawn
 
func _ready():
	# Collecte tous les enfants de type Marker2D comme points de spawn
	for i in get_children():
		if i is Marker2D:
			spawn_points.append(i)
 
# Appelé à chaque tick du Timer de spawn
func _on_timer_timeout():
	var enemies = get_tree().get_nodes_in_group("enemies")
 
	# Spawne un ennemi seulement si le quota de la vague n'est pas atteint
	if enemies.size() < get_parent().max_enemies:
		var spawn = spawn_points[randi() % spawn_points.size()]
 
		if get_parent().wave == 5:
			# Vague boss : spawne le boss une seule fois (quand la liste est vide)
			if enemies.size() == 0:
				var boss = boss_scene.instantiate()
				boss.position = spawn.position
				boss.hit_player.connect(hit)
				main.add_child(boss)
				boss.add_to_group("enemies")
		else:
			# Vagues normales : spawne un rat
			var rat = rat_scene.instantiate()
			rat.position = spawn.position
			rat.hit_player.connect(hit)
			main.add_child(rat)
			rat.add_to_group("enemies")
 
# Relaie le signal de collision ennemi→joueur vers main.gd
func hit():
	hit_p.emit()
