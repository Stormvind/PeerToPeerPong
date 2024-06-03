extends Node2D
var transscenic : Node;
var archive : Array = [];
var unconfirmed_requests : Dictionary = {};
var current_frame : int = 1;
var latest_100_latencies : Array = [];
var average_latency : int = 0;
var label_latency : Label;

# Called when the node enters the scene tree for the first time.
func _ready():
	label_latency = $Label_Latency;
	# 5940 frames = 99 seconds
	archive.resize(5941);
	for i in range(archive.size()):
		archive[i] = {
			"local" : {"confirmed" : false, "frame" : 0, "timestamp" : 0,
			"inputs" : {"up" : false, "down" : false}},
			"remote" : {"confirmed" : false, "frame" : 0, "timestamp" : 0,
			"inputs" : {"up" : false, "down" : false}}
		};
	RenderingServer.set_default_clear_color(Color(0,0,0))
	transscenic = $"/root/Transscenic_Variables";

func _physics_process(_delta):
	var current_timestamp : int = Time.get_ticks_msec();
	# Write local frame
	archive[current_frame].local.confirmed = true;
	archive[current_frame].local.frame = current_frame;
	archive[current_frame].local.timestamp = current_timestamp;
	archive[current_frame].local.inputs.up = Input.is_action_pressed("up");
	archive[current_frame].local.inputs.down = Input.is_action_pressed("down");
	# Write assumed inputs for opponent
	archive[current_frame].remote.inputs.down = archive[current_frame - 1].remote.inputs.down;
	archive[current_frame].remote.inputs.up = archive[current_frame - -1].remote.inputs.up;
	
	if transscenic.is_host:
		transscenic.server.poll();
	
	var message_to_send : Dictionary = {"requests" : [], "confirmations" : []};
	# Process remote frames that have arrived
	while transscenic.connection.get_available_packet_count() > 0:
		var received_message = transscenic.connection.get_var();
		if typeof(received_message) == TYPE_FLOAT:
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
			if archive[request.frame].remote.confirmed == false:
				message_to_send.confirmations.append({
					"timestamp" : request.timestamp,
					"frame" : request.frame
				});
				archive[request.frame].remote.confirmed = true;
				archive[request.frame].remote.inputs.up = request.inputs.up;
				archive[request.frame].remote.inputs.down = request.inputs.down;
				#Roll back here
			
	unconfirmed_requests[current_frame] = \
	{
		"frame" : archive[current_frame].local.frame,
		"timestamp" : archive[current_frame].local.timestamp,
		"inputs" : archive[current_frame].local.inputs
	};
	for key in unconfirmed_requests:
		message_to_send.requests.append(unconfirmed_requests[key]);
	# Send requests and confirmations
	transscenic.connection.put_var(message_to_send);
	if current_frame == 60:
		print(archive[59].remote.inputs);
	current_frame += 1;
