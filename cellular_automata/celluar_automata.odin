package main

import  "core:fmt"
import  "core:math/rand"
import rl "vendor:raylib"

ZONES :: 40
SCREEN_WIDTH :: 16 * ZONES
SCREEN_HEIGHT :: 9 * ZONES
BOTTOM :: 12
ZOOM :: 2
ADJUST :: 0.01

noise: [SCREEN_HEIGHT][SCREEN_WIDTH]bool
next: [SCREEN_HEIGHT][SCREEN_WIDTH]bool

main :: proc() {
    rl.InitWindow(SCREEN_WIDTH * ZOOM, (SCREEN_HEIGHT + BOTTOM) * ZOOM, "Noise")
    defer rl.CloseWindow()

    rl.SetTargetFPS(60)

    factor :f32 = 0.5
    update_noise(factor)
    smooth := 0

    camera := rl.Camera2D{
        zoom = ZOOM,
    }

    for !rl.WindowShouldClose() {
        if rl.IsKeyPressed(.DOWN) {
            if factor > ADJUST {
                factor -= ADJUST
            }
            update_noise(factor)
            for i in 0..<smooth {
                moore_neighborhood()
            }
        }

        if rl.IsKeyPressed(.UP) {
            factor += ADJUST
            update_noise(factor)
            for i in 0..<smooth {
                moore_neighborhood()
            }
        }

        if rl.IsKeyPressed(.SPACE) {
            update_noise(factor)
            for i in 0..<smooth {
                moore_neighborhood()
            }
        }

        if rl.IsKeyPressed(.LEFT) {
            if smooth > 0 {
                smooth -= 1
                update_noise(factor)
                for i in 0..<smooth {
                    moore_neighborhood()
                }
            }
        }

        if rl.IsKeyPressed(.RIGHT) {
            smooth += 1
            moore_neighborhood()
        }


        rl.BeginDrawing()
        rl.BeginMode2D(camera)
        rl.ClearBackground(rl.BLACK)
        draw_noise()
        draw_status(factor, smooth)
        rl.EndMode2D()
        rl.EndDrawing()
        free_all(context.temp_allocator)
    }
}


update_noise :: proc(f: f32) {
    for y in 0 ..< SCREEN_HEIGHT {
        for x in 0 ..< SCREEN_WIDTH {
            pixel := rand.float32() < f
            noise[y][x] = pixel
        }
    }
}

draw_noise :: proc() {
    for y in 0 ..< SCREEN_HEIGHT {
        for x in 0 ..< SCREEN_WIDTH {
            if noise[y][x] {
                rl.DrawPixel(i32(x), i32(y), rl.WHITE)
            }
        }
    }

}

draw_status :: proc(factor: f32, smooth: int) {
    x :i32 = 4
    y :i32 = SCREEN_HEIGHT + 1
    font :i32 = 10
    rl.DrawText(fmt.ctprintf("%d%% / smoothing: %d", int(factor * 100), smooth), x, y, font, rl.GREEN)
}

moore_neighborhood :: proc() {
    for y in 0 ..< SCREEN_HEIGHT {
        for x in 0 ..< SCREEN_WIDTH {
            walls := 0
            for offset_y in -1..=1 {
                for offset_x in -1..=1 {
                    dx := x + offset_x
                    dy := y + offset_y

                    if dx < 0 || dx >= SCREEN_WIDTH || dy < 0 || dy >= SCREEN_HEIGHT {
                        walls += 1
                    } else if noise[dy][dx] == false {
                        walls += 1
                    }
                }
            }

            next[y][x] = walls <= 4
        }
    }

    copy_next()
}

copy_next :: proc() {
    for y in 0 ..< SCREEN_HEIGHT {
        for x in 0 ..< SCREEN_WIDTH {
            noise[y][x] = next[y][x]
        }
    }
}