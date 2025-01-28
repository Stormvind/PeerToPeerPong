extends Control
var Text_Edit_Status : TextEdit;
var server := UDPServer.new();
var peer : PacketPeerUDP;
var has_received_start_request : bool = false;
var synchronization : Dictionary;
var second_timer : float;
var timer_number : int = 4;
var transscenic : Node;

func _ready():
	transscenic = $"/root/Transscenic_Variables";
	Text_Edit_Status = $Text_Edit_Status;
	$Button_Cancel.pressed.connect(func():
		server.stop();
		get_tree().change_scene_to_file("res://start_menu.tscn"));
	server.listen(transscenic.network_port);
	Text_Edit_Status.text = "Awaiting connection requests\n";
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	var current_time : float = Time.get_unix_time_from_system();
	server.poll();
	if !has_received_start_request:
		if server.is_connection_available():
			peer = server.take_connection();
			has_received_start_request = true;
			synchronization = peer.get_var();
			Text_Edit_Status.text += "A user connected. The game will begin soon\n5";
			second_timer = current_time;
		return;
	
	if current_time >= (second_timer + 1.0):
		Text_Edit_Status.text += "\n" + str(timer_number);
		timer_number -= 1;
		second_timer = current_time;
			
	if current_time >= synchronization["requested_time_to_start"]:
		transscenic.server = server;
		transscenic.connection = peer;
		transscenic.is_host = true;
		get_tree().change_scene_to_file("res://pong.tscn");
	# Sends confirmation of which time to start at, and returns the seed for randomness sent by the joiner
	peer.put_var(synchronization);
		
