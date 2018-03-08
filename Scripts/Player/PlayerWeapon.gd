extends Node

# Exports
export (NodePath) var Controller;
export (Script) var WeaponView;
export var ModelScaling = 0.05;
export var EnableScopeRender = true;

# Prefabs
export (PackedScene) var MuzzleFlash;
export (PackedScene) var BulletShell;
export (PackedScene) var BulletImpact;

# Weapon attachment
const BONE_MUZZLEFLASH = "MuzzleFlash";
const BONE_BULLETEJECT = "BulletEject";

# Nodes
onready var WorldNode = get_parent().get_parent();

# Signals
signal weapon_draw();
signal weapon_unload();
signal weapon_attack1();
signal weapon_attack2();
signal weapon_reload();
signal object_hit(obj, pos);

# Nodes
var mWeaponView;
var mWeaponModel;
var mAnimationPlayer;
var mMuzzleFlash;
var mStreamPlayer;
var mScopeRender;

# Variables
var mIsFiring = false;
var mIsReloading = false;
var mNextThink = 0.0;
var mNextIdle = 0.0;
var mSprinting = false;
var mClip = 0;
var mSpread = 0.0;

# Custom weapon configuration
var mMaxClip = 0;
var mAmmo = 0;
var mInitialSpread = 0.5;
var mMaxSpread = 5.0;
var mRecoil = Vector2(1.2, 1.5);
var mReloadTime = 2.0;
var mFireDelay = 1.0/10.0;
var mMoveSpeed = 1.0;

# Input
var mInput = {
	'attack1' : false,
	'attack2' : false
};

# Registered weapon
var mWeaponList = [];
var mCurrentWpn = -1;

func _ready():
	# Get Nodes
	if (typeof(Controller) == TYPE_NODE_PATH):
		Controller = get_node(Controller);
		Controller.PlayerWeapon = self;
	
	# Create weapon view
	if (Controller.CameraNode):
		# Instance scene
		mWeaponView = Spatial.new();
		mWeaponView.name = "WeaponView";
		
		# Set script
		if (WeaponView is Script):
			mWeaponView.set_script(WeaponView);
			mWeaponView.PlayerController = Controller;
		
		# Add to camera node
		Controller.CameraNode.add_child(mWeaponView);
	
	# Create stream player
	if (Controller):
		mStreamPlayer = AudioStreamPlayer3D.new();
		mStreamPlayer.name = "StreamPlayer";
		mStreamPlayer.max_distance = 100.0;
		Controller.add_child(mStreamPlayer);
	
	# Instance prefabs
	if (MuzzleFlash):
		mMuzzleFlash = MuzzleFlash.instance();
	
	# Create scope lens viewport
	mScopeRender = Viewport.new();
	mScopeRender.name = "ScopeRender";
	mScopeRender.size = Vector2(1, 1) * 512.0;
	mScopeRender.render_target_v_flip = true;
	
	var mCamera = Camera.new();
	mCamera.fov = 10.0;
	mCamera.cull_mask = 1;
	mScopeRender.add_child(mCamera, true);
	add_child(mScopeRender);
	
	# Hack! Prevent game from freezing when instancing bullet impact
	if (BulletImpact):
		var impact = BulletImpact.instance();
		add_child(impact);

func _process(delta):
	if (mCurrentWpn < 0 || !Controller):
		return;
	
	if (mNextThink > 0.0):
		mNextThink = max(mNextThink - delta, 0.0);
	
	if (mNextIdle > 0.0):
		mNextIdle = max(mNextIdle - delta, 0.0);

func _physics_process(delta):
	if (mCurrentWpn < 0 || !Controller):
		return;
	
	# Player input
	mIsFiring = mInput['attack1'];
	
	# Weapon think
	Idle(delta);
	PrimaryAttack();
	SecondaryAttack();
	
	# Refill clip
	if (mIsReloading && mNextThink <= 0.0):
		PostReload();
	
	# Update scope lens camera transform
	if (mScopeRender.get_camera()):
		mScopeRender.get_camera().global_transform = GetCameraTransform();

