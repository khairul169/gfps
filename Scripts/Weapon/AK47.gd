extends "Base/BaseWeapon.gd"

func _init():
	# Weapon name
	mName = "AK47";
	
	# Resources
	mWeaponModel = "res://Models/Weapon/AK47/Weapon.scn";
	mAudioShoot1 = "res://Sounds/Weapon/gun_rifle_01.wav";
	
	# Weapon stats
	mClip = 30;
	mAmmo = 90;
	mFiringMode = MODE_AUTO;
	
	mRecoil = Vector2(1.5, 2.0);
	mSpread = Vector2(1.8, 8.0);
	
	mFireDelay = 1.0/10.0;
	mFireRange = 100.0;
	mMoveSpeed = 0.9;
	
	mReloadTime = 2.4;
	mMuzzleSize = 1.0;
	
	mCanAim = true;
	mAimFOV = 45.0;
	mAimStatsMultiplier = 0.4;
	mScopeRenderFOV = 10.0;
