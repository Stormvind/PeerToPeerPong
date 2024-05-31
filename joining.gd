extends Control
var has_received_start_confirmation : bool = false;
var UDP := PacketPeerUDP.new();
var time_to_start : float;
var Text_Edit_Status : TextEdit;
var timeout_timer : float = Time.get_unix_time_from_system() + 10;
var timer : float;
var timer_number : int;
var transscenic : Node;

# Called when the node enters the scene tree for the first time.
func _ready():
	transscenic = $"/root/Transscenic_Variables";
	UDP.connect_to_host(transscenic.peer_address,
	transscenic.network_port);
	Text_Edit_Status = $Text_Edit_Status;
	Text_Edit_Status.text = "Attempting to connect. Giving up if no connection is made in 10 seconds\n";

func _physics_process(_delta):
	var current_time : float = Time.get_unix_time_from_system();
	
	if ((current_time >= timeout_timer) && !has_received_start_confirmation):
		get_tree().change_scene_to_file("res://start_menu.tscn");
		
	if !has_received_start_confirmation:
		UDP.put_var(current_time + 5.0);
		if UDP.get_available_packet_count() > 0:
			time_to_start = UDP.get_var();
			has_received_start_confirmation = true;
			timer_number = round(time_to_start - current_time);
			timer = current_time + 1;
			Text_Edit_Status.text += "Connected to host. The game will begin soon\n" \
			+ str(timer_number) + "\n";
		return;
		
	if current_time >= time_to_start:
		transscenic.connection = UDP;
		transscenic.is_host = false;
		get_tree().change_scene_to_file("res://pong.tscn");
		
	if current_time >= timer:
		timer_number -= 1;
		Text_Edit_Status.text += str(timer_number) + "\n";
		timer = current_time + 1;
		