##########################################################################

func CanSprint():
	return (!mIsFiring && !mIsReloading);

func Idle(delta):
	# Substract weapon spread
	if (!mIsFiring && mNextThink <= 0.0):
		mSpread = clamp(mSpread - ((mMaxSpread-mInitialSpread) * 0.2), mInitialSpread, mMaxSpread);
	
	if (Controller.mSprinting && !mSprinting && mNextThink <= 0.0):
		SprintToggled(true);
		mSprinting = true;
		mNextIdle = 0.4;
		mNextThink = mNextIdle;
	
	if (!Controller.mSprinting && mSprinting && mNextThink <= 0.0):
		SprintToggled(false);
		mSprinting = false;
		mNextIdle = 0.4;
		mNextThink = mNextIdle;
	
	if (mCurrentWpn > -1 && mCurrentWpn < mWeaponList.size()):
		mWeaponList[mCurrentWpn].Think(delta);

func PrimaryAttack():
	if (!mIsFiring || mNextThink > 0.0):
		return;
	
	# Cannot shoot while sprinting
	if (Controller.mSprinting || mSprinting):
		return;
	
	# Out of clip
	if (mClip <= 0):
		return;
	
	var attack = false;
	if (mCurrentWpn > -1 && mCurrentWpn < mWeaponList.size()):
		attack = mWeaponList[mCurrentWpn].PrimaryAttack();
	
	if (!attack):
		return;
	
	# Gun recoil
	CreateRecoil(mRecoil);
	
	# Muzzleflash
	if (mMuzzleFlash && mMuzzleFlash.scale.length() > 0.0):
		mMuzzleFlash.flash();
	
	# Eject bullet shell
	if (mWeaponList[mCurrentWpn].mShellEjectNode):
		CreateBulletShell(mWeaponList[mCurrentWpn].mShellEjectNode);
	
	# Reduce weapon clip
	mClip -= 1;
	
	# Firing delay
	mNextThink = mFireDelay;
	mNextIdle = mNextThink + 0.2;
	
	# Spread bullet
	mSpread = clamp(mSpread + ((mMaxSpread-mInitialSpread) * 0.1), mInitialSpread, mMaxSpread);
	
	# Emit attack signal
	emit_signal("weapon_attack1");

func SecondaryAttack():
	if (!mInput['attack2'] || Controller.mSprinting || mSprinting || mNextThink > 0.0):
		return;
	
	mNextThink = 0.1;
	
	if (mCurrentWpn > -1 && mCurrentWpn < mWeaponList.size()):
		mWeaponList[mCurrentWpn].SecondaryAttack();
		emit_signal("weapon_attack2");

func SprintToggled(sprinting):
	if (!Controller):
		return;
	if (mCurrentWpn > -1 && mCurrentWpn < mWeaponList.size()):
		mWeaponList[mCurrentWpn].SprintToggled(sprinting);

func Reload():
	if (mIsReloading || mNextThink > 0.0 || mAmmo <= 0.0 || mClip >= mMaxClip):
		return;
	
	if (Controller.mSprinting || mSprinting):
		return;
	
	var can_reload = true;
	if (mCurrentWpn > -1 && mCurrentWpn < mWeaponList.size()):
		can_reload = mWeaponList[mCurrentWpn].Reload();
	
	if (can_reload):
		# Start reload
		mIsReloading = true;
		mNextThink = mReloadTime;
		mNextIdle = mNextThink + 0.2;

func PostReload():
	if (mAmmo <= 0.0 || mClip >= mMaxClip):
		return;
	
	# Reload magazine clip
	var mClipFired = clamp(mMaxClip - mClip, 0, mMaxClip);
	mClip = min(mClip + mAmmo, mMaxClip);
	mAmmo = max(mAmmo - mClipFired, 0);
	
	# Set state
	mIsReloading = false;
	mNextThink = 0.1;
	
	if (mCurrentWpn > -1 && mCurrentWpn < mWeaponList.size()):
		mWeaponList[mCurrentWpn].PostReload();
		emit_signal("weapon_reload");

