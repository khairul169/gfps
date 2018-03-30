extends Node

# Exports
export (AudioStream) var StepLeft;
export (AudioStream) var StepRight;
export var StepDelay = 0.4;
export (AudioStream) var JumpLanding;

# Nodes
var controller;
var stream_player;

# Variables
var foot_step = 0;
var next_step = 0.0;
var last_velocity = 0.0;

func _ready():
	if (!StepLeft || !StepRight):
		return;
	
	# Get player controller
	controller = get_parent();
	controller.PlayerSounds = self;
	
	# Initialize stream player
	stream_player = AudioStreamPlayer3D.new();
	stream_player.name = "player_sfx";
	stream_player.stream = StepLeft;
	stream_player.max_distance = 20;
	controller.call_deferred("add_child", stream_player);

func _process(delta):
	if (next_step > 0.0):
		next_step = max(next_step - delta, 0.0);

func _physics_process(delta):
	if (!controller):
		return;
	
	if (next_step <= 0.0):
		footstep_fx();
	
	# Check for jump landing
	if (abs(controller.linear_velocity.y) < 0.5 && last_velocity < -8.0):
		stream_player.stream = JumpLanding;
		stream_player.play();
		next_step = 0.4;
	
	# Set last velocity
	last_velocity = controller.linear_velocity.y;

func footstep_fx():
	var velocity = controller.linear_velocity;
	velocity.y = 0.0;
	if (!controller.on_floor || velocity.length() < controller.MoveSpeed/2.0):
		return;
	
	var speed = float(controller.MoveSpeed)/velocity.length();
	next_step = StepDelay * speed;
	
	if (foot_step):
		stream_player.stream = StepRight;
		foot_step = 0;
	else:
		stream_player.stream = StepLeft;
		foot_step = 1;
	
	# Play the player
	stream_player.play();
