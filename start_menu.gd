extends Control
var Line_Edit_IP_Address : Node;

# Called when the node enters the scene tree for the first time.
func _ready():
	Line_Edit_IP_Address = $Line_Edit_IP_Address;
	
	$Button_Join.pressed.connect(func():
			if (Line_Edit_IP_Address.text.is_valid_ip_address() == false):
				$Label_Error.text = "The specified IP address is invalid";
				return;
			$"/root/Transscenic_Variables".input_delay = $Option_Button_Input_Delay.selected;
			$"/root/Transscenic_Variables".peer_address = Line_Edit_IP_Address.text;
			get_tree().change_scene_to_file("res://joining.tscn"));
			
	$Button_Host.pressed.connect(func():
		$"/root/Transscenic_Variables".input_delay = $Option_Button_Input_Delay.selected;
		get_tree().change_scene_to_file("res://hosting.tscn"));
		
	$Button_Quit.pressed.connect(func(): get_tree().quit());

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
