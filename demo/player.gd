extends "res://gfps/scripts/player/controller.gd"

# Weapons
var weapon_g36c;
var weapon_xm1014;

func _ready():
	# Load weapon configuration
	load_weapon();
	
	# Enable character sprinting
	can_sprint = true;

func _input(event):
	if (event is InputEventKey && event.pressed):
		# Reload weapon
		if ($weapon && event.scancode == KEY_R):
			$weapon.wpn_reload();
		
		# Toggle dual render scope
		if ($weapon && event.scancode == KEY_L):
			$weapon.EnableScopeRender = !$weapon.EnableScopeRender;
	
	if (event is InputEventMouseButton):
		if ($weapon && event.button_index == BUTTON_LEFT):
			$weapon.input['attack'] = event.pressed;
		
		if ($weapon && event.button_index == BUTTON_RIGHT):
			$weapon.input['special'] = event.pressed;

func _physics_process(delta):
	# Update player input
	input['forward'] = Input.is_key_pressed(KEY_W);
	input['backward'] = Input.is_key_pressed(KEY_S);
	input['left'] = Input.is_key_pressed(KEY_A);
	input['right'] = Input.is_key_pressed(KEY_D);
	
	input['jump'] = Input.is_key_pressed(KEY_SPACE);
	input['walk'] = Input.is_key_pressed(KEY_ALT);
	input['sprint'] = Input.is_key_pressed(KEY_SHIFT);
	
	# Update player interface
	update_hud();

func load_weapon():
	# Register weapon
	weapon_g36c = $weapon.register_weapon("res://demo/weapon/g36c/g36c.gd");
	weapon_xm1014 = $weapon.register_weapon("res://demo/weapon/xm1014/xm1014.gd");
	
	# Add weapon to inventory
	$inventory.set_item(0, weapon_g36c);
	$inventory.set_item(1, weapon_xm1014);
	
	# Select primary weapon
	$inventory.select_item(0);

func update_hud():
	var cur_wpn = $weapon.get_current_weapon();
	if (cur_wpn):
		# Set ammo label text
		$interface/ammo.show();
		$interface/ammo.text = str($weapon.wpn_clip).pad_zeros(2) + "/" + str($weapon.wpn_ammo).pad_zeros(3);
		
		# Weapon name
		$interface/weapon_name.show();
		$interface/weapon_name.text = cur_wpn.name;
	
	else:
		# Hide HUD
		$interface/ammo.hide();
		$interface/weapon_name.hide();
	
	if (cur_wpn && (!cur_wpn.is_aiming || !cur_wpn.aim_hidecrosshair)):
		$interface/crosshair.visible = true;
	else:
		$interface/crosshair.visible = false;
