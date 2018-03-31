# gFPS - FPS Framework
## 02 - Player Sound Effects

In this tutorial, you will learn how to add footstep sound, landing sound, and other for the player controller.

## Create and Load Player Sounds

Open the `player.tscn` scene. Select root node, and add `Node` node to the tree. Rename it to `sounds`.

![sounds_tree](resources/sounds_tree.png?raw=true)

Attach player sounds script to the node. The scripts is located at `gfps/scripts/player/sounds.gd`.

![sounds_loadscript](resources/sounds_loadscript.png?raw=true)

Re-select the node. There should be several editable properties in the inspector tab.

## Configure SFX

![sounds_properties](resources/sounds_properties.png?raw=true)

In the editor inspector tab, you can select the sound effect for your player. It is self explained.

If you don't have sfx resource, you can use the example sfx in `gfps/sounds` directory.

![sounds_properties1](resources/sounds_properties1.png?raw=true)

`Step Delay` is used to delay the footstep.

---

Download completed project: [project_tutorial02.zip](resources/project_tutorial02.zip?raw=true)
