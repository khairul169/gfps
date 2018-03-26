extends Node

# Exports
export (NodePath) var Controller;
export (Script) var FirstPersonView;
export var ModelScaling = 0.05;
export var EnableScopeRender = true;

# Prefabs
export (PackedScene) var MuzzleFlash;
export (PackedScene) var BulletShell;
export (PackedScene) var BulletImpact;

# Weapon attachment
const BONE_MUZZLEFLASH = "muzzle_flash";
const BONE_BULLETEJECT = "bullet_eject";

# Nodes
onready var world_node = get_parent().get_parent();

# Signals
signal weapon_attach();
signal weapon_unload();
signal weapon_attack1();
signal weapon_attack2();
signal weapon_reload();
signal object_hit(obj, pos);

# Nodes
var fpview_node;
var weapon_node;
var anim_player;
var muzzleflash_node;
var stream_player;
var scope_renderer;

# Variables
var is_firing = false;
var is_reloading = false;
var next_think = 0.0;
var next_idle = 0.0;
var is_sprinting = false;
var wpn_clip = 0;
var wpn_spread = 0.0;

# Custom weapon configuration
var wpn_clip_max = 0;
var wpn_ammo = 0;
var wpn_initialspread = 0.5;
var wpn_maxspread = 5.0;
var wpn_recoil = Vector2(1.2, 1.5);
var wpn_reloadtime = 2.0;
var wpn_firingdelay = 1.0/10.0;
var wpn_movespeed = 1.0;

# Input
var input = {
	'attack1' : false,
	'attack2' : false
};

# Registered weapon
var weapon_list = [];
var current_wpn = -1;

func _ready():
	# Get Nodes
	if (typeof(Controller) == TYPE_NODE_PATH):
		Controller = get_node(Controller);
		Controller.PlayerWeapon = self;
	
	# Create weapon view
	if (Controller.CameraNode):
		# Instance scene
		fpview_node = Spatial.new();
		fpview_node.name = "firstperson_view";
		
		# Set script
		if (FirstPersonView is Script):
			fpview_node.set_script(FirstPersonView);
			fpview_node.PlayerController = Controller;
		
		# Add to camera node
		Controller.CameraNode.add_child(fpview_node);
	
	# Create stream player
	if (Controller):
		stream_player = AudioStreamPlayer3D.new();
		stream_player.name = "stream_player";
		stream_player.max_distance = 100.0;
		stream_player.unit_db = 8.0;
		stream_player.max_db = 12.0;
		Controller.add_child(stream_player);
	
	# Instance prefabs
	if (MuzzleFlash):
		muzzleflash_node = MuzzleFlash.instance();
	
	# Create scope lens viewport
	scope_renderer = Viewport.new();
	scope_renderer.name = "scope_renderer";
	scope_renderer.size = Vector2(1, 1) * 512.0;
	scope_renderer.render_target_v_flip = true;
	
	var camera = Camera.new();
	camera.fov = 10.0;
	camera.cull_mask = 1;
	scope_renderer.add_child(camera, true);
	add_child(scope_renderer);
	
	# Hack! Prevent game from freezing when instancing bullet impact
	if (BulletImpact):
		var impact = BulletImpact.instance();
		add_child(impact);

func _process(delta):
	if (current_wpn < 0 || !Controller):
		return;
	
	if (next_think > 0.0):
		next_think = max(next_think - delta, 0.0);
	
	if (next_idle > 0.0):
		next_idle = max(next_idle - delta, 0.0);

func _physics_process(delta):
	if (current_wpn < 0 || !Controller):
		return;
	
	# Player input
	is_firing = input['attack1'];
	
	# Weapon think
	wpn_idle(delta);
	wpn_attack();
	wpn_special();
	
	# Refill clip
	if (is_reloading && next_think <= 0.0):
		wpn_postreload();
	
	# Update scope lens camera transform
	if (scope_renderer.get_camera()):
		scope_renderer.get_camera().global_transform = get_camera_transform();

##########################################################################

func able_to_sprint():
	return (next_think <= 0.0 && !is_firing && !is_reloading);

func wpn_idle(delta):
	# Substract weapon spread
	if (!is_firing && next_think <= 0.0):
		wpn_spread = clamp(wpn_spread - ((wpn_maxspread-wpn_initialspread) * 0.2), wpn_initialspread, wpn_maxspread);
	
	if (Controller.is_sprinting && !is_sprinting && next_think <= 0.0):
		sprint_toggled(true);
		is_sprinting = true;
		next_idle = 0.5;
		next_think = 0.1;
	
	if (!Controller.is_sprinting && is_sprinting && next_think <= 0.0):
		sprint_toggled(false);
		is_sprinting = false;
		next_idle = 0.5;
		next_think = 0.1;
	
	if (current_wpn > -1 && current_wpn < weapon_list.size()):
		weapon_list[current_wpn].think(delta);

