extends RigidBody

# Constants
const INTERPOLATION = 25.0;

# Variables
var last_state = 0.0;
var current_pos = Vector3();
var current_velocity = Vector3();

func _ready():
	# Object type
	add_to_group("player");
	add_to_group("damageable");
	
	# Rigidbody params
	mode = RigidBody.MODE_CHARACTER;
	friction = 0.0;
	can_sleep = false;

func _physics_process(delta):
	last_state = min(last_state + delta, 5.0);
	
	if (global_transform.origin.distance_to(current_pos) > 5.0):
		global_transform.origin = current_pos;
	if (last_state < 0.5):
		linear_velocity = (current_pos - global_transform.origin) * INTERPOLATION;

func set_state(pos, rot):
	var last_pos = current_pos;
	current_velocity = pos - last_pos;
	
	current_pos = pos;
	$body.rotation_degrees.y = rot[1];
	
	last_state = 0.0;

func give_damage(dmg):
	print(get_name(), " dmg: ", dmg);
