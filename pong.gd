extends Node2D
var seconds_left : int = 99;
var transscenic : Node;
var input_delay : int;
var archive : Dictionary = {};
var unconfirmed_requests : Dictionary = {};
var current_frame : int = 1;
var latest_100_latencies : Array = [];
var average_latency : int = 0;
var label_latency : Label;
var label_timer : Label;
# The higher this value is, the more frames must elapse before the computer
# that is ahead of the other can again wait for a frame to resynchronise
var synchronisation_interval : int = 5;
var local_frame_aheadness : int = 0;
var latest_integral_frame : int = 0;
# The amount of frames before the connection times out and the game ends
var connection_timeout_amount : int = 120;
var gamestate = {"local_position" : 299, "remote_position" : 299,
"square_position_x" : 588, "square_position_y" : 312};
var saved_gamestate = {"local_position" : 299, "remote_position" : 299,
"square_position_x" : 588, "square_position_y" : 312};

# Called when the node enters the scene tree for the first time.
func _ready():
	label_timer = $Label_Timer;
	label_latency = $Label_Latency;
	transscenic = $"/root/Transscenic_Variables";
	input_delay = transscenic.input_delay;
	var current_timestamp : int = Time.get_ticks_msec();
	for i in range(0, input_delay + 1):
		archive[i] = \
		{
			"local" : {"frame" : i, "timestamp" : current_timestamp,
			"inputs" : {"up" : false, "down" : false}},
			"remote" : {"confirmed" : false, "frame" : i, "timestamp" : 0,
			"inputs" : {"up" : false, "down" : false}}
		};
		unconfirmed_requests[i] = \
		{
			"frame" : archive[i].local.frame,
			"timestamp" : archive[i].local.timestamp,
			"inputs" : {"down" : archive[i].local.inputs.down,
						"up" : archive[i].local.inputs.up}
		};
	
func _draw() -> void:
	draw_rect(Rect2(Vector2(gamestate.square_position_x, gamestate.square_position_y),
	Vector2(25, 25)), Color.MINT_CREAM);
	if transscenic.is_host == false:
		draw_rect(Rect2(Vector2(25, gamestate.local_position), Vector2(25, 50)), Color.DARK_CYAN);
		draw_rect(Rect2(Vector2(1102, gamestate.remote_position), Vector2(25, 50)), Color.DARK_MAGENTA);
	else:
		draw_rect(Rect2(Vector2(1102, gamestate.local_position), Vector2(25, 50)), Color.DARK_MAGENTA);
		draw_rect(Rect2(Vector2(25, gamestate.remote_position), Vector2(25, 50)), Color.DARK_CYAN);