###########################################################################

func GetCameraTransform():
	if (Controller):
		return Controller.GetCameraTransform();
	else:
		return Transform();

func PlayAnimation(anim, loop = false, custom_blend = -1, immediately = true):
	if (!mAnimationPlayer):
		return;
	
	if (!immediately && mAnimationPlayer.current_animation == anim):
		return;
	
	if (mAnimationPlayer.has_animation(anim)):
		mAnimationPlayer.get_animation(anim).loop = loop;
		mAnimationPlayer.play(anim, custom_blend);

func CreateRecoil(recoil):
	# Recoil direction
	var mRecoilImpact = Vector3();
	mRecoilImpact.x = rand_range(-1.0, 1.0) * recoil.x;
	mRecoilImpact.y = rand_range(0.5, 1.0) * recoil.y;
	
	# Double the recoil when player is moving
	if (Controller.mIsMoving):
		mRecoilImpact *= 2.0;
	
	# And when climbing..
	if (Controller.mClimbing):
		mRecoilImpact *= 2.0;
	
	# Add camera impulse
	Controller.mCameraImpulse += mRecoilImpact;

func PlayAudioStream(stream):
	if (!mStreamPlayer || !stream || !stream is AudioStream):
		return;
	
	mStreamPlayer.stream = stream;
	mStreamPlayer.play();

func ShootBullet(distance):
	var mRayVector = Vector2();
	mRayVector.x += rand_range(-1.0, 1.0) * mSpread;
	mRayVector.y += rand_range(-1.0, 1.0) * mSpread;
	
	# Spread more when moving and climbing
	if (Controller.mIsMoving):
		mRayVector *= 2.0;
	
	if (Controller.mClimbing):
		mRayVector *= 2.0;
	
	# Cast a ray
	var mCamTransform = GetCameraTransform();
	var mFrom = mCamTransform.origin;
	var mDirection = mCamTransform.basis.xform(Vector3(mRayVector.x, mRayVector.y, -distance));
	var mResult = Controller.get_world().direct_space_state.intersect_ray(mFrom, mFrom + mDirection, [Controller]);
	
	# Ray hit an object
	if (!mResult.empty()):
		RayCheck(mResult, mDirection);
		return mResult;
	
	return null;

func RayCheck(result, direction):
	if (!result || typeof(result) != TYPE_DICTIONARY || result.empty()):
		return;
	
	# Instantiate bullet hole
	if (result.collider is StaticBody):
		CreateBulletImpact(result.position, result.normal, true);
	
	# Knock back rigidbody
	if (result.collider is RigidBody && result.collider.is_in_group("physics")):
		CreateBulletImpact(result.position, result.normal, false);
		
		# Apply body impulse
		var pos = result.position-result.collider.global_transform.origin;
		result.collider.apply_impulse(pos, direction.normalized() * 2.0);
	
	# Give damage to damageable object
	if (result.collider.is_in_group("damageable")):
		GiveObjectDamage(result.collider, 10.0, result.position);
	
	# Emit signal
	emit_signal("object_hit", result.collider, result.position);

func CreateBulletImpact(pos, normal, bullet_hole = true):
	if (!BulletImpact):
		return;
	
	# Instance prefabs
	var mInstance = BulletImpact.instance();
	mInstance.mBulletHole = bullet_hole;
	WorldNode.add_child(mInstance);
	
	# Set transform
	mInstance.look_at_from_position(pos + (normal.normalized() * 0.01), pos + normal + Vector3(1, 1, 1) * 0.001, Vector3(0, 1, 0));

func CreateBulletShell(node):
	if (!node || !node.is_inside_tree()):
		return;
	
	var shell = BulletShell.instance();
	shell.add_collision_exception_with(Controller);
	shell.global_transform = node.global_transform;
	shell.linear_velocity = -node.global_transform.basis.z.normalized() * 0.6;
	shell.linear_velocity.y = 0.4;
	WorldNode.add_child(shell);

