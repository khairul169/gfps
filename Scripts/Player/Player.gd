extends RigidBody

# Constants
const INTERPOLATION = 25.0;

# Variables
var mLastState = 0.0;
var mCurrPos = Vector3();
var mVelocity = Vector3();

func _ready():
	# Object type
	add_to_group("player");
	add_to_group("damageable");
	
	# Rigidbody params
	mode = RigidBody.MODE_CHARACTER;
	friction = 0.0;
	can_sleep = false;

func _physics_process(delta):
	mLastState = min(mLastState + delta, 5.0);
	
	if (global_transform.origin.distance_to(mCurrPos) > 5.0):
		global_transform.origin = mCurrPos;
	if (mLastState < 0.5):
		linear_velocity = (mCurrPos - global_transform.origin) * INTERPOLATION;

func SetState(pos, rot):
	var mLastPos = mCurrPos;
	mVelocity = pos - mLastPos;
	
	mCurrPos = pos;
	$Body.rotation_degrees.y = rot[1];
	
	mLastState = 0.0;

func GiveDamage(dmg):
	print(get_name(), " dmg: ", dmg);
