extends "Base/Shotgun.gd"

func _init():
	# Weapon name
	mName = "XM1014";
	
	# Resources
	mWeaponModel = "res://Models/Weapon/XM1014/Weapon.scn";
	mAudioShoot1 = "res://Sounds/Weapon/xm1014-shoot.wav";
	
	# Weapon stats
	mClip = 8;
	mAmmo = 32;
	mFiringMode = MODE_AUTO;
	
	mRecoil = Vector2(2.2, 6.5);
	mSpread = Vector2(0.7, 2.0);
	
	mFireDelay = 0.4;
	mFireRange = 20.0;
	mMoveSpeed = 1.0;
	
	mReloadTime = 0.8;
	mMuzzleSize = 1.2;
	mCanAim = false;
	
	# Shotgun
	mBulletSpread = 8;
	mProgressiveReload = true;
