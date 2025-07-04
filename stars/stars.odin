package stars

import "core:math"
import "core:math/rand"
import rl "vendor:raylib"

SCREEN_WIDTH :: 1920
SCREEN_HEIGHT :: 1080
STARS :: 200
SPEED :: 180
RADIUS :: 20

Star :: struct {
    x: f32,
    y: f32,
    z: f32,
    r: f32,
    a: f32,
    c: rl.Color,
    hidden: bool,
}

stars: [STARS]Star
deltaY: f32
last_time: f64

main :: proc() {
    rl.SetConfigFlags({ .VSYNC_HINT }) // ultimately controls max FPS
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "Stars")

    for i in 0 ..< len(stars) {
        z := rand.float32()
        stars[i] = Star{
            x = rand.float32() * SCREEN_WIDTH,
            y = rand.float32() * SCREEN_HEIGHT,
            z = z,
            r = rand_radius(z),
            a = rand.float32_range(0, 360), //rand.float32() * 2.0 * math.PI,
            c = darken_color(rand_color(), 1.0 - z),
            hidden = rand_choice(),
        }
    }

    sort_stars()
    last_time = rl.GetTime()
    pause := false
    for !rl.WindowShouldClose() {
        if rl.IsKeyPressed(.SPACE) {
            pause = !pause
        }

        if pause == false {
            dt := rl.GetFrameTime()
            update(dt)
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)
        draw()

        rl.EndDrawing()

    }
}

update :: proc(dt: f32) {
    for i in 0 ..< len(stars) {
        s := stars[i]
        x := f32(s.x) - f32(SPEED) * s.z * dt
        y := s.y + s.z * deltaY
        if y < 0 {
            y = SCREEN_HEIGHT
        } else if y > SCREEN_HEIGHT {
            y = 0
        }

        if x < 0 {
            x = f32(rand.int_max(200)) + SCREEN_WIDTH

            // don't change 'z' value, as array is sorted based on it
            stars[i].y = rand.float32() * SCREEN_HEIGHT
            stars[i].r = rand_radius(stars[i].z)
            stars[i].c = darken_color(rand_color(), stars[i].z)
            stars[i].a = rand.float32() * 360.0
            stars[i].hidden = rand_choice()
        }
        stars[i].x = x
        stars[i].y = y
    }

//    t := rl.GetTime()
//    if t - last_time >= 5.0 {
//        last_time = t
//        deltaY = rand.float32() - 0.5
//        fmt.printf("TICK %f\n", deltaY)
//    }
}

draw :: proc() {
    for i in 0 ..< len(stars) {
        s := stars[i]
        if !s.hidden {
            rec := rl.Rectangle{ s.x, s.y, s.r, s.r }
            rl.DrawRectanglePro(rec, { s.r / 2, s.r / 2 }, s.a, s.c)
            rl.DrawRectanglePro(rec, { s.r / 2, s.r / 2 }, s.a + 45, s.c)
        }
    }
}

rand_color2 :: proc() -> rl.Color {
    return rl.Color{ u8(rand.int_max(255)), u8(rand.int_max(255)), u8(rand.int_max(255)), 255 }
}

rand_color :: proc() -> rl.Color {
    colors := []rl.Color{
        rl.YELLOW,
        rl.GOLD,
        rl.ORANGE,
        rl.PINK,
        rl.RED,
        rl.MAROON,
        rl.GREEN,
        rl.LIME,
        rl.DARKGREEN,
        rl.SKYBLUE,
        rl.BLUE,
        rl.DARKBLUE,
        rl.PURPLE,
        rl.VIOLET,
        rl.DARKPURPLE
    }

    return colors[rand.int_max(len(colors))]
}

rand_radius :: proc(z: f32) -> f32 {
    return rand.float32() * RADIUS * z * 1
}

rand_choice :: proc() -> bool {
    return rand.float32() < 0.5
}

darken_color :: proc(color: rl.Color, percentage: f32) -> rl.Color {
    pct := math.clamp(percentage, 0.0, 1.0) * 0.5
    new_r := u8(f32(color.r) * (1.0 - pct))
    new_g := u8(f32(color.g) * (1.0 - pct))
    new_b := u8(f32(color.b) * (1.0 - pct))
    return rl.Color{ new_r, new_g, new_b, color.a }
}

sort_stars :: proc() {
// Sort the stars array based on z value from smallest to largest
// Implementing a simple bubble sort since sort.sort doesn't accept a comparison function
    for i := 0; i < len(stars) - 1; i += 1 {
        for j := 0; j < len(stars) - i - 1; j += 1 {
            if stars[j].z > stars[j + 1].z {
            // Swap stars[j] and stars[j+1]
                temp := stars[j]
                stars[j] = stars[j + 1]
                stars[j + 1] = temp
            }
        }
    }
}
