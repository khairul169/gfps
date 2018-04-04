extends "res://gfps/scripts/weapon/base_weapon.gd"

func _init():
	# Weapon name
	name = "G36C";
	
	# Resources
	view_scene = "view.tscn";
	
	# Sounds
	sfx['shoot'] = "g36c-shoot.wav";
	
	# Weapon stats
	clip = 40;
	ammo = 120;
	
	recoil = Vector2(1.4, 1.8);
	spread = Vector2(1.8, 6.0);
	move_speed = 0.96;
	damage = 16.0;
	
	firing_delay = 1.0/9.0;
	firing_range = 100.0;
	firing_mode = MODE_AUTO;
	
	reload_time = 2.4;
	muzzle_size = 1.6;
	
	can_aim = true;
	aim_fov = 40.0;
	aim_statsmultiplier = 0.8;
	aim_bobscale = 0.1;
	dualrender_fov = 30.0;
