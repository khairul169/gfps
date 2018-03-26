extends Spatial

# Configuration
var BobSpeed = 1.5;
var BobFactor = 0.008;
var BobSprintingMultiplier = 3.0;
var BobAngle = 1.0;
var SwayFactor = 0.002;
var SwayLimit = 0.015;
var CameraShift = 0.02;
var OnAirFactor = 0.02;
var Interpolation = 8.0;

############################ DO NOT EDIT BELOW ###############################

# Nodes
var PlayerController;

# Variables
var mBobbing = false;
var mCycle = 0.0;
var mPlayerHVel = Vector3();
var mViewSway = Vector3();
var mCustomScale = 1.0;
var mShiftingEnabled = true;

func _ready():
	if (PlayerController != null):
		PlayerController.connect("camera_motion", self, "OnCameraMotion");

func _process(delta):
	if (!PlayerController || !mBobbing):
		return;
	
	var mCycleSpeed = min((mPlayerHVel.length()/PlayerController.MoveSpeed) * BobSpeed, 10.0);
	mCycle = fmod(mCycle + 360 * delta * mCycleSpeed, 360.0);

func _physics_process(delta):
	if (!PlayerController):
		return;
	
	# Translation vector
	var mViewTranslation = Vector3();
	var mViewRotation = Vector3();
	
	# Player horizontal movement
	mPlayerHVel = PlayerController.linear_velocity;
	mPlayerHVel.y = 0.0;
	
	if (mPlayerHVel.length() > 0.1 && !PlayerController.mClimbing):
		mBobbing = true;
	else:
		if (mCycle > 0.0):
			mCycle = 0.0;
		mBobbing = false;
	
	var mFactor = BobFactor * mCustomScale;
	
	if (PlayerController.mSprinting):
		mFactor *= BobSprintingMultiplier;
	
	# Shift weapon position
	if (mShiftingEnabled):
		mViewTranslation.y += sin(deg2rad(-PlayerController.mCameraRotation.x)) * CameraShift;
	
	# Weapon y-pos when jumping
	if (mShiftingEnabled && !PlayerController.mClimbing):
		if (PlayerController.linear_velocity.y > 0.5):
			mViewTranslation.y += OnAirFactor;
		
		if (PlayerController.linear_velocity.y < -0.5):
			mViewTranslation.y -= OnAirFactor;
	
	if (mBobbing):
		mViewTranslation.x += sin(deg2rad(mCycle)) * mFactor;
		mViewTranslation.y += abs(cos(deg2rad(mCycle))) * mFactor - mFactor;
		
		mViewRotation.y += cos(deg2rad(mCycle)) * BobAngle;
		mViewRotation.z += sin(deg2rad(mCycle)) * -BobAngle;
	
	if (mViewSway.length() > 0.0):
		mViewTranslation += mViewSway * mCustomScale;
		mViewSway = mViewSway.linear_interpolate(Vector3(), Interpolation * delta);
	
	translation = translation.linear_interpolate(mViewTranslation, Interpolation * delta);
	rotation_degrees = rotation_degrees.linear_interpolate(mViewRotation, Interpolation * delta);

func OnCameraMotion(rel):
	mViewSway.x = clamp(mViewSway.x - rel.x * SwayFactor, -SwayLimit, SwayLimit);
	mViewSway.y = clamp(mViewSway.y + rel.y * SwayFactor, -SwayLimit, SwayLimit);

func SetCustomScale(scale):
	mCustomScale = scale;

func SetShiftingEnabled(enabled):
	mShiftingEnabled = enabled;