func wpn_attack():
	if (!is_firing || next_think > 0.0 || is_reloading):
		return;
	
	# Cannot shoot while sprinting
	if (Controller.is_sprinting || is_sprinting):
		return;
	
	# Out of clip
	if (wpn_clip <= 0):
		return;
	
	var attack = false;
	if (current_wpn > -1 && current_wpn < weapon_list.size()):
		attack = weapon_list[current_wpn].attack();
	
	if (!attack):
		return;
	
	# Gun recoil
	create_recoil(wpn_recoil);
	
	# Muzzleflash
	if (muzzleflash_node && muzzleflash_node.scale.length() > 0.0):
		muzzleflash_node.flash();
	
	# Eject bullet shell
	if (weapon_list[current_wpn].ShellEjectNode):
		create_bulletshell(weapon_list[current_wpn].ShellEjectNode);
	
	# Reduce weapon clip
	wpn_clip -= 1;
	
	# Firing delay
	next_think = wpn_firingdelay;
	next_idle = next_think + 0.8;
	
	# Spread bullet
	wpn_spread = clamp(wpn_spread + ((wpn_maxspread-wpn_initialspread) * 0.1), wpn_initialspread, wpn_maxspread);
	
	# Emit attack signal
	emit_signal("weapon_attack1");

func wpn_special():
	if (!input['attack2'] || Controller.is_sprinting || is_sprinting || next_think > 0.0):
		return;
	
	next_think = 0.1;
	
	if (current_wpn > -1 && current_wpn < weapon_list.size()):
		weapon_list[current_wpn].special();
		emit_signal("weapon_attack2");

func sprint_toggled(sprinting):
	if (!Controller):
		return;
	if (current_wpn > -1 && current_wpn < weapon_list.size()):
		weapon_list[current_wpn].sprint_toggled(sprinting);

func wpn_reload():
	if (is_reloading || next_think > 0.0 || wpn_ammo <= 0.0 || wpn_clip >= wpn_clip_max):
		return;
	
	if (Controller.is_sprinting || is_sprinting):
		return;
	
	var can_reload = true;
	if (current_wpn > -1 && current_wpn < weapon_list.size()):
		can_reload = weapon_list[current_wpn].reload();
	
	if (can_reload):
		# Start reload
		is_reloading = true;
		next_think = wpn_reloadtime;
		next_idle = next_think + 0.2;

func wpn_postreload():
	if (wpn_ammo <= 0.0 || wpn_clip >= wpn_clip_max):
		return;
	
	# Reload magazine clip
	var wpn_clipFired = clamp(wpn_clip_max - wpn_clip, 0, wpn_clip_max);
	wpn_clip = min(wpn_clip + wpn_ammo, wpn_clip_max);
	wpn_ammo = max(wpn_ammo - wpn_clipFired, 0);
	
	# Set state
	is_reloading = false;
	next_think = 0.1;
	
	if (current_wpn > -1 && current_wpn < weapon_list.size()):
		weapon_list[current_wpn].post_reload();
		emit_signal("weapon_reload");

###########################################################################

func get_camera_transform():
	if (Controller):
		return Controller.get_camera_transform();
	else:
		return Transform();

func has_animation(anim):
	return (anim_player && anim_player.has_animation(anim));

func play_animation(anim, loop = false, custom_blend = -1, immediately = true):
	if (!anim_player):
		return;
	
	if (!immediately && anim_player.current_animation == anim):
		return;
	
	if (anim_player.has_animation(anim)):
		anim_player.get_animation(anim).loop = loop;
		anim_player.play(anim, custom_blend);

func create_recoil(recoil):
	# Recoil direction
	var recoil_impact = Vector3();
	recoil_impact.x = rand_range(-1.0, 1.0) * recoil.x;
	recoil_impact.y = rand_range(0.5, 1.0) * recoil.y;
	
	# Double the recoil when player is moving
	if (Controller.is_moving):
		recoil_impact *= 2.0;
	
	# And when climbing..
	if (Controller.is_climbing):
		recoil_impact *= 2.0;
	
	# Add camera impulse
	Controller.camera_impulse += recoil_impact;

func play_audio_stream(stream):
	if (!stream_player || !stream || !stream is AudioStream):
		return;
	
	stream_player.stream = stream;
	stream_player.play();

