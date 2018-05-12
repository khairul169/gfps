extends "res://gfps/scripts/weapon/base_weapon.gd"

# Stats
var impulse_force = 15.0;
var drag_speed = 5.0;
var static_distance = 0.0;

# Variables
var grab_target = null;
var target_distance = 0.0;
var target_gravity = 0.0;
var target_offset = Vector3();

###########################################################

func _init():
	# Weapon name
	name = "Base Physics Gun";
	
	# Weapon stats
	clip = 1;
	ammo = 0;
	recoil = Vector2(1.4, 4.8);
	firing_mode = MODE_SINGLE;
	firing_range = 5.0;
	firing_delay = 1.0;

###########################################################

func think(delta):
	.think(delta);
	
	if (!grab_target || PlayerWeapon.next_think > 0.0):
		return;
	
	var object_distance = target_distance;
	if (static_distance > 0.0):
		object_distance = static_distance;
	
	var new_position = PlayerWeapon.get_camera_transform().xform(Vector3(0, 0, -object_distance)) - target_offset;
	var object_velocity = (new_position - grab_target.global_transform.origin) * drag_speed;
	
	if (object_velocity.length() > 50.0):
		set_object_state(false);
		return;
	
	grab_target.linear_velocity = object_velocity;
	grab_target.angular_velocity = Vector3();

func attach():
	.attach();

func unload():
	.unload();
	
	grab_target = null;

func attack():
	if (!grab_target || impulse_force <= 0.0):
		return false;
	
	var object = grab_target;
	set_object_state(false);
	
	var impulse = PlayerWeapon.get_camera_transform().basis.xform(Vector3(0, 0, -impulse_force));
	object.apply_impulse(Vector3(), impulse);
	
	# Shoot animation
	PlayerWeapon.play_animation('shoot', false, 0.05);
	
	# Play sound
	play_audio('shoot');
	return true;

func special():
	if (next_special > 0.0):
		return;
	
	# Delay function
	next_special = firing_delay;
	
	if (grab_target):
		set_object_state(false);
		return;
	
	# Grab animation
	PlayerWeapon.play_animation('grab', false, 0.05);
	
	# Play sound
	play_audio('grab');
	
	var ray = PlayerWeapon.screenray_test(Vector3(0, 0, -firing_range));
	if (ray.result.empty()):
		return true;
	
	if (ray.result.collider is RigidBody && ray.result.collider.is_in_group("physics")):
		set_object_state(true, ray.result.collider, ray.result.position);

func reload():
	return false;

func set_object_state(picked, object = null, hit_position = Vector3()):
	if (picked):
		target_distance = object.global_transform.origin.distance_to(PlayerWeapon.get_camera_transform().origin);
		target_gravity = object.gravity_scale;
		target_offset = hit_position - object.global_transform.origin;
		object.gravity_scale = 0.0;
		object.continuous_cd = true;
		grab_target = object;
	else:
		grab_target.gravity_scale = target_gravity;
		grab_target.continuous_cd = true;
		grab_target.linear_velocity = Vector3();
		grab_target.angular_velocity = Vector3();
		
		grab_target = null;
		target_gravity = 0.0;
		target_distance = 0.0;
		target_offset = Vector3();
