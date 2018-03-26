extends Spatial

# Variables
var mNetworkMgr;

func _ready():
	if (has_node("/root/network_mgr")):
		mNetworkMgr = get_node("/root/network_mgr");

func _input(event):
	if (event is InputEventKey):
		# Host a game
		if (event.scancode == KEY_F2 && mNetworkMgr):
			mNetworkMgr.CreateServer(26444, 32);
		
		# Connect to local hosted network
		if (event.scancode == KEY_F3 && mNetworkMgr):
			mNetworkMgr.ConnectTo("127.0.0.1", 26444);
		
		# Toggle mouse mode
		if (event.scancode == KEY_CONTROL && event.pressed):
			if (Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED):
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
