extends Node

# Constants
const NETWORK_UPDATERATE = 1.0/40.0;

# Scenes
onready var scene_networkplayer = load("res://scenes/player/network_player.tscn");

# Network variables
var network_peer;
var network_server = false;
var network_client = false;

# Local player variables
var player_node;
var player_transform = [
	Vector3(), # Position
	[0.0, 0.0] # Rotation
];

func _ready():
	# Networking signals
	get_tree().connect("network_peer_connected", self, "_player_connected");
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected");
	get_tree().connect("connected_to_server", self, "_connected_ok");
	get_tree().connect("connection_failed", self, "_connected_fail");
	get_tree().connect("server_disconnected", self, "_server_disconnected");

func _physics_process(delta):
	process_server(delta);
	process_client(delta);

############################## SERVER ##############################

# Player data
var player_list = {};

# Signals
signal server_hosted();

# Variables
var next_broadcast = 0.0;

# Player class
class Player extends Reference:
	# Constants
	enum State {
		WAITING,
		CONNECTED
	};
	
	# Variables
	var id = -1;
	var connected = false;
	var name = "";
	var pos = Vector3();
	var rot = [0.0, 0.0];
	
	func _init(id = -1):
		self.id = id;
	
	func connected():
		print("Player ", id, " connected.");
	
	func ready():
		print("Player ", id, " ready.");
	
	func disconnected():
		print("Player ", id, " disconnected.");

#############################################################

func _player_connected(id):
	if (!player_list.has(id)):
		player_list[id] = Player.new(id);
		player_list[id].connected();

func _player_disconnected(id):
	if (player_list.has(id)):
		player_list[id].disconnected();
		player_list.erase(id);
		
		# Remove scene from all players
		rpc("player_remove", id);

func start_server(port, maxplayers):
	if (network_peer):
		return;
	
	network_peer = NetworkedMultiplayerENet.new();
	network_peer.create_server(port, maxplayers);
	get_tree().set_network_peer(network_peer);
	print("Server created. Port: ", port);
	
	# Set network type
	network_server = true;
	emit_signal("server_hosted");

remote func player_join(id):
	if (!network_server || !player_list.has(id)):
		return;
	
	for i in player_list:
		if (i != id):
			rpc_id(id, "player_create", i);
	
	if (player_list[id].connected == false):
		player_list[id].connected = true;
		player_list[id].ready();

func create_local_player():
	player_list[1] = Player.new(1);
	player_list[1].connected();
	player_join(1);
	
	# Enable client side
	client_player_id = 1;
	network_client = true;

func process_server(delta):
	if (!network_server):
		return;
	
	next_broadcast = max(next_broadcast - delta, 0.0);
	if (next_broadcast > 0.0):
		return;
	
	# Broadcast player transform
	for id in player_list:
		# Player is not ready
		if (!player_list[id].connected):
			continue;
		
		# Send to all players
		rpc("set_player_transform", id, [
			player_list[id].pos,
			player_list[id].rot
		]);
	
	next_broadcast = NETWORK_UPDATERATE;

############################## CLIENT ##############################

# Variables
var client_player_id = -1;
var player_nodes = {};

func connect_to(ip, port):
	if (network_peer):
		return;
	
	network_peer = NetworkedMultiplayerENet.new();
	network_peer.create_client(ip, port);
	get_tree().set_network_peer(network_peer);
	print("Connecting to ", ip, ":", port, "...");

func _connected_ok():
	if (!network_peer):
		return;
	
	# Get player id
	client_player_id = get_tree().get_network_unique_id();
	
	# Tell server that we are ready
	rpc("player_join", client_player_id);
	
	# Set as client
	network_client = true;

func _server_disconnected():
	# Server kicked us, show error and abort
	print("Disconnected.");
	
	# Remove all slave players
	for i in player_nodes.keys():
		player_remove(i);
	
	# Disconnect from server
	player_disconnect();

func _connected_fail():
    pass # Could not even connect to server, abort

func process_client(delta):
	if (!network_client):
		return;
	
	if (network_server):
		# Local player transform
		set_player_transform(1, player_transform);
	else:
		# Send player current state to server
		rpc_id(1, "set_player_transform", client_player_id, player_transform);

func player_disconnect():
	# Disable networking
	network_peer = null;
	network_client = false;
	get_tree().set_network_peer(null);

###################################################################

remote func set_player_transform(id, transform):
	if (network_server && player_list.has(id) && player_list[id].connected):
		# Set player state
		player_list[id].pos = transform[0];
		player_list[id].rot = transform[1];
	
	if (network_client && id != client_player_id):
		if (!player_nodes.has(id)):
			# Player is not exist, create player
			player_create(id);
		
		# Set player transform
		if (player_nodes[id].has_method("set_state")):
			player_nodes[id].set_state(transform[0], transform[1]);

sync func player_create(id):
	if (!player_node || player_nodes.has(id)):
		return;
	
	# Instance slave player
	var instance = scene_networkplayer.instance();
	instance.name = str(id);
	
	player_node.get_parent().add_child(instance);
	player_nodes[id] = instance;

sync func player_remove(id):
	if (!network_client):
		return;
	
	if (player_nodes.has(id)):
		player_nodes[id].queue_free();
		player_nodes.erase(id);
