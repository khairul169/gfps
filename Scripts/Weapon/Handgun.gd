extends "Base/BaseWeapon.gd"

func _init():
	# Weapon name
	mName = "Handgun";
	
	# Resources
	mWeaponModel = "res://Models/Weapon/Handgun/Weapon.scn";
	mAudioShoot1 = "res://Sounds/Weapon/gun_shot_01.wav";
	
	# Weapon stats
	mClip = 20;
	mAmmo = 120;
	mFiringMode = MODE_SINGLE;
	
	mRecoil = Vector2(1.2, 1.5);
	mSpread = Vector2(0.4, 0.9);
	
	mFireDelay = 1.0/10.0;
	mFireRange = 20.0;
	mMoveSpeed = 1.0;
	
	mReloadTime = 2.0;
	mMuzzleSize = 1.2;
	
	mCanAim = true;
	mAimFOV = 50.0;
	mAimStatsMultiplier = 0.4;
	mScopeRenderFOV = 0.0;