func AttachMuzzleFlash(node, size = 0.0):
	if (!mMuzzleFlash):
		return;
	
	if (node):
		mMuzzleFlash.scale = Vector3(1, 1, 1) * size;
		node.add_child(mMuzzleFlash);
	else:
		if (mMuzzleFlash.get_parent()):
			mMuzzleFlash.get_parent().remove_child(mMuzzleFlash);

########################################################################

func RegisterWeapon(path):
	if (!Directory.new().file_exists(path)):
		return -1;
	
	# Load script
	var wpn = load(path).new();
	wpn.PlayerWeapon = self;
	mWeaponList.append(wpn);
	
	# Initialize weapon
	var id = (mWeaponList.size()-1);
	wpn.mId = id;
	wpn.Registered();
	
	# Models skeleton
	var mSkeleton = null;
	if (wpn.mWeaponModel):
		mSkeleton = wpn.mWeaponModel.find_node("Skeleton");
	
	# Set mesh layers
	for i in GetMeshInstances(wpn.mWeaponModel):
		i.layers = 2;
	
	# Initialize weapon attachment
	SetupAttachment(wpn, mSkeleton);
	return id;

func SetupAttachment(wpn, skeleton):
	if (!wpn || !skeleton):
		return;
	
	# Muzzleflash
	if (!MuzzleFlash || skeleton.find_bone(BONE_MUZZLEFLASH) < 0):
		return;
	
	# Attachment
	var attachment = BoneAttachment.new();
	attachment.name = "MuzzleFlash";
	attachment.bone_name = BONE_MUZZLEFLASH;
	skeleton.add_child(attachment);
	
	# Set muzzle flash attachment node
	wpn.mMuzzleNode = attachment;
	
	# Bullet shell eject
	if (!BulletShell || skeleton.find_bone(BONE_BULLETEJECT) < 0):
		return;
	
	# The attachment that we will use to instance the shell from
	attachment = BoneAttachment.new();
	attachment.name = "ShellEject";
	attachment.bone_name = BONE_BULLETEJECT;
	skeleton.add_child(attachment);
	
	# Set attachment node
	wpn.mShellEjectNode = attachment;

func SetWeaponModel(model):
	if (!mWeaponView):
		return;
	
	# Remove old model
	if (mWeaponModel != null):
		mWeaponView.remove_child(mWeaponModel);
		mWeaponModel = null;
	
	if (!model || !model is Spatial):
		return;
	
	# Set new model
	mWeaponModel = model;
	mWeaponModel.scale = Vector3(1, 1, 1) * ModelScaling;
	mWeaponView.add_child(mWeaponModel);
	
	# Find animation player
	if (mWeaponModel.has_node("AnimationPlayer")):
		mAnimationPlayer = mWeaponModel.get_node("AnimationPlayer");
		mAnimationPlayer.playback_default_blend_time = 0.1;

func UnloadCurrentWeapon():
	if (mCurrentWpn > -1 && mCurrentWpn < mWeaponList.size()):
		# Remove all attachments
		AttachMuzzleFlash(null);
		
		# Call weapon function
		mWeaponList[mCurrentWpn].Holster();
		emit_signal("weapon_unload");
	
	# Remove weapon
	mCurrentWpn = -1;

