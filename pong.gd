extends Node2D
var transscenic : Node;

# Called when the node enters the scene tree for the first time.
func _ready():
	RenderingServer.set_default_clear_color(Color(0,0,0))
	transscenic = $"/root/Transscenic_Variables";

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta):
	if transscenic.is_host:
		transscenic.server.poll();
		transscenic.connection.put_var("HOST");
		while transscenic.connection.get_available_packet_count() > 0:
			print(transscenic.connection.get_var());
		return;
		
	while transscenic.connection.get_available_packet_count() > 0:
		print(transscenic.connection.get_var());
	transscenic.connection.put_var("JOIN");
