extends CanvasLayer

onready var gameMenu = get_node("GameMenu")

var game_menu_on = false

func _ready():
	get_node("GameMenu").hide()


func _process(delta):
	if game_menu_on:
		gameMenu.show()
	else:
		gameMenu.hide()


func _on_Resume_pressed():
	game_menu_on = false


func _on_QuitGame_pressed():
	get_tree().quit()