func shoot_bullet(distance):
	var mRayVector = Vector2();
	mRayVector.x += rand_range(-1.0, 1.0) * wpn_spread;
	mRayVector.y += rand_range(-1.0, 1.0) * wpn_spread;
	
	# Spread more when moving and climbing
	if (Controller.is_moving):
		mRayVector *= 2.0;
	
	if (Controller.is_climbing):
		mRayVector *= 2.0;
	
	# Cast a ray
	var cam_transform = get_camera_transform();
	var vec_from = cam_transform.origin;
	var vec_dir = cam_transform.basis.xform(Vector3(mRayVector.x, mRayVector.y, -distance));
	var result = Controller.get_world().direct_space_state.intersect_ray(vec_from, vec_from + vec_dir, [Controller]);
	
	# Ray hit an object
	if (!result.empty()):
		raytest_check(result, vec_dir);
		return result;
	
	return null;

func raytest_check(result, direction):
	if (!result || typeof(result) != TYPE_DICTIONARY || result.empty()):
		return;
	
	# Instantiate bullet hole
	if (result.collider is StaticBody):
		create_bulletimpact(result.position, result.normal, true);
	
	# Knock back rigidbody
	if (result.collider is RigidBody && result.collider.is_in_group("physics")):
		create_bulletimpact(result.position, result.normal, false);
		
		# Apply body impulse
		var pos = result.position-result.collider.global_transform.origin;
		result.collider.apply_impulse(pos, direction.normalized() * 2.0);
	
	# Give damage to damageable object
	if (result.collider.is_in_group("damageable")):
		create_bulletimpact(result.position, result.normal, false);
		give_object_damage(result.collider, 10.0, result.position);
	
	# Emit signal
	emit_signal("object_hit", result.collider, result.position);

func create_bulletimpact(pos, normal, bullet_hole = true):
	if (!BulletImpact):
		return;
	
	# Instance prefabs
	var instance = BulletImpact.instance();
	instance.spawn_bullethole = bullet_hole;
	world_node.add_child(instance);
	
	# Set transform
	instance.look_at_from_position(pos + (normal.normalized() * 0.01), pos + normal + Vector3(1, 1, 1) * 0.001, Vector3(0, 1, 0));

func create_bulletshell(node):
	if (!node || !node.is_inside_tree()):
		return;
	
	var shell = BulletShell.instance();
	shell.add_collision_exception_with(Controller);
	shell.global_transform = node.global_transform;
	shell.linear_velocity = -node.global_transform.basis.z.normalized() * 0.6;
	shell.linear_velocity.y = 0.4;
	world_node.add_child(shell);

func attach_muzzleflash(node, size = 0.0):
	if (!muzzleflash_node):
		return;
	
	if (node):
		muzzleflash_node.scale = Vector3(1, 1, 1) * size;
		node.add_child(muzzleflash_node);
	else:
		if (muzzleflash_node.get_parent()):
			muzzleflash_node.get_parent().remove_child(muzzleflash_node);

########################################################################

func setup_attachment(wpn, skeleton):
	if (!wpn || !skeleton):
		return;
	
	# Muzzleflash
	if (!MuzzleFlash || skeleton.find_bone(BONE_MUZZLEFLASH) < 0):
		return;
	
	# Attachment
	var attachment = BoneAttachment.new();
	attachment.name = BONE_MUZZLEFLASH;
	attachment.bone_name = BONE_MUZZLEFLASH;
	skeleton.add_child(attachment);
	
	# Set muzzle flash attachment node
	wpn.MuzzleNode = attachment;
	
	# Bullet shell eject
	if (!BulletShell || skeleton.find_bone(BONE_BULLETEJECT) < 0):
		return;
	
	# The attachment that we will use to instance the shell from
	attachment = BoneAttachment.new();
	attachment.name = BONE_BULLETEJECT;
	attachment.bone_name = BONE_BULLETEJECT;
	skeleton.add_child(attachment);
	
	# Set attachment node
	wpn.ShellEjectNode = attachment;

func register_weapon(path):
	if (!Directory.new().file_exists(path)):
		return -1;
	
	# Load script
	var wpn = load(path).new();
	wpn.PlayerWeapon = self;
	weapon_list.append(wpn);
	
	# Initialize weapon
	var id = (weapon_list.size()-1);
	wpn.set_meta("id", id);
	wpn.registered();
	
	# Models skeleton
	var skeleton = null;
	if (wpn.weapon_scene):
		skeleton = wpn.weapon_scene.find_node("Skeleton");
	
	# Set mesh layers
	for i in get_meshinstances(wpn.weapon_scene):
		i.layers = 16;
	
	# Initialize weapon attachment
	setup_attachment(wpn, skeleton);
	return id;

