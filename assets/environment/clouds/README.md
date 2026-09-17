# Cloud artwork

Drop transparent `.png`, `.webp`, `.jpg`, `.jpeg`, or `.svg` cloud images here.

The game automatically discovers every supported image in this folder and distributes them across the sky. Transparent images around 512×256 pixels work well. Restart the running game after adding files so Godot imports them.

A cloud cleanup shader removes isolated specks, erodes contaminated outer pixels, and suppresses cyan/blue or dark matte outlines. Transparent PNG or WebP images still produce the best result.
