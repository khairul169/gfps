extends Node

# Constants
const NETWORK_UPDATERATE = 1.0/40.0;

# Scenes
onready var PlayerSlave = load("res://Scenes/Player/Player.tscn");

# Network variables
var mNetworkPeer;
var mServer = false;
var mClient = false;

# Local player variables
var mPlayerNode;
var mPlayerTransform = [
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
	ServerThink(delta);
	ClientThink(delta);

############################## SERVER ##############################

# Player data
var mPlayerList = {};

# Signals
signal server_hosted();

# Variables
var mNextBroadcast = 0.0;

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
	if (!mPlayerList.has(id)):
		mPlayerList[id] = Player.new(id);
		mPlayerList[id].connected();

func _player_disconnected(id):
	if (mPlayerList.has(id)):
		mPlayerList[id].disconnected();
		mPlayerList.erase(id);
		
		# Remove scene from all players
		rpc("RemovePlayer", id);

func CreateServer(port, maxplayers):
	if (mNetworkPeer):
		return;
	
	mNetworkPeer = NetworkedMultiplayerENet.new();
	mNetworkPeer.create_server(port, maxplayers);
	get_tree().set_network_peer(mNetworkPeer);
	print("Server created. Port: ", port);
	
	# Set network type
	mServer = true;
	emit_signal("server_hosted");

remote func PlayerJoin(id):
	if (!mServer || !mPlayerList.has(id)):
		return;
	
	for i in mPlayerList:
		if (i != id):
			rpc_id(id, "CreatePlayer", i);
	
	if (mPlayerList[id].connected == false):
		mPlayerList[id].connected = true;
		mPlayerList[id].ready();

func CreateLocalPlayer():
	mPlayerList[1] = Player.new(1);
	mPlayerList[1].connected();
	PlayerJoin(1);
	
	# Enable client side
	mPlayerId = 1;
	mClient = true;

func ServerThink(delta):
	if (!mServer):
		return;
	
	mNextBroadcast = max(mNextBroadcast - delta, 0.0);
	if (mNextBroadcast > 0.0):
		return;
	
	# Broadcast player transform
	for id in mPlayerList:
		# Player is not ready
		if (!mPlayerList[id].connected):
			continue;
		
		# Send to all players
		rpc("PlayerTransform", id, [
			mPlayerList[id].pos,
			mPlayerList[id].rot
		]);
	
	mNextBroadcast = NETWORK_UPDATERATE;

############################## CLIENT ##############################

# Variables
var mPlayerId = -1;
var mPlayerNodes = {};

func ConnectTo(ip, port):
	if (mNetworkPeer):
		return;
	
	mNetworkPeer = NetworkedMultiplayerENet.new();
	mNetworkPeer.create_client(ip, port);
	get_tree().set_network_peer(mNetworkPeer);
	print("Connecting to ", ip, ":", port, "...");

func _connected_ok():
	if (!mNetworkPeer):
		return;
	
	# Get player id
	mPlayerId = get_tree().get_network_unique_id();
	
	# Tell server that we are ready
	rpc("PlayerJoin", mPlayerId);
	
	# Set as client
	mClient = true;

func _server_disconnected():
	# Server kicked us, show error and abort
	print("Disconnected.");
	
	# Remove all slave players
	for i in mPlayerNodes.keys():
		RemovePlayer(i);
	
	# Disconnect from server
	Disconnect();

func _connected_fail():
    pass # Could not even connect to server, abort

func ClientThink(delta):
	if (!mClient):
		return;
	
	if (mServer):
		# Local player transform
		PlayerTransform(1, mPlayerTransform);
	else:
		# Send player current state to server
		rpc_id(1, "PlayerTransform", mPlayerId, mPlayerTransform);

func Disconnect():
	# Disable networking
	mNetworkPeer = null;
	mClient = false;
	get_tree().set_network_peer(null);

###################################################################

remote func PlayerTransform(id, transform):
	if (mServer && mPlayerList.has(id) && mPlayerList[id].connected):
		# Set player state
		mPlayerList[id].pos = transform[0];
		mPlayerList[id].rot = transform[1];
	
	if (mClient && id != mPlayerId):
		if (!mPlayerNodes.has(id)):
			# Player is not exist, create player
			CreatePlayer(id);
		
		# Set player transform
		if (mPlayerNodes[id].has_method("SetState")):
			mPlayerNodes[id].SetState(transform[0], transform[1]);

sync func CreatePlayer(id):
	if (!mPlayerNode || mPlayerNodes.has(id)):
		return;
	
	# Instance slave player
	var instance = PlayerSlave.instance();
	instance.name = str(id);
	
	mPlayerNode.get_parent().add_child(instance);
	mPlayerNodes[id] = instance;

sync func RemovePlayer(id):
	if (!mClient):
		return;
	
	if (mPlayerNodes.has(id)):
		mPlayerNodes[id].queue_free();
		mPlayerNodes.erase(id);
