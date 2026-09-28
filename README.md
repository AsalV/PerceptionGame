# Perception Game - based on VR/AR@MIT Godot XR Project Template

Features basic XR setup, dynamic controller/hand models for both hand and regular tracking, passthrough setup, and other basic scaffolds.


For mesh and shape, go to scenes > levels > level tscn.
Then, click on the props in the scene map to edit them. (Do not touch the prop tscns in the FileSystem). Please do not remove any nodes.


## 1 Template Capabilities

This template contains:
- Prebuilt XR setup
- Controller/hand tracking visuals
- Some examples of code and similar for gdscript
- Grabbing support in both controller (grip) and hand tracking (pinch)
- Cool XR shader examples
- General ideas to kickstart your own project!

## 2 Installation / Setup

A set of slides also detailing this process can be found here: https://docs.google.com/presentation/d/1k10QOjVzC8dSaK8WAtLZF0jyv3P6TW-NY8ZJmvSjivk/edit?usp=sharing

Written instructions here coming soon tm

## Toybox Vision Sort

The project now contains a complete desktop-first perception game in `main.tscn`.
Players identify six toys and sort them into **Animal Toys** or **Things That Go**.
The same objects are presented in three progressively richer visual stages:

1. Silhouettes with identifying sound cues
2. Simple shapes and colors
3. Fully detailed pastel toy models

Correctly sorting all six toys advances the level. Completing level three displays
the win screen. Incorrect choices provide category feedback without removing the toy.

### Desktop controls

- WASD or arrow keys: move
- Mouse: look and aim
- Left click: pick up the aimed-at toy
- E: drop the held toy into the aimed-at sorting box
- Right click: return the held toy to its starting place
- Space / Shift: move the camera up / down
- Escape: release or recapture the mouse
- R: replay after winning

### Key implementation files

- `scripts/game_controller.gd`: environment, rules, interaction, audio, UI, levels, and win condition
- `scripts/toy_factory.gd`: procedural cat, dog, cow, car, bike, and train models
- `screenshots/level_1_silhouettes.png`: opening level screenshot
- `screenshots/level_3_full_detail.png`: final-detail level screenshot

Desktop builds use the regular camera. Android builds retain the OpenXR path for Quest testing.
