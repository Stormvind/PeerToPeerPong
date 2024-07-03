extends Control
var transscenic : Node;
var frame_counter : int = 0;

func _ready():
	transscenic = $"/root/Transscenic_Variables";
	$Label_Text.text = transscenic.game_over_text

func _physics_process(_delta):
	frame_counter += 1;
	if frame_counter >= 80:
		get_tree().change_scene_to_file("res://start_menu.tscn");
