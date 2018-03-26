extends "base_weapon.gd"

# Stats
var mBulletSpread = 8;
var mProgressiveReload = true;

# Variables
var mReloading = false;
var mFirstInsert = false;

###########################################################

func _init():
	# Weapon name
	mName = "base_shotgun";
	
	# Weapon stats
	mClip = 8;
	mAmmo = 32;
	mFiringMode = MODE_AUTO;
	
	mRecoil = Vector2(2.0, 4.5);
	mFireDelay = 1.0;
	mReloadTime = 1.0;
	mCanAim = false;

###########################################################

func Think(delta):
	.Think(delta);
	
	if (!mReloading || PlayerWeapon.mNextThink > 0.0):
		return;
	
	if (mFirstInsert):
		mFirstInsert = false;
	else:
		PlayerWeapon.AddWeaponClip(1);
		PlayerWeapon.emit_signal("weapon_reload");
	
	if (PlayerWeapon.mClip >= mClip || PlayerWeapon.mAmmo <= 0):
		CancelReload();
		return;
	
	PlayerWeapon.PlayAnimation("reload");
	PlayerWeapon.mNextThink = mReloadTime;
	PlayerWeapon.mNextIdle = PlayerWeapon.mNextThink + 0.5;

func Draw():
	.Draw();
	
	mReloading = false;

func PrimaryAttack():
	if (mReloading || !.PrimaryAttack(false)):
		return false;
	
	# Spread bullet
	for i in range(0, mBulletSpread):
		PlayerWeapon.ShootBullet(mFireRange);
	return true;

func Reload():
	if (mReloading):
		return false;
	
	if (!mProgressiveReload && .Reload()):
		return true;
	
	if (PlayerWeapon.mClip >= mClip || PlayerWeapon.mAmmo <= 0):
		return false;
	
	mReloading = true;
	mFirstInsert = true;
	
	PlayerWeapon.PlayAnimation("pre_reload");
	PlayerWeapon.mNextThink = 0.4;
	PlayerWeapon.mNextIdle = PlayerWeapon.mNextThink + 0.1;
	return false;

func CancelReload():
	if (!mReloading):
		return;
	
	PlayerWeapon.PlayAnimation("post_reload");
	PlayerWeapon.mNextThink = 0.4;
	mReloading = false;

func SprintToggled(sprinting):
	# Stop reload
	CancelReload();
	PlayerWeapon.mNextThink = 0.0;
	PlayerWeapon.mNextIdle = 0.0;
	.SprintToggled(sprinting);
