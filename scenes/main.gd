extends Node

# Variables de jeu globales

var wave : int                        # Numéro de la vague actuelle
var difficulty : float                # Difficulté courante (nombre d'ennemis)
const DIFF_MULTIPLIER : float = 1.2   # Multiplicateur de difficulté entre chaque vague
var max_enemies : int                 # Nombre d'ennemis à spawner pour la vague actuelle
var lives : int                       # Nombre de vies restantes du joueur
var countdown : int                   # Compteur pour le décompte entre les vagues
var wave_ending : bool = false        # Verrou pour éviter que is_wave_completed() soit appelé en boucle
 
# Liste de toutes les améliorations disponibles
var upgrades = ["max_mana", "mana_regen", "mana_cost", "speed", "life"]
 
# Textes affichés sur les boutons du menu d'amélioration
var upgrade_labels = {
	"max_mana": "+15 Max Mana",
	"mana_regen": "+3 Mana Regen",
	"mana_cost": "-3 Shoot cost",
	"speed": "+15 Speed",
	"life": "+1 Life"
}
 
# Les 3 améliorations actuellement proposées au joueur
var current_upgrades = []

# Initialisation

func _ready():
	new_game()
	# Connecte les boutons des menus à leurs fonctions respectives
	$GameOver/Button.pressed.connect(new_game)
	$WinScreen/Button.pressed.connect(new_game)
	$UpgradeMenu/Upgrade1.pressed.connect(_on_upgrade1_pressed)
	$UpgradeMenu/Upgrade2.pressed.connect(_on_upgrade2_pressed)
	$UpgradeMenu/Upgrade3.pressed.connect(_on_upgrade3_pressed)
 
# Démarre une nouvelle partie depuis zéro
func new_game():
	# Connecte le signal de mana du joueur une seule fois pour éviter les doublons
	if not $Player.mana_changed.is_connected(_on_mana_changed):
		$Player.mana_changed.connect(_on_mana_changed)
	lives = 3
	wave = 1
	difficulty = 10.0
	$EnemySpawner/Timer.wait_time = 1.0
	reset()

# Réinitialisation entre les vagues

# Remet la scène à zéro pour la vague actuelle
func reset():
	wave_ending = false
 
	# Calcule le nombre d'ennemis selon la vague
	if wave == 5:
		max_enemies = 1  # Vague boss : un seul ennemi
	else:
		max_enemies = int(difficulty)
 
	# Réinitialise le joueur et supprime tous les éléments en jeu
	$Player.reset()
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("bullets", "queue_free")
	get_tree().call_group("items", "queue_free")
 
	# Met à jour le HUD
	$Hud/LivesLabel.text = "X " + str(lives)
	$Hud/WaveLabel.text = "WAVE: " + str(wave)
	$Hud/EnemiesLabel.text = "X " + str(max_enemies)
 
	# Cache tous les écrans d'interface
	$GameOver.hide()
	$WinScreen.hide()
	$WaveTransition.hide()
	$UpgradeMenu.hide()
 
	# Met le jeu en pause et démarre le timer de démarrage
	get_tree().paused = true
	$RestartTimer.start()

# Boucle principale

func _process(_delta):
	# Vérifie chaque frame si la vague est terminée (sans doublon grâce à wave_ending)
	if is_wave_completed() and not wave_ending:
		wave_ending = true
		wave += 1
		difficulty *= DIFF_MULTIPLIER
 
		# Accélère le spawn des ennemis au fil des vagues (minimum 0.25s)
		if $EnemySpawner/Timer.wait_time > 0.25:
			$EnemySpawner/Timer.wait_time -= 0.05
 
		# Démarre le timer qui laisse le temps au joueur de ramasser les items
		$ItemCollectTimer.start()

# Transitions entre vagues

# Appelé quand le timer de ramassage d'items expire : affiche le menu d'upgrade
func _on_item_collect_timer_timeout():
	get_tree().paused = true
	show_upgrade_menu()
 
