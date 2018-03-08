extends Node

# Exports
export (NodePath) var Controller;
export (AudioStream) var StepLeft;
export (AudioStream) var StepRight;
export var StepDelay = 0.32;
export (AudioStream) var JumpLanding;

# Nodes
var mStreamPlayer;

# Variables
var mStep = 0;
var mNextStep = 0.0;
var mLastVelocity = 0.0;

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
	SetupSound(StepLeft);
	SetupSound(StepRight);
	SetupSound(JumpLanding);
	
	# Initialize stream player
	mStreamPlayer = AudioStreamPlayer3D.new();
	mStreamPlayer.name = "player";
	mStreamPlayer.stream = StepLeft;
	mStreamPlayer.max_distance = 50;
	Controller.add_child(mStreamPlayer);

func _process(delta):
	if (mNextStep > 0.0):
		mNextStep = max(mNextStep - delta, 0.0);

func _physics_process(delta):
	if (!Controller):
		return;
	
	if (mNextStep <= 0.0):
		FootstepFx();
	
	# Check for jump landing
	if (abs(Controller.linear_velocity.y) < 0.5 && mLastVelocity < -8.0):
		mStreamPlayer.stream = JumpLanding;
		mStreamPlayer.play();
		mNextStep = 0.4;
	
	# Set last velocity
	mLastVelocity = Controller.linear_velocity.y;

func FootstepFx():
	var mVelocity = Controller.linear_velocity;
	mVelocity.y = 0.0;
	if (mVelocity.length() < Controller.MoveSpeed/2.0):
		return;
	
	var mSpeed = float(Controller.MoveSpeed)/mVelocity.length();
	mNextStep = StepDelay * mSpeed;
	
	if (mStep):
		mStreamPlayer.stream = StepRight;
		mStep = 0;
	else:
		mStreamPlayer.stream = StepLeft;
		mStep = 1;
	
	# Play the player
	mStreamPlayer.play();

func SetupSound(res):
	if (res is AudioStreamOGGVorbis):
		res.loop = false;
	if (res is AudioStreamSample):
		res.loop_mode = 0;
