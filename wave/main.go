package main

import (
	"math/rand"
	"time"

	"github.com/gen2brain/raylib-go/raylib"
)

type Tile int

const (
	Water Tile = iota
	Grass
	Mountain
)

var tileColors = map[Tile]rl.Color{
	Water:    rl.Blue,
	Grass:    rl.Green,
	Mountain: rl.Gray,
}

var allowedNeighbors = map[Tile][]Tile{
	Water:    {Water, Grass},
	Grass:    {Water, Grass, Mountain},
	Mountain: {Grass, Mountain},
}

type pos struct {
	x int
	y int
}

var dirs = []pos{{-1, 0}, {1, 0}, {0, -1}, {0, 1}}

func main() {
	const screenSize = 800
	const gridSize = 20
	const cellSize = screenSize / gridSize

	rl.InitWindow(screenSize, screenSize, "Wave Function Collapse Terrain Demo")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	rand.Seed(time.Now().UnixNano())

	grid := generate(gridSize, gridSize)

	for !rl.WindowShouldClose() {
		if rl.IsKeyPressed(rl.KeySpace) {
			grid = generate(gridSize, gridSize)
		}

		rl.BeginDrawing()
		rl.ClearBackground(rl.RayWhite)

		for y := 0; y < gridSize; y++ {
			for x := 0; x < gridSize; x++ {
				t := grid[y][x][0] // Collapsed to single tile
				col := tileColors[t]
				rl.DrawRectangle(int32(x*cellSize), int32(y*cellSize), int32(cellSize), int32(cellSize), col)
			}
		}

		rl.EndDrawing()
	}
}

func generate(width, height int) [][][]Tile {
	for {
		grid := make([][][]Tile, height)
		for y := 0; y < height; y++ {
			grid[y] = make([][]Tile, width)
			for x := 0; x < width; x++ {
				grid[y][x] = []Tile{Water, Grass, Mountain}
			}
		}

		success := true
		for success {
			minEnt := 999
			var candidates []pos
			allCollapsed := true

			for y := 0; y < height; y++ {
				for x := 0; x < width; x++ {
					l := len(grid[y][x])
					if l > 1 {
						allCollapsed = false
						if l < minEnt {
							minEnt = l
							candidates = []pos{{x, y}}
						} else if l == minEnt {
							candidates = append(candidates, pos{x, y})
						}
					}
				}
			}

			if allCollapsed {
				return grid
			}

			idx := rand.Intn(len(candidates))
			cp := candidates[idx]
			poss := grid[cp.y][cp.x]
			chosenIdx := rand.Intn(len(poss))
			chosen := poss[chosenIdx]
			grid[cp.y][cp.x] = []Tile{chosen}

			var stack []pos
			for _, d := range dirs {
				nx := cp.x + d.x
				ny := cp.y + d.y
				if nx >= 0 && nx < width && ny >= 0 && ny < height {
					stack = append(stack, pos{nx, ny})
				}
			}

			success = propagate(grid, &stack, width, height)
		}
		// If contradiction, restart generation
	}
}

func propagate(grid [][][]Tile, stack *[]pos, width, height int) bool {
	for len(*stack) > 0 {
		cp := (*stack)[len(*stack)-1]
		*stack = (*stack)[:len(*stack)-1]

		oldPoss := grid[cp.y][cp.x]
		if len(oldPoss) == 1 {
			continue
		}

		newPoss := make([]Tile, len(oldPoss))
		copy(newPoss, oldPoss)

		for _, d := range dirs {
			nx := cp.x + d.x
			ny := cp.y + d.y
			if nx < 0 || nx >= width || ny < 0 || ny >= height {
				continue
			}

			nposs := grid[ny][nx]
			if len(nposs) != 1 {
				continue
			}

			nt := nposs[0]
			temp := []Tile{}
			for _, c := range newPoss {
				if contains(allowedNeighbors[nt], c) {
					temp = append(temp, c)
				}
			}
			newPoss = temp
		}

		if len(newPoss) == 0 {
			return false
		}

		if len(newPoss) < len(oldPoss) {
			grid[cp.y][cp.x] = newPoss
			for _, d := range dirs {
				nx := cp.x + d.x
				ny := cp.y + d.y
				if nx >= 0 && nx < width && ny >= 0 && ny < height {
					*stack = append(*stack, pos{nx, ny})
				}
			}
		}
	}
	return true
}

func contains(s []Tile, e Tile) bool {
	for _, a := range s {
		if a == e {
			return true
		}
	}
	return false
}