func SetActiveWeapon(id):
	# Cannot switch to current weapon. remove it first.
	if (mCurrentWpn == id):
		return;
	
	# Remove current weapon
	UnloadCurrentWeapon();
	
	# Id isn't valid
	if (id == null || id < 0 || id >= mWeaponList.size()):
		return;
	
	# Set current weapon id
	mCurrentWpn = id;
	
	# Set weapon configuration
	mMaxClip = mWeaponList[id].mClip;
	mInitialSpread = mWeaponList[id].mSpread.x;
	mMaxSpread = mWeaponList[id].mSpread.y;
	mRecoil = mWeaponList[id].mRecoil;
	mReloadTime = mWeaponList[id].mReloadTime;
	mFireDelay = mWeaponList[id].mFireDelay;
	mMoveSpeed = mWeaponList[id].mMoveSpeed;
	
	# Set weapon clip & ammo
	RefillWeapon();
	
	# Set weapon state
	mIsReloading = false;
	mIsFiring = false;
	mSprinting = false;
	
	# Attach muzzleflash
	if (mWeaponList[id].mMuzzleNode):
		AttachMuzzleFlash(mWeaponList[id].mMuzzleNode, mWeaponList[id].mMuzzleSize);
	
	# Call weapon draw function
	mWeaponList[id].Draw();
	emit_signal("weapon_draw");

func RefillWeapon():
	if (mCurrentWpn < 0 || mCurrentWpn >= mWeaponList.size()):
		return;
	
	mClip = mWeaponList[mCurrentWpn].mClip;
	mAmmo = mWeaponList[mCurrentWpn].mAmmo;

func SetWeaponAmmo(clip, ammo):
	if (mCurrentWpn < 0 || mCurrentWpn >= mWeaponList.size()):
		return;
	
	mClip = clamp(clip, 0, mMaxClip);
	mAmmo = clamp(ammo, 0, mWeaponList[mCurrentWpn].mAmmo);

func AddWeaponClip(amount):
	if (mCurrentWpn < 0 || mCurrentWpn >= mWeaponList.size()):
		return;
	
	mClip = clamp(mClip + amount, 0, mMaxClip);
	mAmmo = clamp(mAmmo - amount, 0, mWeaponList[mCurrentWpn].mAmmo);

func SetCameraFOV(fov):
	if (!Controller):
		return;
	
	if (fov != null && fov > 0):
		Controller.mCameraFOV = fov;
	else:
		Controller.mCameraFOV = Controller.CameraFOV;

func SetCameraBobScale(scale):
	if (!mWeaponView || !mWeaponView.has_method("SetCustomScale")):
		return;
	if (scale != null && scale > 0.0):
		mWeaponView.SetCustomScale(scale);
	else:
		mWeaponView.SetCustomScale(1.0);

func GetMeshInstances(node):
	if (!node || node.get_child_count() <= 0):
		return [];
	var meshes = [];
	for i in node.get_children():
		if (i is MeshInstance):
			meshes.append(i);
		for j in GetMeshInstances(i):
			meshes.append(j);
	return meshes;

func AddToWorld(node):
	if (!WorldNode || !node || !node is Node):
		return;
	WorldNode.add_child(node);

func SetCameraShifting(enabled):
	if (!mWeaponView || !mWeaponView.has_method("SetShiftingEnabled")):
		return;
	mWeaponView.SetShiftingEnabled(enabled);

func ToggleWeaponLens(toggle, fov = 60.0):
	if (!mWeaponModel || !mWeaponModel.has_method("SetLensTexture")):
		return;
	if (toggle && EnableScopeRender):
		mScopeRender.get_camera().fov = fov;
		mWeaponModel.SetLensTexture(mScopeRender.get_texture());
	else:
		mWeaponModel.SetLensTexture(null);

func GiveObjectDamage(object, damage, hit_pos = Vector3()):
	if (!object || !object.is_inside_tree() || !object.has_method("GiveDamage")):
		return;
	
	# Initial damage
	var dmg = damage * rand_range(0.8, 1.2);
	
	if (hit_pos.length() > 0.0 && object.is_in_group("player")):
		# Position based damage
		var obj_pos = object.global_transform.origin;
		var height_diff = hit_pos.y - obj_pos.y;
		
		# Hit body
		dmg = (dmg * 0.6) + (damage * 0.4 * clamp(height_diff, 0.0, 1.0));
		
		# Hit head
		if (height_diff > 1.0):
			dmg = dmg + (damage * 0.4 * clamp(height_diff, 1.0, 2.0));
	
	# Give damage to object
	object.GiveDamage(dmg);
