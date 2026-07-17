extends Node3D

## Level controller. Watches the exit and shows the win screen.
## Expects:
##   Level1 (Node3D)             <- this script
##     Exit (Area3D)
##       CollisionShape3D        <- BoxShape3D
##       CSGBox3D                <- so you can see it
##     WinScreen (CanvasLayer)   <- Process Mode must be "Always"
##       Background (ColorRect)
##         CenterBox (VBoxContainer)
##           Label
##           PlayAgainButton (Button)
##
## The Player node must be in the "player" group.

@onready var exit: Area3D = $Exit
@onready var win_screen: CanvasLayer = $WinScreen
@onready var play_again_button: Button = $WinScreen/Background/CenterBox/PlayAgainButton


func _ready() -> void:
	win_screen.hide()

	# Connecting signals in code instead of the editor. Same thing, but it
	# lives next to the function it calls, so you can read it in one place.
	exit.body_entered.connect(_on_exit_body_entered)
	play_again_button.pressed.connect(_on_play_again_pressed)


func _on_exit_body_entered(body: Node3D) -> void:
	# Anything can wander into the exit — skeletons, a dropped sword, whatever.
	# We only care about the player. Checking the group instead of the node name
	# means renaming things later won't quietly break this.
	if not body.is_in_group("player"):
		return

	win()


func win() -> void:
	win_screen.show()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Pausing freezes every node whose Process Mode is "Inherit" — which is all
	# of them except WinScreen, since we set that one to "Always" in the editor.
	# That's why the button still works while the world is stopped.
	get_tree().paused = true


func _on_play_again_pressed() -> void:
	# Unpause BEFORE reloading. Forget this and the fresh scene loads frozen
	# and you'll swear the game is broken.
	get_tree().paused = false
	get_tree().reload_current_scene()
