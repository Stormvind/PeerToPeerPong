extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$Button_Cancel.pressed.connect(func(): get_tree().change_scene_to_file("res://start_menu.tscn"));


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
