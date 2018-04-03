extends Camera

export (NodePath) var Controller;
export var bob_speed = 1.2;
export var bob_factor = 0.1;
export var min_weight = 1.2;

var camera_height = 0.0;
var bob_cycle = 0.0;

func _ready():
	# Get controller
	if (Controller && typeof(Controller) == TYPE_NODE_PATH):
		Controller = get_node(Controller);
	
	# Get camera default height
	camera_height = transform.origin.y;

func _process(delta):
	if (!Controller):
		return;
	
	# Get horizontal velocity from controller
	var hv = Controller.linear_velocity;
	hv.y = 0.0;
	
	# Calculate bob weight
	var bob_weight = min((hv.length()/Controller.MoveSpeed), 10.0);
	
	# Cycle bob angle
	if (bob_weight >= min_weight):
		bob_cycle = fmod(bob_cycle + 360 * delta * bob_weight * bob_speed, 360.0);
	else:
		bob_cycle = 0.0;
	
	var factor = bob_factor * bob_weight;
	var cam_transform = Vector3(0, camera_height, 0);
	cam_transform -= transform.basis.x * sin(deg2rad(bob_cycle)) * factor;
	cam_transform += transform.basis.y * abs(cos(deg2rad(bob_cycle))) * factor;
	
	# Set camera transform
	transform.origin = transform.origin.linear_interpolate(cam_transform, 8 * delta);
