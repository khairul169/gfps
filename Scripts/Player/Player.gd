extends Spatial

# Nodes
onready var controller = get_node("Controller");
onready var weapon = get_node("Weapon");

# Weapons
var weapon_handgun;
var weapon_ak47;
var weapon_launcher;
var weapon_xm1014;
var weapon_g36;

func _ready():
	# Load weapon list
	weapon_handgun = weapon.RegisterWeapon("res://Scripts/Weapon/Handgun.gd");
	weapon_ak47 = weapon.RegisterWeapon("res://Scripts/Weapon/AK47.gd");
	weapon_launcher = weapon.RegisterWeapon("res://Scripts/Weapon/Launcher.gd");
	weapon_xm1014 = weapon.RegisterWeapon("res://Scripts/Weapon/XM1014.gd");
	weapon_g36 = weapon.RegisterWeapon("res://Scripts/Weapon/G36.gd");
	
	# Enable character sprinting
	controller.mCanSprinting = true;
	
	# Set primary weapon
	weapon.SetActiveWeapon(weapon_g36);
	
	# Change camera y-rotation to follow this node rotation
	controller.mCameraRotation.y = rotation_degrees.y;

func _input(event):
	if (event is InputEventKey && event.pressed):
		if (event.scancode == KEY_1):
			weapon.SetActiveWeapon(weapon_ak47);
		
		if (event.scancode == KEY_2):
			weapon.SetActiveWeapon(weapon_handgun);
		
		if (event.scancode == KEY_3):
			weapon.SetActiveWeapon(weapon_xm1014);
		
		if (event.scancode == KEY_4):
			weapon.SetActiveWeapon(weapon_launcher);
		
		if (event.scancode == KEY_5):
			weapon.SetActiveWeapon(weapon_g36);
		
		# Reload weapon
		if (event.scancode == KEY_R):
			weapon.Reload();
		
		if (event.scancode == KEY_L):
			weapon.EnableScopeRender = !weapon.EnableScopeRender;
	
	if (event is InputEventMouseButton):
		if (weapon && event.button_index == BUTTON_LEFT):
			weapon.mInput['attack1'] = event.pressed;
		
		if (weapon && event.button_index == BUTTON_RIGHT):
			weapon.mInput['attack2'] = event.pressed;

func _physics_process(delta):
	# Update player input
	if (controller):
		controller.mInput['forward'] = Input.is_key_pressed(KEY_W);
		controller.mInput['backward'] = Input.is_key_pressed(KEY_S);
		controller.mInput['left'] = Input.is_key_pressed(KEY_A);
		controller.mInput['right'] = Input.is_key_pressed(KEY_D);
		
		controller.mInput['jump'] = Input.is_key_pressed(KEY_SPACE);
		controller.mInput['walk'] = Input.is_key_pressed(KEY_ALT);
		controller.mInput['sprint'] = Input.is_key_pressed(KEY_SHIFT);