func set_weapon_scene(scene):
	if (!fpview_node):
		return;
	
	# Remove old scene
	if (weapon_node != null):
		fpview_node.remove_child(weapon_node);
		weapon_node = null;
	
	if (!scene || !scene is Spatial):
		return;
	
	# Set new scene
	weapon_node = scene;
	weapon_node.scale = Vector3(1, 1, 1) * ModelScaling;
	fpview_node.add_child(weapon_node);
	
	# Find animation player
	if (weapon_node.has_node("AnimationPlayer")):
		anim_player = weapon_node.get_node("AnimationPlayer");
		anim_player.playback_default_blend_time = 0.1;

func unload_current_weapon():
	if (current_wpn > -1 && current_wpn < weapon_list.size()):
		# Remove all attachments
		attach_muzzleflash(null);
		
		# Call weapon function
		weapon_list[current_wpn].unload();
	
	# Remove weapon
	current_wpn = -1;
	emit_signal("weapon_unload");

func get_current_weapon():
	if (current_wpn < 0 || current_wpn >= weapon_list.size()):
		return null;
	return weapon_list[current_wpn];

func set_current_weapon(id):
	# Cannot switch to current weapon. remove it first.
	if (current_wpn == id):
		return;
	
	# Remove current weapon
	unload_current_weapon();
	
	# Id isn't valid
	if (id == null || id < 0 || id >= weapon_list.size()):
		return;
	
	# Set current weapon id
	current_wpn = id;
	
	# Set weapon configuration
	wpn_clip_max = weapon_list[id].clip;
	wpn_initialspread = weapon_list[id].spread.x;
	wpn_maxspread = weapon_list[id].spread.y;
	wpn_recoil = weapon_list[id].recoil;
	wpn_reloadtime = weapon_list[id].reload_time;
	wpn_firingdelay = weapon_list[id].firing_delay;
	wpn_movespeed = weapon_list[id].move_speed;
	
	# Set weapon clip & ammo
	refill_weapon();
	
	# Set weapon state
	is_reloading = false;
	is_firing = false;
	is_sprinting = false;
	
	# Attach muzzleflash
	if (weapon_list[id].MuzzleNode):
		attach_muzzleflash(weapon_list[id].MuzzleNode, weapon_list[id].muzzle_size);
	
	# Call weapon draw function
	weapon_list[id].attach();
	emit_signal("weapon_attach");

func refill_weapon():
	if (current_wpn < 0 || current_wpn >= weapon_list.size()):
		return;
	
	wpn_clip = weapon_list[current_wpn].clip;
	wpn_ammo = weapon_list[current_wpn].ammo;

func set_weapon_ammo(clip, ammo):
	if (current_wpn < 0 || current_wpn >= weapon_list.size()):
		return;
	
	wpn_clip = clamp(clip, 0, wpn_clip_max);
	wpn_ammo = clamp(ammo, 0, weapon_list[current_wpn].ammo);

func add_weapon_clip(amount):
	if (current_wpn < 0 || current_wpn >= weapon_list.size()):
		return;
	
	wpn_clip = clamp(wpn_clip + amount, 0, wpn_clip_max);
	wpn_ammo = clamp(wpn_ammo - amount, 0, weapon_list[current_wpn].ammo);

func set_camera_fov(fov):
	if (!Controller):
		return;
	
	if (fov != null && fov > 0):
		Controller.camera_fov = fov;
	else:
		Controller.camera_fov = Controller.CameraFOV;

func set_camera_bobscale(scale):
	if (!fpview_node || !fpview_node.has_method("set_custom_scale")):
		return;
	if (scale != null && scale > 0.0):
		fpview_node.set_custom_scale(scale);
	else:
		fpview_node.set_custom_scale(1.0);

func get_meshinstances(node):
	if (!node || node.get_child_count() <= 0):
		return [];
	var meshes = [];
	for i in node.get_children():
		if (i is MeshInstance):
			meshes.append(i);
		for j in get_meshinstances(i):
			meshes.append(j);
	return meshes;

func add_to_world(node):
	if (!world_node || !node || !node is Node):
		return;
	world_node.add_child(node);

func set_camera_shifting(enabled):
	if (!fpview_node || !fpview_node.has_method("set_shifting_enabled")):
		return;
	fpview_node.set_shifting_enabled(enabled);

func toggle_weaponlens(toggle, fov = 60.0):
	if (!weapon_node || !weapon_node.has_method("set_lens_texture")):
		return;
	if (toggle && EnableScopeRender):
		scope_renderer.get_camera().fov = fov;
		weapon_node.set_lens_texture(scope_renderer.get_texture());
	else:
		weapon_node.set_lens_texture(null);

func give_object_damage(object, damage, hit_pos = Vector3()):
	if (!object || !object.is_inside_tree() || !object.has_method("give_damage")):
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
	object.give_damage(dmg);
