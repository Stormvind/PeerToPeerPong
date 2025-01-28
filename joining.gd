extends Control
var has_received_start_confirmation : bool = false;
var UDP := PacketPeerUDP.new();
var confirmed_time_to_start : float;
var synchronization : Dictionary;
var Text_Edit_Status : TextEdit;
var timeout_timer : float = Time.get_unix_time_from_system() + 10;
var second_timer : float;
var timer_number : int;
var transscenic : Node;

func _ready():
	transscenic = $"/root/Transscenic_Variables";
	# UDP is connectionless; this only configures the destination. Does not actually send data
	UDP.connect_to_host(transscenic.peer_address,
	transscenic.network_port);
	Text_Edit_Status = $Text_Edit_Status;
	Text_Edit_Status.text = "Attempting to connect. Giving up if no connection is made in 10 seconds\n";
	synchronization["seed"] = Time.get_ticks_msec();

func _physics_process(_delta):
	var current_time : float = Time.get_unix_time_from_system();
	
	if ((current_time >= timeout_timer) && !has_received_start_confirmation):
		UDP.close();
		get_tree().change_scene_to_file("res://start_menu.tscn");
		
	if !has_received_start_confirmation:
		synchronization["requested_time_to_start"] = current_time + 5.0;
		UDP.put_var(synchronization);
		if UDP.get_available_packet_count() > 0:
			var received_synchronization : Dictionary = UDP.get_var();
			confirmed_time_to_start = received_synchronization["requested_time_to_start"];
			if (!received_synchronization.has("seed")
			|| received_synchronization["seed"] != synchronization["seed"]):
				UDP.close();
				get_tree().change_scene_to_file("res://start_menu.tscn");
			has_received_start_confirmation = true;
			timer_number = round(confirmed_time_to_start - current_time);
			second_timer = current_time + 1;
			Text_Edit_Status.text += "Connected to host. The game will begin soon\n" \
			+ str(timer_number) + "\n";
		return;
		
	if current_time >= confirmed_time_to_start:
		transscenic.connection = UDP;
		transscenic.is_host = false;
		transscenic.seed = synchronization["seed"];
		get_tree().change_scene_to_file("res://pong.tscn");
		
	if current_time >= second_timer:
		timer_number -= 1;
		Text_Edit_Status.text += str(timer_number) + "\n";
		second_timer = current_time + 1;
		
