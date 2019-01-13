# godot-procedural-maze
A simple procedural maze for 3d games using Godot Engine

![Inside Godot](/addons/procedural_maze/screenshots/screenshot1.png)

![TPS view of the multimesh maze](/addons/procedural_maze/screenshots/screenshot2.png)

To create a new maze, create a new script that extends either **maze.gd** or **maze_multimesh.gd** from the **addons/procedural_maze** directory and attach it to a new StaticBody.

**maze.gd** builds a 3d maze using 3 materials (1 for the floor, 1 for the walls and 1 for the ceiling) and exports the following variables:
* **size_x** and **size_y**, the number of columns and rows of the maze grid
* **corridor_width** the width of rows and columns
* **wall_width** the width of generated walls
* **height** the height of the maze
* **random_seed** the seed used when creating the maze
* **wall_material**, **floor_material** and **ceiling material** the materials used for floor, wall and ceiling

**maze_multimesh.gd** uses an array of wall models and will instantiate them randomly and has the following additional variables:
* **wall_models** an array of meshes to be used as walls inside the maze
* **outer_wall_models** an array of meshes to be used as walls
* **pillar_model** is a mesh that is used where walls end

You can add a child node named **Config** to the maze and add CollisionShape nodes with box shapes to this node. this will exclude the corresponding zones from maze generation (the example show how this can be used to define rooms and openings in the maze).

Your maze script can also redefine the **instanciate_objects** function. This function is automatically called at the ens of maze generate with an array of object locations as parameter. Objects are either "loot" and "door" and ordered in a "maze walking order" that can be used to place doors and keys in the maze.

Character model used by the example: https://opengameart.org/content/animated-human-low-poly.