func _physics_process(_delta):
	# If ahead of the other computer, pause every fifth frame to synchronise
	if local_frame_aheadness > 0 \
	and current_frame % (synchronisation_interval + 1) == synchronisation_interval:
		local_frame_aheadness -= 1;
		return;
		
	var current_timestamp : int = Time.get_ticks_msec();
	# Write local frame
	if !archive.has(current_frame + input_delay):
		archive[current_frame + input_delay] = \
		{
			"local" : { "inputs" : {}},
			"remote" : { "confirmed" : false, "inputs" : {}}
		};

	archive[current_frame + input_delay].local.frame = current_frame + input_delay;
	archive[current_frame + input_delay].local.timestamp = current_timestamp;
	archive[current_frame + input_delay].local.inputs.up = Input.is_action_pressed("up");
	archive[current_frame + input_delay].local.inputs.down = Input.is_action_pressed("down");
	# Write assumed inputs for opponent
	if archive[current_frame].remote.confirmed == false:
		archive[current_frame].remote.inputs.down = archive[current_frame - 1].remote.inputs.down;
		archive[current_frame].remote.inputs.up = archive[current_frame - 1].remote.inputs.up;
	
	if transscenic.is_host:
		transscenic.server.poll();
	
	var message_to_send : Dictionary = {"requests" : [], "confirmations" : []};
	# Process remote frames that have arrived
	while transscenic.connection.get_available_packet_count() > 0:
		var received_message = transscenic.connection.get_var();
		# The following datatypes were sent at a previous stage.
		# Such datagrams still coming in are to be discarded
		if typeof(received_message) == TYPE_FLOAT:
			continue;
		if typeof(received_message) == TYPE_DICTIONARY && received_message.has("seed"):
			continue;
		# Process confirmations
		for confirmation in received_message.confirmations:
			unconfirmed_requests.erase(confirmation.frame);
			# Update average latency
			if latest_100_latencies.size() < 100:
				latest_100_latencies.append(current_timestamp - confirmation.timestamp);
			else:
				latest_100_latencies[confirmation.frame % 100] = \
				current_timestamp - confirmation.timestamp;
			average_latency = latest_100_latencies.\
			reduce(func(accumlator, number):
				return accumlator + number, 0) / latest_100_latencies.size();
			label_latency.text = str(average_latency) + " ms";
		# Process requests
		for request in received_message.requests:
			if !archive.has(request.frame):
				archive[request.frame] = \
				{
					"local" : { "inputs" : {}}, 
					"remote" : { "inputs" : {}}
				};
			archive[request.frame].remote.confirmed = true;
			archive[request.frame].remote.frame = request.frame;
			archive[request.frame].remote.inputs.up = request.inputs.up;
			archive[request.frame].remote.inputs.down = request.inputs.down;
			message_to_send.confirmations.append({
				"timestamp" : request.timestamp,
				"frame" : request.frame
			});
			# Determine local frame aheadness
			local_frame_aheadness = \
			(current_timestamp - (request.timestamp + average_latency)) / 16.667;
	# Add the current frame to the list of unconfirmed requests
	unconfirmed_requests[current_frame + input_delay] = \
	{
		"frame" : archive[current_frame + input_delay].local.frame,
		"timestamp" : archive[current_frame + input_delay].local.timestamp,
		"inputs" : {"down" : archive[current_frame + input_delay].local.inputs.down,
					"up" : archive[current_frame + input_delay].local.inputs.up}
	};
	for key in unconfirmed_requests:
		message_to_send.requests.append(unconfirmed_requests[key]);
	# Send requests and confirmations
	transscenic.connection.put_var(message_to_send);
	Integrate();
	# Update the visual timer once every second
	if current_frame % 60 == 0:
		seconds_left -= 1;
		label_timer.text = str(seconds_left);
	queue_redraw();
	# Check for game end conditions: Connection timeout and draw ending due to game time elapsing
	if current_frame >= (latest_integral_frame + 120):
		End_Game("Connection failure");
	if current_frame >= 5940:
		End_Game("Draw");
	current_frame += 1;
# Process a frame by reading its inputs and changing the game state based on them
func Process_Frame(frame : int) -> void:
	gamestate.local_position += (7 * int(archive[frame].local.inputs.down));
	if gamestate.local_position > 598:
		gamestate.local_position = 598;
		
	gamestate.local_position -= (7 * int(archive[frame].local.inputs.up));
	if gamestate.local_position < 0:
		gamestate.local_position = 0;
	
	gamestate.remote_position += (7 * int(archive[frame].remote.inputs.down));
	if gamestate.remote_position > 598:
		gamestate.remote_position = 598;
		
	gamestate.remote_position -= (7 * int(archive[frame].remote.inputs.up));
	if gamestate.remote_position < 0:
		gamestate.remote_position = 0;
# Restore the game state to the latest saved game state, then process all frames from there up to the
# present. Save a more recent game state if there is an unbroken line of confirmed frames to it
func Integrate() -> void:
	gamestate.local_position = saved_gamestate.local_position;
	gamestate.remote_position = saved_gamestate.remote_position;
	var integral : bool = true;
	for i in range(latest_integral_frame, current_frame + 1):
		if archive[i].remote.confirmed == false:
			integral = false;
		if integral:
			latest_integral_frame = i;
			saved_gamestate.local_position = gamestate.local_position;
			saved_gamestate.remote_position = gamestate.remote_position;
		Process_Frame(i);

func End_Game(message : String):
	transscenic.game_over_text = message;
	if transscenic.is_host:
		transscenic.server.stop();
	transscenic.connection.close();
	get_tree().change_scene_to_file("res://game_over.tscn");
	
