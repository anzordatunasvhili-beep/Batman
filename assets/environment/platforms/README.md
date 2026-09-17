# Platform textures

Place seamless platform images here. These are intentionally opt-in because each region may need a specific texture.

To use one, load it in `scripts/game.gd` and pass it as the fourth argument to `make_platform()`. Example:

```gdscript
var grass_texture := load("res://assets/environment/platforms/grass.png") as Texture2D
make_platform(Vector2(500, 570), Vector2(1000, 90), "grass", grass_texture)
```

Without images, platforms use the built-in procedural grass, stone, rust, and crystal styles.
