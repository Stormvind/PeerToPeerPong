extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$Button_Host.pressed.connect(func():
			
			get_tree().change_scene_to_file("res://hosting.tscn"));
			
	$Button_Join.pressed.connect(func(): get_tree().change_scene_to_file("res://joining.tscn"));
	$Button_Quit.pressed.connect(func(): get_tree().quit());

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
