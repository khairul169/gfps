extends "base_weapon.gd"

# Resources
var mMissileObject = "";
var mMissileImpact = "";

# Stats
var mVelocity = 0.0;
var mImpulse = Vector3(0, 1.0, -10.0);
var mExplosionRange = 5.0;
var mExplosionForce = 4.0;

###########################################################

func _init():
	# Weapon name
	mName = "base_projectile";
	
	# Weapon stats
	mClip = 1;
	mAmmo = 100;
	mFiringMode = MODE_AUTO;
	
	mRecoil = Vector2(1.0, 7.5);
	mFireDelay = 0.2;
	mReloadTime = 1.0;
	
	mCanAim = true;
	mAimFOV = 40.0;
	mAimStatsMultiplier = 0.4;

func Registered():
	.Registered();
	
	# Load resources
	mMissileObject = LoadResource(mMissileObject);
	mMissileImpact = LoadResource(mMissileImpact);
	
	# Set animation name
	mAnimation['shoot'][1] = 'shoot';

###########################################################

func Think(delta):
	if (PlayerWeapon.mNextThink > 0.0):
		return;
	
	if (PlayerWeapon.mClip <= 0):
		mAnimation['idle'] = 'idle_empty';
		mAnimation['sprint'][1] = 'sprinting_e';
	else:
		mAnimation['idle'] = 'idle';
		mAnimation['sprint'][1] = 'sprinting';
	
	.Think(delta);

func Draw():
	if (PlayerWeapon.mClip <= 0):
		mAnimation['draw'] = 'draw_empty';
	else:
		mAnimation['draw'] = 'draw';
	.Draw();

func PrimaryAttack():
	if (!.PrimaryAttack(false)):
		return false;
	
	# Launch the missile
	CreateProjectile();
	return true;

func SprintToggled(sprinting):
	.SprintToggled(sprinting);
	
	if (PlayerWeapon.mClip > 0):
		return;
	
	if (sprinting):
		PlayerWeapon.PlayAnimation('pre_sprint_e');
	else:
		PlayerWeapon.PlayAnimation('post_sprint_e');

###########################################################

func CreateProjectile():
	if (!mMissileObject || !PlayerWeapon.Controller):
		return;
	var projectile = mMissileObject.instance();
	if (!projectile is RigidBody):
		return;
	
	# Set missile transform
	projectile.global_transform = PlayerWeapon.GetCameraTransform();
	
	# Configure missile
	projectile.add_collision_exception_with(PlayerWeapon.Controller);
	projectile.contact_monitor = true;
	projectile.contacts_reported = 1;
	projectile.connect("body_entered", self, "OnProjectileColliding", [projectile]);
	
	# Add object to the world
	PlayerWeapon.AddToWorld(projectile);
	
	# Set forward velocity
	if (mVelocity > 0.0):
		projectile.linear_velocity = -projectile.global_transform.basis.z * mVelocity;
		projectile.gravity_scale = 0.0;
	
	# Rigid impulse
	if (mImpulse.length() > 0.0):
		projectile.apply_impulse(Vector3(), projectile.global_transform.xform(mImpulse) - projectile.global_transform.origin);

func OnProjectileColliding(body, projectile):
	if (!body || !projectile || !projectile.is_inside_tree()):
		return;
	
	if (mMissileImpact):
		# Create explosion particles
		var explosion = mMissileImpact.instance();
		PlayerWeapon.AddToWorld(explosion);
		
		# Set missile transform
		explosion.global_transform.origin = projectile.global_transform.origin;
	
	# Give damage & push object in area
	for i in projectile.get_tree().get_nodes_in_group("damageable"):
		if (i.global_transform.origin.distance_to(projectile.global_transform.origin) > mExplosionRange):
			continue;
		if (i.has_method("GiveDamage")):
			i.GiveDamage(10.0);
	
	for i in projectile.get_tree().get_nodes_in_group("physics"):
		PushRigidBody(i, projectile.global_transform.origin);
	
	# Remove projectile from world
	projectile.queue_free();

func PushRigidBody(body, position):
	if (!body || !body.is_inside_tree() || !body is RigidBody):
		return;
	
	var dir = body.global_transform.origin - position;
	if (dir.length() > mExplosionRange):
		return;
	
	var impulse = dir.normalized() * clamp(1.0 - (dir.length()/mExplosionRange), 0.0, 1.0);
	
	# Push body!
	body.apply_impulse(Vector3(), impulse * mExplosionForce);
