extends "res://gfps/scripts/weapon/base_weapon.gd"

# Stats
var impulse_force = 8.0;
var drag_speed = 5.0;

# Variables
var grab_target = null;
var target_distance = 0.0;
var target_gravity = 0.0;

###########################################################

func _init():
	# Weapon name
	name = "base_physicsgun";
	
	# Weapon stats
	clip = 1;
	ammo = 0;
	firing_mode = MODE_SINGLE;
	firing_range = 5.0;
	firing_delay = 0.1;

###########################################################

func think(delta):
	.think(delta);
	
	if (!grab_target || PlayerWeapon.next_think > 0.0):
		return;
	
	var new_position = PlayerWeapon.get_camera_transform().xform(Vector3(0, 0, -target_distance));
	var object_dir = new_position - grab_target.global_transform.origin;
	
	grab_target.linear_velocity = object_dir * drag_speed;
	grab_target.angular_velocity = Vector3();

func attach():
	.attach();

func unload():
	.unload();
	
	grab_target = null;

func attack():
	if (!.attack(false)):
		return false;
	
	# Keep weapon clip above zero
	PlayerWeapon.wpn_clip += 1;
	
	if (grab_target):
		set_object_state(false);
		return;
	
	var ray = PlayerWeapon.screenray_test(Vector3(0, 0, -firing_range));
	if (ray.result.empty()):
		return true;
	
	if (ray.result.collider is RigidBody && ray.result.collider.is_in_group("physics")):
		set_object_state(true, ray.result.collider);
	return true;

func special():
	next_special = 0.5;
	
	if (!grab_target):
		return;
	
	var impulse = PlayerWeapon.get_camera_transform().basis.xform(Vector3(0, 0, -impulse_force));
	grab_target.apply_impulse(Vector3(), impulse);
	
	set_object_state(false);

func reload():
	return false;

func set_object_state(picked, object = null):
	if (picked):
		target_distance = object.global_transform.origin.distance_to(PlayerWeapon.get_camera_transform().origin);
		target_gravity = object.gravity_scale;
		object.gravity_scale = 0.0;
		object.continuous_cd = true;
		grab_target = object;
	else:
		grab_target.gravity_scale = target_gravity;
		grab_target.continuous_cd = true;
		grab_target = null;
		target_gravity = 0.0;
		target_distance = 0.0;
