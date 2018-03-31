# gFPS - FPS Framework
## 01 - Project Setup

In this tutorial, you will learn how to setup your fps project, make a character controller, and control the first person camera.

## New Project

Create new project in project manager, your project directory should be consist of this files:

![project_dir](resources/project_dir.png?raw=true)

Clone this repo or download it as .zip, then link or unzip `gfps` directory to your project dir.

Download [game_scene.zip](resources/game_scene.zip?raw=true) and uncompress it. Open `scene.tscn`, and also you will need to set `scene.tscn` as main scene of your project.

Now we will make the character controller to control our player.

## Player Controller

Create new scene and create new RigidBody node. Rename `RigidBody` node to `player`. Save it as `player.tscn`.

![player_scene](resources/player_scene.png?raw=true)

Set `Mode` to `Character` and `Gravity Scale` to `2`.

Create two `CollisionShape` node. We will use 2 shape, Ray shape and Capsule shape.

![shape_new](resources/shape_new.png?raw=true)

For shape1, create RayShape and shape2 CapsuleShape.

![shape_new1](resources/shape_new1.png?raw=true)

Click on the shape resource to edit shape parameters.

![shape_edit](resources/shape_edit.png?raw=true)

### Shape Parameters

![shape_ray](resources/shape_ray.png?raw=true)

![shape_capsule](resources/shape_capsule.png?raw=true)

Our shapes are created, but it is not supposed to be. We will change its translation and rotation to transform it properly.

### Shape Transforms

![shape1_transform](resources/shape1_transform.png?raw=true)

![shape2_transform](resources/shape2_transform.png?raw=true)

Now, your shape should look like this:

![shape_editor](resources/shape_editor.png?raw=true)

### Camera

We need to create `Camera` node to project 3d viewport as our player vision. Create new `Camera` node and rename it to `camera`.

![camera_tree](resources/camera_tree.png?raw=true)

Camera params:

- Fov: 60
- Z Near: 0.01
- Z Far: 100.0

Camera transform:

- Translation: 0, 1.2, 0
- Rotation: 0, 0, 0

You can always tweak the parameters with whatever you want.

Preview of our current controller:

![camera_preview](resources/camera_preview.png?raw=true)

### Attach Script

Create a script for `player` node that is inherited from `gfps/scripts/player/controller.gd`.

![player_script](resources/player_script.png?raw=true)

Now press or select the player node. You will see several configurable properties like move speed, acceleration, etc in the inspector panel.

![player_inspector](resources/player_inspector.png?raw=true)

Assign `Camera Node` properties to `camera` node in the scene to setup first person camera. Your player controller are ready, but you will need to map input to move your character.

## Input Mapping

Back to the `player.gd` script, we will make a script that control the player with WASD keys and several action like Jump, Sprint, etc.

![player_script1](resources/player_script1.png?raw=true)

Create new `_physics_process` function. Within this method, we will update input of our controller frame-per-frame.

```
func _physics_process(delta):
	# Player movement
	input['forward'] = Input.is_key_pressed(KEY_W);
	input['backward'] = Input.is_key_pressed(KEY_S);
	input['left'] = Input.is_key_pressed(KEY_A);
	input['right'] = Input.is_key_pressed(KEY_D);
	
	# Actions
	input['jump'] = Input.is_key_pressed(KEY_SPACE);
	input['walk'] = Input.is_key_pressed(KEY_ALT);
	input['sprint'] = Input.is_key_pressed(KEY_SHIFT);
```

`input` is a `Dictionary` variable that is used in `controller.gd` to check input from user. It holds several keys like forward, backward, and other.

`Input.is_key_pressed` can be replaced with `Input.is_action_pressed` if you want to map the keys from project settings. Now your character are ready for the action! But, save it first :p

**Note: You will need to set `enable_sprint` variable to `true` if you want to enable sprinting ability of your controller.**

## Instance Player to The Scene

Our character controller are ready, and we will place it in our game scene.

Switch to the `scene` tab, right click on the `scene` node and click `Instance Child Scene`.

![player_instance](resources/player_instance.png?raw=true)

Select `player.tscn` that we have created first, and set the translation or position to `0, 1, 0`.

And that's it :)

## Play the Scene

Our simple scene are ready to play. Now press F5 or press the play button to play the project.

If you see the following message, you need to select `scene.tscn` and set it as your main project scene.

![select_scene](resources/select_scene.png?raw=true)

Download completed project: [project_tutorial01.zip](resources/project_tutorial01.zip?raw=true)
