extends Node

# Exports
export (NodePath) var Controller;
export (AudioStream) var StepLeft;
export (AudioStream) var StepRight;
export var StepDelay = 0.32;
export (AudioStream) var JumpLanding;

# Nodes
var stream_player;

# Variables
var foot_step = 0;
var next_step = 0.0;
var last_velocity = 0.0;

func _ready():
	if (!StepLeft || !StepRight):
		return;
	
	# Get player controller
	if (typeof(Controller) == TYPE_NODE_PATH):
		Controller = get_node(Controller);
	
	if (!Controller):
		print("Player SoundFx: Controller not found!");
		return;
	else:
		# Reference this node to controller
		Controller.PlayerSounds = self;
	
	# Disable audio looping
	setup_sound(StepLeft);
	setup_sound(StepRight);
	setup_sound(JumpLanding);
	
	# Initialize stream player
	stream_player = AudioStreamPlayer3D.new();
	stream_player.name = "player";
	stream_player.stream = StepLeft;
	stream_player.max_distance = 20;
	Controller.add_child(stream_player);

func _process(delta):
	if (next_step > 0.0):
		next_step = max(next_step - delta, 0.0);

func _physics_process(delta):
	if (!Controller):
		return;
	
	if (next_step <= 0.0):
		footstep_fx();
	
	# Check for jump landing
	if (abs(Controller.linear_velocity.y) < 0.5 && last_velocity < -8.0):
		stream_player.stream = JumpLanding;
		stream_player.play();
		next_step = 0.4;
	
	# Set last velocity
	last_velocity = Controller.linear_velocity.y;

func footstep_fx():
	var velocity = Controller.linear_velocity;
	velocity.y = 0.0;
	if (velocity.length() < Controller.MoveSpeed/2.0):
		return;
	
	var speed = float(Controller.MoveSpeed)/velocity.length();
	next_step = StepDelay * speed;
	
	if (foot_step):
		stream_player.stream = StepRight;
		foot_step = 0;
	else:
		stream_player.stream = StepLeft;
		foot_step = 1;
	
	# Play the player
	stream_player.play();

func setup_sound(res):
	if (res is AudioStreamOGGVorbis):
		res.loop = false;
	if (res is AudioStreamSample):
		res.loop_mode = 0;
