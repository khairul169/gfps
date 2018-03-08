extends RigidBody

# Exports
export var MoveSpeed = 3.6;
export var SprintSpeed = 1.2;
export var WalkSpeed = 0.5;
export var Acceleration = 10.0;
export var JumpForce = 6.0;

export var CameraSensitivity = 0.2;
export var CameraFOV = 60.0;
export var CameraHeight = 1.2;

# Signals
signal camera_motion(dir);

# Nodes
var CameraNode;
var FloorRay;

# Sub Nodes
var PlayerSounds;
var PlayerWeapon;

# Variables
var mMoveDir = Vector3();
var mDefaultGravity = 0.0;

var mCameraRotation = Vector3();
var mCameraImpulse = Vector3();
var mCurCamImpulse = Vector3();
var mCameraFOV = 0.0;

var mIsJumping = false;
var mIsOnFloor = false;
var mSprinting = false;
var mIsMoving = false;
var mClimbing = false;

# Input
var mInput = {
	'forward' : false,
	'backward' : false,
	'left' : false,
	'right' : false,
	'jump' : false,
	'walk' : false,
	'sprint' : false,
};

# Character ability
var mCanSprinting = false;

func _ready():
	# Set groups
	add_to_group("player");
	add_to_group("damageable");
	
	# Create camera
	CameraNode = Camera.new();
	CameraNode.fov = CameraFOV;
	CameraNode.transform.origin.y = CameraHeight;
	add_child(CameraNode, true);
	
	# Set camera as current
	CameraNode.make_current();
	mCameraFOV = CameraFOV;
	
	# Set camera znear & zfar
	CameraNode.near = 0.01;
	CameraNode.far = 100.0;
	
	# Create floor raycaster
	FloorRay = RayCast.new();
	FloorRay.transform.origin.y = 0.3;
	FloorRay.cast_to = Vector3(0.0, -0.5, 0.0);
	FloorRay.enabled = true;
	add_child(FloorRay, true);
	
	# Set default arguments
	friction = 0.0;
	mode = MODE_CHARACTER;
	can_sleep = false;
	
	# Set gravity variable
	mDefaultGravity = gravity_scale;

func _enter_tree():
	# Capture mouse input
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);

func _exit_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);

func _input(event):
	if (event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED):
		RotateCamera(event.relative);

func _process(delta):
	# Update camera transform
	update_camera(delta);

func _integrate_forces(state):
	# Reset variable
	mMoveDir = Vector3();
	
	# Get camera basis
	var mCameraDir = Basis();
	if (CameraNode):
		mCameraDir = CameraNode.global_transform.basis;
	
	# Set move direction
	if (mInput['forward']):
		mMoveDir -= mCameraDir.z;
	if (mInput['backward']):
		mMoveDir += mCameraDir.z;
	if (mInput['left']):
		mMoveDir -= mCameraDir.x;
	if (mInput['right']):
		mMoveDir += mCameraDir.x;
	
	# Enable y-axis movement when climbing
	if (mClimbing):
		mMoveDir.y = sign(mMoveDir.y) * max(abs(mMoveDir.y), 0.8);
	else:
		mMoveDir.y = 0.0;
	
	# Calculate move vector
	mMoveDir = mMoveDir.normalized();
	mMoveDir = mMoveDir * MoveSpeed;
	
	# Check if player is colliding with an object
	if (FloorRay != null && !FloorRay.is_colliding()):
		mMoveDir = mMoveDir * 0.6;
		mIsOnFloor = false;
	else:
		mIsOnFloor = true;
	
	# Sprint
	if (mCanSprinting && mInput['sprint'] && mIsOnFloor && mMoveDir.dot(-mCameraDir[2]) > 0.2):
		if (!PlayerWeapon || (PlayerWeapon != null && PlayerWeapon.CanSprint())):
			mSprinting = true;
			mMoveDir = mMoveDir * SprintSpeed;
	else:
		mSprinting = false;
	
	# Walk
	if (mInput['walk'] && mIsOnFloor):
		mMoveDir = mMoveDir * WalkSpeed;
	
	# Weapon weight modifier
	if (PlayerWeapon != null):
		mMoveDir = mMoveDir * PlayerWeapon.mMoveSpeed;
	
	# Add world gravity
	if (!mClimbing):
		mMoveDir.y = state.linear_velocity.y;
	
	# New velocity value
	var newVelocity = state.linear_velocity.linear_interpolate(mMoveDir, Acceleration * state.step);
	
	if (mInput['jump']):
		if (!mIsJumping):
			mIsJumping = true;
			
			# Jump!
			if (FloorRay != null && FloorRay.is_colliding()):
				newVelocity.y = JumpForce;
	else:
		if (mIsJumping):
			mIsJumping = false;
	
	if (newVelocity.length() > 0.2):
		mIsMoving = true;
	else:
		mIsMoving = false;
	
	# Set new linear velocity
	state.linear_velocity = newVelocity;

func update_camera(delta):
	if (!CameraNode):
		return;
	
	# Camera FOV
	if (CameraNode && CameraNode.fov != mCameraFOV):
		CameraNode.fov = lerp(CameraNode.fov, mCameraFOV, 16 * delta);
	
	# Recoil system
	if (mCameraImpulse.length() > 0.0):
		mCurCamImpulse = mCurCamImpulse.linear_interpolate(mCameraImpulse, 24 * delta);
	
	if (mCameraImpulse.length() > 0.0):
		mCameraImpulse = mCameraImpulse.linear_interpolate(Vector3(), 5 * delta);
	
	var mLookDir = Vector3();
	var mCamRot = mCameraRotation;
	
	# Add camera impulse
	mCamRot.x += mCurCamImpulse.y;
	mCamRot.y += mCurCamImpulse.x;
	
	# Calculate eye direction
	mLookDir.x += sin(deg2rad(mCamRot.y)) * cos(deg2rad(mCamRot.x));
	mLookDir.y += sin(deg2rad(mCamRot.x));
	mLookDir.z += cos(deg2rad(mCamRot.y)) * cos(deg2rad(mCamRot.x));
	
	if (mLookDir.length() <= 0.0 || abs(mLookDir.y) >= 1.0):
		return;
	
	# Set camera transform
	CameraNode.transform = CameraNode.transform.looking_at(CameraNode.transform.origin + mLookDir.normalized(), Vector3(0, 1, 0));

#########################################################################

func OnLadder(state):
	mClimbing = state;
	
	if (mClimbing):
		gravity_scale = 0.0;
	else:
		gravity_scale = mDefaultGravity;

##########################################################################

func RotateCamera(rotation):
	var sensitivity = CameraSensitivity * (mCameraFOV/CameraFOV);
	mCameraRotation.x = clamp(mCameraRotation.x - rotation.y * sensitivity, -80.0, 80.0);
	mCameraRotation.y = fmod(mCameraRotation.y - rotation.x * sensitivity, 360.0);
	emit_signal("camera_motion", rotation * sensitivity);

func GetCameraTransform():
	if (is_inside_tree() && CameraNode):
		return CameraNode.global_transform;
	return Transform();
