package main

import rl "vendor:raylib"
import "core:math/rand"

TILE_SIZE :: 60
MAP_WIDTH :: 20
MAP_HEIGHT :: 15
SCREEN_WIDTH :: MAP_WIDTH * TILE_SIZE
SCREEN_HEIGHT :: MAP_HEIGHT * TILE_SIZE
EMPTY_COLOR :: rl.DARKGREEN
ROAD_COLOR :: rl.GOLD
BORDER_COLOR :: rl.BLACK
BORDER_SIZE :: 2.0

board: [MAP_HEIGHT][MAP_WIDTH]u8

main :: proc() {
    rl.SetTraceLogLevel(.WARNING)
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Wave Collapse")
    defer rl.CloseWindow()
    rl.SetTargetFPS(60)

    init_map()

    for !rl.WindowShouldClose() {
        rl.BeginDrawing()
        rl.ClearBackground(rl.SKYBLUE)
        draw_board()
        rl.EndDrawing()
    }
}

draw_board :: proc() {
    for y in 0..<MAP_HEIGHT {
        for x in 0..<MAP_WIDTH {
            draw_tile(x, y)
        }
    }
}

draw_tile :: proc(xx, yy: int) {
    x := f32(xx) * TILE_SIZE
    y := f32(yy) * TILE_SIZE
    s := f32(TILE_SIZE) / 3.0

    m := tiles[board[yy][xx]]
    for r in 0 ..< 3 {
        for c in 0 ..< 3 {
            rec := rl.Rectangle{ x + f32(c) * s, y + f32(r) * s, s, s }
            v := m[r][c]
            if v == 1 {
                rl.DrawRectangleRec(rec, ROAD_COLOR)
            } else {
                rl.DrawRectangleRec(rec, EMPTY_COLOR)
            }

            if r < 2 {
                if v == 0 && m[r + 1][c] == 1 {
                    rl.DrawLineEx(
                    rl.Vector2{ x + f32(c) * s, y + f32(r + 1) * s - BORDER_SIZE / 2 },
                    rl.Vector2{ x + f32(c + 1) * s, y + f32(r + 1) * s - BORDER_SIZE / 2 },
                    BORDER_SIZE,
                    BORDER_COLOR)
                }
            } else if r == 2 {
                if v == 0 && m[r - 1][c] == 1 {
                    rl.DrawLineEx(
                    rl.Vector2{ x + f32(c) * s, y + f32(r) * s + BORDER_SIZE / 2 },
                    rl.Vector2{ x + f32(c + 1) * s, y + f32(r) * s + BORDER_SIZE / 2 },
                    BORDER_SIZE,
                    BORDER_COLOR)
                }
            }

            if c < 2 {
                if v == 0 && m[r][c + 1] == 1 {
                    rl.DrawLineEx(
                    rl.Vector2{ x + f32(c + 1) * s - BORDER_SIZE / 2, y + f32(r) * s },
                    rl.Vector2{ x + f32(c + 1) * s - BORDER_SIZE / 2, y + f32(r + 1) * s },
                    BORDER_SIZE,
                    BORDER_COLOR)
                }
            } else if c == 2 {
                if v == 0 && m[r][c - 1] == 1{
                    rl.DrawLineEx(
                    rl.Vector2{ x + f32(c) * s + BORDER_SIZE / 2, y + f32(r) * s },
                    rl.Vector2{ x + f32(c) * s + BORDER_SIZE / 2, y + f32(r + 1) * s },
                    BORDER_SIZE,
                    BORDER_COLOR)
                }
            }

            //rl.DrawRectangleLinesEx(rec, 1, rl.WHITE)
        }
    }

    if m[1][1] == 1 {
        r := 1
        c := 1
        rec := rl.Rectangle{ x + f32(c) * s, y + f32(r) * s, s, s }

        // upper left corner
        if m[0][0] == 0 && m[0][1] == 0 && m[1][0] == 0 {
            rl.DrawRectangle(
            i32(x + f32(c) * s - BORDER_SIZE),
            i32(y + f32(r) * s - BORDER_SIZE),
            i32(BORDER_SIZE),
            i32(BORDER_SIZE), BORDER_COLOR)
        }

        // upper right corner
        if m[0][1] == 0 && m[0][2] == 0 && m[1][2] == 0  {
            rl.DrawRectangle(
            i32(x + f32(c + 1) * s),
            i32(y + f32(r) * s - BORDER_SIZE),
            i32(BORDER_SIZE),
            i32(BORDER_SIZE), BORDER_COLOR)
        }

        // lower left corner
        if m[1][0] == 0 && m[2][0] == 0 && m[2][1] == 0 {
            rl.DrawRectangle(
            i32(x + f32(c) * s - BORDER_SIZE),
            i32(y + f32(r + 1) * s),
            i32(BORDER_SIZE),
            i32(BORDER_SIZE), BORDER_COLOR)
        }

        // lower right corner
        if m[2][1] == 0 && m[2][2] == 0 && m[1][2] == 0 {
            rl.DrawRectangle(
            i32(x + f32(c + 1) * s),
            i32(y + f32(r + 1) * s),
            i32(BORDER_SIZE),
            i32(BORDER_SIZE), BORDER_COLOR)
        }
    }


    //rec := rl.Rectangle{ x, y, TILE_SIZE, TILE_SIZE }
    rl.DrawLine(i32(x), i32(y+TILE_SIZE), i32(x+TILE_SIZE), i32(y+TILE_SIZE), BORDER_COLOR)
    rl.DrawLine(i32(x+TILE_SIZE), i32(y), i32(x+TILE_SIZE), i32(y+TILE_SIZE), BORDER_COLOR)

    //rl.DrawRectangleLinesEx(rec, 1, rl.BLACK)
}

init_map :: proc() {
    for y in 0..<MAP_HEIGHT {
        for x in 0..<MAP_WIDTH {
            n := rand.int_max(len(tiles))
            board[y][x] = u8(n)
        }
    }
}