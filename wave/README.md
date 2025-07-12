# Wave Function Collapse

This Go code uses Raylib to visualize a simple wave function collapse algorithm for generating terrain. It defines three tile types (Water, Grass, Mountain) with adjacency rules to ensure coherent terrain (e.g., water borders grass but not directly mountains). The grid is 20x20, rendered as colored squares in an 800x800 window. Press space to regenerate the terrain.

To run this, install the Raylib Go bindings with `go get github.com/gen2brain/raylib-go/raylib`, ensure Raylib is installed on your system (see https://github.com/gen2brain/raylib-go for setup), then `go run` the file.

The WFC implementation initializes all cells with all possible tiles, iteratively collapses the cell with the lowest entropy (fewest possibilities) to a random tile, and propagates constraints to neighbors. If a contradiction occurs (no possible tiles for a cell), it restarts the generation process. This is a basic version; for more complex games, you could expand tiles, rules, or add patterns from sample inputs.