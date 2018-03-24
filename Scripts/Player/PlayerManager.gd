extends Spatial

# Nodes
onready var controller = get_node("Controller");
onready var weapon = get_node("Weapon");

# Weapons
var weapon_handgun;
var weapon_ak47;
var weapon_rpg7;
var weapon_xm1014;
var weapon_g36c;

func _ready():
	# Set network player node
	if (has_node("/root/NetworkManager")):
		get_node("/root/NetworkManager").mPlayerNode = self;
		get_node("/root/NetworkManager").connect("server_hosted", self, "on_server_hosted");
	
	# Load weapon list
	weapon_handgun = weapon.RegisterWeapon("res://Scripts/Weapon/Handgun.gd");
	weapon_ak47 = weapon.RegisterWeapon("res://Scripts/Weapon/AK47.gd");
	weapon_rpg7 = weapon.RegisterWeapon("res://Scripts/Weapon/RPG7.gd");
	weapon_xm1014 = weapon.RegisterWeapon("res://Scripts/Weapon/XM1014.gd");
	weapon_g36c = weapon.RegisterWeapon("res://Scripts/Weapon/G36C.gd");
	
	# Connect weapon signals
	weapon.connect("weapon_attach", self, "update_hud");
	weapon.connect("weapon_attack1", self, "update_hud");
	weapon.connect("weapon_attack2", self, "update_hud");
	weapon.connect("weapon_unload", self, "update_hud");
	weapon.connect("weapon_reload", self, "update_hud");
	
	# Enable character sprinting
	controller.mCanSprinting = true;
	
	# Set primary weapon
	weapon.SetActiveWeapon(weapon_handgun);
	
	# Change camera y-rotation to follow this node rotation
	controller.SetCameraRotation(0.0, rotation_degrees.y);

func _input(event):
	if (event is InputEventKey && event.pressed):
		if (event.scancode == KEY_1):
			weapon.SetActiveWeapon(weapon_ak47);
		
		if (event.scancode == KEY_2):
			weapon.SetActiveWeapon(weapon_handgun);
		
		if (event.scancode == KEY_3):
			weapon.SetActiveWeapon(weapon_xm1014);
		
		if (event.scancode == KEY_4):
			weapon.SetActiveWeapon(weapon_rpg7);
		
		if (event.scancode == KEY_5):
			weapon.SetActiveWeapon(weapon_g36c);
		
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

func update_hud():
	var cur_wpn = weapon.GetCurrentWeapon();
	if (cur_wpn != null):
		# Set ammo label text
		$HUD/Ammo.show();
		$HUD/Ammo.text = str(weapon.mClip).pad_zeros(2) + "/" + str(weapon.mAmmo).pad_zeros(3);
		
		# Weapon name
		$HUD/WeaponName.show();
		$HUD/WeaponName.text = cur_wpn.mName;
	
	else:
		# Hide HUD
		$HUD/Ammo.hide();
		$HUD/WeaponName.hide();

func on_server_hosted():
	NetworkManager.CreateLocalPlayer();
