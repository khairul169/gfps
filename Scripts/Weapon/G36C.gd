extends "Base/BaseWeapon.gd"

func _init():
	# Weapon name
	mName = "G36C";
	
	# Resources
	mWeaponModel = "res://Models/Weapon/G36C/Weapon.scn";
	mAudioShoot1 = "res://Sounds/Weapon/g36c-shoot.wav";
	
	# Weapon stats
	mClip = 35;
	mAmmo = 105;
	mFiringMode = MODE_AUTO;
	
	mRecoil = Vector2(1.4, 1.8);
	mSpread = Vector2(1.8, 6.0);
	
	mFireDelay = 1.0/9.0;
	mFireRange = 100.0;
	mMoveSpeed = 0.95;
	
	mReloadTime = 2.4;
	mMuzzleSize = 1.0;
	
	mCanAim = true;
	mAimFOV = 30.0;
	mAimStatsMultiplier = 0.4;
	mScopeRenderFOV = 10.0;
