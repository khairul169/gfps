extends Camera

export var enabled = true;
export (NodePath) var Controller;
export var bob_speed = 0.8;
export var bob_factor = 0.01;
export var min_weight = 1.2;
export var interpolation = 4.0;

var bob_cycle = 0.0;
var cam_translation = Vector3();

func _ready():
	# Get controller
	if (Controller && typeof(Controller) == TYPE_NODE_PATH):
		Controller = get_node(Controller);

func _process(delta):
	if (!enabled || !Controller):
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
	var cam_transform = cam_translation;
	
	# Calculate bob vector
	cam_transform -= transform.basis.x * sin(deg2rad(bob_cycle)) * factor;
	cam_transform += transform.basis.y * abs(sin(deg2rad(bob_cycle))) * factor * 1.5;
	
	# Interpolate cam translation
	cam_translation = cam_translation.linear_interpolate(Vector3(), interpolation * delta);
	
	# Set camera transform
	transform.origin = transform.origin.linear_interpolate(cam_transform, interpolation * delta);

func set_camera_translation(vec): cam_translation = vec;

func set_camera_animation(anims):
	pass # TODO
