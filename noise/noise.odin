package main

import  "core:fmt"
import  "core:math/rand"
import rl "vendor:raylib"

SCREEN_WIDTH :: 320
SCREEN_HEIGHT :: 180
BOTTOM :: 12
ZOOM :: 4

noise: [SCREEN_HEIGHT][SCREEN_WIDTH]bool

main :: proc() {
    rl.InitWindow(SCREEN_WIDTH*ZOOM, (SCREEN_HEIGHT+BOTTOM)*ZOOM, "Noise")
    defer rl.CloseWindow()

    rl.SetTargetFPS(60)

    noiseFactor:f32 = 0.5
    updateNoise(noiseFactor)

    camera := rl.Camera2D{
        zoom = ZOOM,
    }

    for !rl.WindowShouldClose() {
        if rl.IsKeyPressed(.DOWN) {
            if noiseFactor > 0.1 {
                noiseFactor -= 0.1
            }
            updateNoise(noiseFactor)
        }

        if rl.IsKeyPressed(.UP) {
            if noiseFactor < 1.0 {
                noiseFactor += 0.1
            }
            updateNoise(noiseFactor)
        }

        if rl.IsKeyPressed(.SPACE) {
            updateNoise(noiseFactor)
        }

        rl.BeginDrawing()
        rl.BeginMode2D(camera)
        rl.ClearBackground(rl.BLACK)
        drawNoise()
        drawStatus(noiseFactor)
        rl.EndMode2D()
        rl.EndDrawing()
        free_all(context.temp_allocator)
    }
}


updateNoise :: proc(f: f32) {
    for y in 0 ..< SCREEN_HEIGHT {
        for x in 0 ..< SCREEN_WIDTH {
            pixel := rand.float32() < f
            noise[y][x] = pixel
        }
    }
}

drawNoise :: proc() {
    for y in 0 ..< SCREEN_HEIGHT {
        for x in 0 ..< SCREEN_WIDTH {
            if noise[y][x] {
                rl.DrawPixel(i32(x), i32(y), rl.WHITE)
            }
        }
    }

}

drawStatus :: proc(noiseFactor: f32) {
    x:i32 = 4
    y:i32 = SCREEN_HEIGHT + 1
    font:i32 = 10
    rl.DrawText(fmt.ctprintf("%d%%", int(noiseFactor * 100)), x, y, font, rl.GREEN)
}