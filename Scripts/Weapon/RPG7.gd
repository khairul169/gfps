extends "Base/Projectile.gd"

func _init():
	# Weapon name
	mName = "Launcher";
	
	# Resources
	mWeaponModel = "res://Models/Weapon/RPG7/Weapon.scn";
	mAudioShoot1 = "res://Sounds/Weapon/rpg7-shoot.wav";
	
	# Missile
	mMissileObject = "res://Models/Weapon/RPG7/Rocket.scn";
	mMissileImpact = "res://Scenes/Weapon/Explosion.tscn";
	
	# Weapon stats
	mClip = 1;
	mAmmo = 2;
	
	mRecoil = Vector2(1.0, 8.0);
	mFireDelay = 0.2;
	mMoveSpeed = 1.0;
	mReloadTime = 2.3;
	
	mCanAim = true;
	mAimFOV = 40.0;
	
	# Rocket launcher
	mVelocity = 10.0;
	mImpulse = Vector3(0, 0, 0);
	mExplosionRange = 5.0;
	mExplosionForce = 8.0;
