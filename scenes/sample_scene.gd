extends Spatial

# Variables
var network;

func _ready():
	if (has_node("/root/network_mgr")):
		network = get_node("/root/network_mgr");

func _input(event):
	if (event is InputEventKey):
		# Toggle mouse mode
		if (event.scancode == KEY_CONTROL && event.pressed):
			toggle_mouse();
		
		# Host a game
		if (event.scancode == KEY_F2 && network):
			network.start_server(26444, 32);
		
		# Connect to local hosted network
		if (event.scancode == KEY_F3 && network):
			network.connect_to("127.0.0.1", 26444);

func toggle_mouse():
	if (Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
