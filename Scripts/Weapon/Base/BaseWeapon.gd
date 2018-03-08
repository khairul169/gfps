extends Reference

# Nodes
var PlayerWeapon;

# Constants
const MODE_AUTO = 0;
const MODE_SINGLE = 1;

# Variables
var mId = -1;
var mName = "BaseWeapon";

# Resources
var mWeaponModel = "";
var mAudioShoot1 = "";

var mMuzzleNode;
var mShellEjectNode;

# Weapon configuration
var mClip = 12;
var mAmmo = 48;
var mFiringMode = MODE_AUTO;

var mRecoil = Vector2(0.0, 0.0);
var mSpread = Vector2(0.0, 0.0);
var mFireDelay = 1.0/1.0;
var mFireRange = 1.0;
var mMoveSpeed = 1.0;
var mReloadTime = 1.0;
var mMuzzleSize = 1.0;

var mCanAim = false;
var mAimFOV = 0.0;
var mAimStatsMultiplier = 1.0;
var mAimMoveSpeed = 0.65;
var mAimBobScale = 0.4;
var mScopeRenderFOV = 10.0;

# State
var mIsAiming = false;
var mHasAttack = false;
var mNextAttack2 = 0.0;

# Animation
var mAnimation = {
	'idle' : 'idle',
	'draw' : 'draw',
	'reload' : 'reload',
	
	'sprint' : [
		'pre_sprint',
		'sprinting',
		'post_sprint'
	],
	
	'aiming' : [
		'pre_aim',
		'aiming',
		'post_aim',
	],
	
	'shoot' : [
		'shoot',
		'shoot_aim'
	]
};

#####################################################################

func Registered():
	# Load resources
	mWeaponModel = LoadResource(mWeaponModel);
	mAudioShoot1 = LoadResource(mAudioShoot1);
	
	if (mWeaponModel):
		mWeaponModel = mWeaponModel.instance();

func Draw():
	# Weapon draw
	PlayerWeapon.SetWeaponModel(mWeaponModel);
	PlayerWeapon.PlayAnimation(mAnimation['draw'], false, 0.0);
	PlayerWeapon.mNextThink = 0.5;
	PlayerWeapon.mNextIdle = 1.0;

func Holster():
	# Un-Aim weapon
	ToggleAim(false);
	
	PlayerWeapon.SetWeaponModel(null);

#####################################################################

func Think(delta):
	if (mNextAttack2 > 0.0):
		mNextAttack2 = max(mNextAttack2 - delta, 0.0);
	
	if (PlayerWeapon.mNextThink > 0.0):
		return;
	
	# Idle animation
	var mIdleAnims = mAnimation['idle'];
	
	# Aiming anims
	if (mIsAiming):
		mIdleAnims = mAnimation['aiming'][1];
	
	if (PlayerWeapon.mSprinting):
		mIdleAnims = mAnimation['sprint'][1];
	
	# Play idle animation
	if (PlayerWeapon.mNextIdle <= 0.0):
		PlayerWeapon.PlayAnimation(mIdleAnims, true, -1, false);
		
		# Set next animation check
		PlayerWeapon.mNextIdle = 0.1;
	
	# Reset single attack
	if (mHasAttack && !PlayerWeapon.mIsFiring):
		mHasAttack = false;
	
	# Auto reload
	if (PlayerWeapon.mClip <= 0 && PlayerWeapon.mAmmo > 0 && PlayerWeapon.mNextThink <= 0.0  && !PlayerWeapon.mIsReloading):
		PlayerWeapon.Reload();

func PrimaryAttack(shoot_bullet = true):
	if (mFiringMode == MODE_SINGLE && mHasAttack):
		return false;
	
	# Play animation
	if (mCanAim && mIsAiming):
		PlayerWeapon.PlayAnimation(mAnimation['shoot'][1], false, 0.0);
	else:
		PlayerWeapon.PlayAnimation(mAnimation['shoot'][0], false, 0.0);
	
	# Play sound
	if (mAudioShoot1 != null):
		PlayerWeapon.PlayAudioStream(mAudioShoot1);
	
	# Shoot a bullet
	if (shoot_bullet):
		PlayerWeapon.ShootBullet(mFireRange);
	
	# Set state
	mHasAttack = true;
	return true;

func SecondaryAttack():
	if (!mCanAim ||  mNextAttack2 > 0.0 || PlayerWeapon.mIsReloading || PlayerWeapon.mSprinting):
		return;
	
	ToggleAim(!mIsAiming);
	mNextAttack2 = 0.5;

func Reload():
	# Un-Aim weapon
	ToggleAim(false);
	
	# Play animation
	PlayerWeapon.PlayAnimation(mAnimation['reload']);
	return true;

func PostReload():
	pass

##########################################################################

func LoadResource(res):
	if (typeof(res) != TYPE_STRING || res == ""):
		return null;
	if (!Directory.new().file_exists(res)):
		print("Resource not found: ", res);
		return null;
	return load(res);

func ToggleAim(toggle):
	if (toggle == mIsAiming):
		return;
	
	if (toggle):
		PlayerWeapon.SetCameraFOV(mAimFOV);
		PlayerWeapon.SetCameraBobScale(mAimBobScale);
		PlayerWeapon.SetCameraShifting(false);
		PlayerWeapon.ToggleWeaponLens(true, mScopeRenderFOV);
		PlayerWeapon.PlayAnimation(mAnimation['aiming'][0]);
		mIsAiming = true;
	else:
		PlayerWeapon.SetCameraFOV(null);
		PlayerWeapon.SetCameraBobScale(null);
		PlayerWeapon.SetCameraShifting(true);
		PlayerWeapon.ToggleWeaponLens(false);
		PlayerWeapon.PlayAnimation(mAnimation['aiming'][2]);
		mIsAiming = false;
	
	# Set stats value with multiplier modifier
	ReloadStats();

func SprintToggled(sprinting):
	# Un-Aim weapon
	ToggleAim(false);
	
	if (sprinting):
		PlayerWeapon.PlayAnimation(mAnimation['sprint'][0]);
	else:
		PlayerWeapon.PlayAnimation(mAnimation['sprint'][2]);

func ReloadStats():
	var multiplier = 1.0;
	if (mIsAiming):
		multiplier = mAimStatsMultiplier;
	
	# Set new stats
	PlayerWeapon.mRecoil = mRecoil * multiplier;
	PlayerWeapon.mInitialSpread = mSpread.x * multiplier;
	PlayerWeapon.mMaxSpread = mSpread.y * multiplier;
	
	if (mIsAiming):
		PlayerWeapon.mMoveSpeed = mMoveSpeed * mAimMoveSpeed;
	else:
		PlayerWeapon.mMoveSpeed = mMoveSpeed;
