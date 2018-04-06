extends "res://gfps/scripts/weapon/shotgun.gd"

func _init():
	# Weapon name
	name = "XM1014";
	
	# Resources
	view_scene = "view.tscn";
	
	# Sounds
	sfx['shoot'] = "sfx/shoot.wav";
	sfx['reload'] = AudioSequence.new(self, [
		[0.1, "sfx/shell_in.wav"]
	]);
	
	# Weapon stats
	clip = 8;
	ammo = 32;
	move_speed = 1.0;
	recoil = Vector2(2.2, 6.4);
	spread = Vector2(1.2, 1.8);
	damage = 12.0;
	
	firing_delay = 0.4;
	firing_range = 20.0;
	firing_mode = MODE_AUTO;
	reload_time = 0.6;
	muzzle_size = 2.8;
	can_aim = false;
	
	# Shotgun
	bullet_spread = 8;
	progressive_reload = true;
