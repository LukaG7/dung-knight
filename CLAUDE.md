# Dungeon crawler

A third-person 3D dungeon crawler in Godot 4. You play a knight fighting
skeletons through a maze. Reach the exit to clear the level. Ten levels
eventually; right now we are building level 1 only.

## Who I am

I'm new to Godot and new to gamedev. I come from marketing/sales automation
(Zapier, CRMs), so I understand triggers, state, and conditional logic — but
not engines, not 3D math, and not C#/GDScript idioms yet.

When you write code for me:
- Explain *why*, briefly, in comments — especially anything involving vectors,
  transforms, or rotation. That's the part I can't yet debug on my own.
- Prefer the boring, standard Godot way over the clever way.
- If I ask for something that's a bad idea at my stage, say so before doing it.
- Don't refactor things I didn't ask you to touch.

## Current milestone

**Milestone 3 — dungeon and knight.** Replace the box mesh with the KayKit
knight model, then build the maze with GridMap and KayKit dungeon tiles.
Animations come after the model is standing in place.

Done when: the knight (T-posing is fine) walks through a hand-painted
dungeon maze to the exit.

### The ladder (for context — don't jump ahead)

1. ~~Grey box — capsule walks in a room~~ ✅
2. ~~Exit trigger, win screen~~ ✅
3. Dungeon and knight — GridMap maze, KayKit model  ← HERE
4. Skeleton chases you — NavigationAgent3D pathfinding
5. Sword kills skeleton — Area3D hitbox on the swing
6. Level 1 finished — then 2–10 are content, not code

## Architecture decisions already made

- **Godot 4.x, GDScript.** Not C#, not Godot 3.
- **Third-person camera** on a SpringArm3D. The spring arm is non-negotiable —
  it's what stops the camera clipping into dungeon walls.
- **Levels are hand-built with GridMap**, not procedurally generated. Level
  design should be painting tiles, not writing a maze algorithm.
- **Free CC0 art from KayKit** (kaylousberg.itch.io): Adventurers pack for the
  knight, Skeletons pack for enemies, Dungeon pack for tiles, plus their
  Character Animations pack. All GLTF. We do not make our own art.
- **Enemies use NavigationAgent3D** over a baked NavigationRegion3D.
- **Combat is hitbox-based**: an Area3D on the sword, enabled only during the
  swing animation's active frames.

## Node structure

Player scene (`scenes/player.tscn`):

```
Player (CharacterBody3D)      <- scripts/player.gd
  CollisionShape3D            <- CapsuleShape3D
  Mesh (Node3D)               <- visible model goes in here
  CameraPivot (Node3D)        <- y ≈ 1.5, chest height
    SpringArm3D               <- spring_length ≈ 4
      Camera3D
```

Why Mesh and CameraPivot are siblings: the camera yaws freely with the mouse
while the knight only turns when he moves. If the model were under the pivot,
he'd spin with the camera.

## Conventions

- `snake_case` for files, variables, functions. `PascalCase` for node names.
- Static types everywhere: `var speed: float = 5.0`, not `var speed = 5.0`.
- Tunable numbers are `@export` so I can adjust them in the inspector
  without touching code.
- Signals over polling when nodes need to talk to each other.
- `scripts/` for .gd, `scenes/` for .tscn, `assets/` for imported models.

## What you can't do

You can't click things in the Godot editor. Scene trees, node creation,
inspector values, GridMap painting, and navmesh baking are all mine.

So when a task needs editor work: tell me the exact steps to do by hand,
then write the script that assumes it's done. Don't try to hand-author .tscn
files — they're fragile and I should be learning the editor anyway.

## Input map

Defined in Project Settings → Input Map:

| Action        | Key   |
|---------------|-------|
| move_forward  | W     |
| move_back     | S     |
| move_left     | A     |
| move_right    | D     |
| jump          | Space |
| attack        | Left mouse (added at milestone 5) |