# Sélectionne 3 améliorations aléatoires et affiche le menu
func show_upgrade_menu():
	current_upgrades = upgrades.duplicate()
	current_upgrades.shuffle()
	current_upgrades = current_upgrades.slice(0, 3)
 
	$UpgradeMenu/Upgrade1.text = upgrade_labels[current_upgrades[0]]
	$UpgradeMenu/Upgrade2.text = upgrade_labels[current_upgrades[1]]
	$UpgradeMenu/Upgrade3.text = upgrade_labels[current_upgrades[2]]
 
	# PROCESS_MODE_ALWAYS permet au menu de fonctionner même en pause
	$UpgradeMenu.process_mode = Node.PROCESS_MODE_ALWAYS
	$UpgradeMenu.show()
 
# Callbacks des 3 boutons d'amélioration
func _on_upgrade1_pressed():
	apply_upgrade(current_upgrades[0])
func _on_upgrade2_pressed():
	apply_upgrade(current_upgrades[1])
func _on_upgrade3_pressed():
	apply_upgrade(current_upgrades[2])
 
# Applique l'amélioration choisie et lance la transition de vague
func apply_upgrade(type: String):
	if type == "life":
		# L'amélioration "vie" est gérée ici car elle affecte main.gd
		lives += 1
		$Hud/LivesLabel.text = "X " + str(lives)
	else:
		# Les autres améliorations sont déléguées au joueur
		$Player.apply_upgrade(type)
	$UpgradeMenu.hide()
	show_wave_transition()
 
# Affiche le compte à rebours 3-2-1 avant la prochaine vague
func show_wave_transition():
	countdown = 3
	$WaveTransition.show()
	$WaveTransition/WaveLabel.text = "WAVE " + str(wave) + " INCOMING!"
	$WaveTransition/CountdownLabel.text = str(countdown)
	$CountdownTimer.process_mode = Node.PROCESS_MODE_ALWAYS
	$CountdownTimer.start()
 
# Décrémente le compteur chaque seconde, lance reset() quand il atteint 0
func _on_countdown_timer_timeout():
	countdown -= 1
	$WaveTransition/CountdownLabel.text = str(countdown)
	if countdown <= 0:
		$CountdownTimer.stop()
		$WaveTransition.hide()
		reset()

# Gestion des vies et game over

# Appelé quand un ennemi touche le joueur
func _on_enemy_spawner_hit_p():
	lives -= 1
	$Hud/LivesLabel.text = "X " + str(lives)
	get_tree().paused = true
 
	if lives <= 0:
		# Plus de vies : affiche le game over avec le score
		$GameOver/WavesSurvivedLabel.text = "WAVES SURVIVED: " + str(wave - 1)
		$GameOver.show()
	else:
		# Il reste des vies : redémarre la vague après un délai
		$WaveOverTimer.start()
 
func _on_wave_over_timer_timeout():
	reset()
 
# Reprend le jeu après la pause initiale
func _on_restart_timer_timeout():
	get_tree().paused = false

# Condition de fin de vague

# Retourne true si tous les ennemis sont morts ET que le quota a été atteint
func is_wave_completed():
	var all_dead = true
	var enemies = get_tree().get_nodes_in_group("enemies")
 
	# Attend que tous les ennemis prévus aient été spawnés
	if enemies.size() == max_enemies:
		for e in enemies:
			if e.alive:
				all_dead = false
		return all_dead
	else:
		return false

# Victoire

# Appelé par boss.gd quand le boss est tué : affiche l'écran de victoire
func boss_defeated():
	get_tree().paused = true
	$WinScreen.show()

# HUD - Mana

# Met à jour la barre de mana dans le HUD à chaque changement
func _on_mana_changed(current, maximum):
	$Hud/ManaBar.max_value = maximum
	$Hud/ManaBar.value = current
